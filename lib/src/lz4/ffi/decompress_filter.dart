// Copyright (c) 2021, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:math';

import 'package:ffi/ffi.dart';

import '../../../framework.dart';
import '../../../lz4.dart';
import '../../framework/native/buffers.dart';
import '../../framework/native/filters.dart';
import 'constants.dart';
import 'dispatcher.dart';
import 'types.dart';

/// A [Lz4DecompressFilter] is an FFI-based [CodecFilter] that implements the
/// lz4 decompression algorithm.
class Lz4DecompressFilter extends NativeCodecFilterBase {
  /// Dispatcher to make calls via FFI to lz4 shared library.
  final Lz4Dispatcher _dispatcher = Lz4Dispatcher();

  /// Native lz4 frame info.
  Pointer<Lz4FrameInfo>? _frameInfo;

  /// Native lz4 context.
  Pointer<Lz4Dctx>? _context;

  /// Native lz4 decompress options.
  late final Pointer<Lz4DecompressOptions> _options;

  /// Construct the [Lz4DecompressFilter] with the defined buffer lengths.
  Lz4DecompressFilter(int inputBufferLength, int outputBufferLength)
      : super(
            inputBufferLength: inputBufferLength,
            outputBufferLength: outputBufferLength) {
    _options = _dispatcher.library.newDecompressOptions();
  }

  /// Init the filter.
  ///
  /// 1. Provide appropriate buffer lengths to codec builders
  /// [inputBufferHolder] decoding buffer length and
  /// [outputBufferHolder] encoding buffer length.
  /// Ensure that the [outputBufferHolder] is at least as large as the
  /// maximum size of an lz4 block given the [inputBufferHolder].
  ///
  /// 2. Allocate and setup the native lz4 context.
  ///
  /// 3. Write the lz4 header out to the compressed buffer.
  @override
  int doInit(
      CodecBufferHolder<Pointer<Uint8>, NativeCodecBuffer> inputBufferHolder,
      CodecBufferHolder<Pointer<Uint8>, NativeCodecBuffer> outputBufferHolder,
      List<int> bytes,
      int start,
      int end) {
    _initContext();

    inputBufferHolder.length = inputBufferHolder.isLengthSet()
        ? max(inputBufferHolder.length, Lz4Constants.LZ4F_HEADER_SIZE_MAX)
        : lz4DecoderInputBufferLength;

    final numBytes = inputBufferHolder.buffer.nextPutAll(bytes, start, end);
    if (numBytes > 0) _readFrameInfo(inputBufferHolder.buffer);

    outputBufferHolder.length = max(
        _frameInfo!.ref.blockSize,
        outputBufferHolder.isLengthSet()
            ? outputBufferHolder.length
            : max(lz4DecoderOutputBufferLength, inputBufferHolder.length));

    return numBytes;
  }

  /// Perform decompression.
  ///
  /// Answer an [CodecResult] that store how much was read, written and
  /// how many 'srcSize' bytes are expected for the next call.
  @override
  CodecResult doProcessing(
      NativeCodecBuffer inputBuffer, NativeCodecBuffer outputBuffer) {
    final result = _dispatcher.callLz4FDecompress(
        _checkedContext(),
        outputBuffer.writePtr,
        outputBuffer.unwrittenCount,
        inputBuffer.readPtr,
        inputBuffer.unreadCount,
        _options);
    final read = result[0];
    final written = result[1];
    final hint = result[2];
    return _Lz4DecodingResult(read, written, hint);
  }

  /// Free memory and release the dispatcher.
  @override
  void doClose() {
    _destroyContext();
    _destroyFrameInfo();
    _releaseDispatcher();
  }

  /// Allocate the native lz4 decompression context.
  ///
  /// A [StateError] is thrown if the decompression context could not be
  /// allocated.
  void _initContext() {
    _context = _dispatcher.callLz4FCreateDecompressionContext();
  }

  /// Perform a null-check on the context and throw a [StateError] if [_context]
  /// is [:null:].
  ///
  /// Return the null-checked [_context].
  Pointer<Lz4Dctx> _checkedContext() {
    if (_context == null) throw StateError('null _context is unexpected');
    return _context!;
  }

  /// Read the [Lz4FrameInfo] from the [encoderBuffer].
  int _readFrameInfo(NativeCodecBuffer encoderBuffer, {bool reset = false}) {
    final result = _dispatcher.callLz4FGetFrameInfo(
        _checkedContext(), encoderBuffer.readPtr, encoderBuffer.unreadCount);
    _frameInfo = result[1] as Pointer<Lz4FrameInfo>;
    final read = result[2] as int;
    encoderBuffer.incrementBytesRead(read);
    if (reset == true) _reset();
    return read;
  }

  /// Restores the [_context] to a clean state.
  void _reset() {
    _dispatcher.callLz4FResetDecompressionContext(_checkedContext());
  }

  /// Free the native context.
  ///
  /// A [StateError] is thrown if the context is invalid and can not be freed.
  void _destroyContext() {
    if (_context != null) {
      _dispatcher.callLz4FFreeDecompressionContext(_context!);
    }
  }

  /// Free the native memory from the allocated [_frameInfo].
  void _destroyFrameInfo() {
    if (_frameInfo != null) malloc.free(_frameInfo!);
  }

  /// Release the Lz4 FFI call dispatcher.
  void _releaseDispatcher() {
    _dispatcher.release();
  }
}

/// Result object for an Lz4 Decompression operation.
class _Lz4DecodingResult extends CodecResult {
  /// How many 'srcSize' bytes expected to be decompressed for next call.
  /// When a frame is fully decoded, this will be 0.
  final int hint;

  /// Return a new instance of [_Lz4DecodingResult].
  const _Lz4DecodingResult(super.bytesRead, super.bytesWritten, this.hint);
}
