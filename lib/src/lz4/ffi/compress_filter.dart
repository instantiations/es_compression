// Copyright (c) 2021, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:math';

import 'package:ffi/ffi.dart';

import '../../../framework.dart';
import '../../framework/native/buffers.dart';
import '../../framework/native/filters.dart';
import '../encoder.dart';
import 'constants.dart';
import 'dispatcher.dart';
import 'types.dart';

/// A [Lz4CompressFilter] is an FFI-based [CodecFilter] that implements the
/// lz4 compression algorithm.
class Lz4CompressFilter extends NativeCodecFilterBase {
  /// Dispatcher to make calls via FFI to lz4 shared library.
  final Lz4Dispatcher _dispatcher = Lz4Dispatcher();

  /// FFI Struct exposed by lz4 shared lib for configuration.
  late final Pointer<Lz4Preferences> _preferences;

  /// Native lz4 context.
  late final Pointer<Lz4Cctx> _context;

  /// Native lz4 compress options.
  late final Pointer<Lz4CompressOptions> _options;

  /// Construct the [Lz4CompressFilter] with the optional parameters.
  Lz4CompressFilter(
      {int? level,
      bool? fastAcceleration,
      bool? contentChecksum,
      bool? blockChecksum,
      bool? blockLinked,
      int? blockSize,
      bool? optimizeForCompression,
      int inputBufferLength = 16386,
      int outputBufferLength = 16386})
      : super(
            inputBufferLength: inputBufferLength,
            outputBufferLength: outputBufferLength) {
    _options = _dispatcher.library.newCompressOptions();
    _preferences = _dispatcher.library.newPreferences(
        level: level,
        fastAcceleration: fastAcceleration,
        contentChecksum: contentChecksum,
        blockChecksum: blockChecksum,
        blockLinked: blockLinked,
        blockSize: blockSize,
        optimizeForCompression: optimizeForCompression);
  }

  /// Init the filter.
  ///
  /// 1. Provide appropriate buffer lengths to codec builders
  /// `inputBufferHolder.length` decoding buffer length and
  /// `outputBufferHolder.length` encoding buffer length.
  /// Ensure that the `outputBufferHolder.length` is at least as large as the
  /// maximum size of an lz4 block given the `inputBufferHolder.length`.
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
    if (!inputBufferHolder.isLengthSet()) {
      inputBufferHolder.length = outputBufferHolder.isLengthSet()
          ? outputBufferHolder.length
          : lz4EncoderInputBufferLength;
    }

    final minimumOut = _lz4CompressBound(inputBufferHolder.length);
    outputBufferHolder.length = max(
        minimumOut,
        outputBufferHolder.isLengthSet()
            ? outputBufferHolder.length
            : lz4EncoderOutputBufferLength);

    _initContext();
    _writeHeader(outputBufferHolder.buffer);
    return 0;
  }

  /// Perform an lz4 encoding of `inputBuffer.unreadCount` bytes in
  /// and put the resulting encoded bytes into [outputBuffer] of length
  /// `outputBuffer.unwrittenCount`.
  ///
  /// Return an [CodecResult] which describes the amount read/write.
  @override
  CodecResult doProcessing(
      NativeCodecBuffer inputBuffer, NativeCodecBuffer outputBuffer) {
    final writtenCount = _dispatcher.callLz4FCompressUpdate(
        _context,
        outputBuffer.writePtr,
        outputBuffer.unwrittenCount,
        inputBuffer.readPtr,
        inputBuffer.unreadCount,
        _options);
    return CodecResult(inputBuffer.unreadCount, writtenCount);
  }

  /// Lz4 flush implementation.
  ///
  /// Return the number of bytes flushed.
  @override
  int doFlush(NativeCodecBuffer outputBuffer) => _dispatcher.callLz4FFlush(
      _context, outputBuffer.writePtr, outputBuffer.unwrittenCount, _options);

  /// Lz4 finalize implementation.
  ///
  /// Only 1 round of finalization is required, put filter state into
  /// the finalized state.
  ///
  /// A [FormatException] is thrown if [outputBuffer] is not of sufficient
  /// length.
  /// A [FormatException] is thrown if writing out the lz4 trailer fails.
  @override
  int doFinalize(NativeCodecBuffer outputBuffer) {
    final writeLength = outputBuffer.unwrittenCount;
    if (writeLength < 4 ||
        (_preferences.ref.frameInfoContentChecksumFlag != 0 &&
            writeLength < 8)) {
      const FormatException(
          'buffer capacity is too small to properly finish the lz4 frame');
    }
    final numBytes = _dispatcher.callLz4FCompressEnd(
        _context, outputBuffer.writePtr, writeLength, _options);
    state = CodecFilterState.finalized;
    return numBytes;
  }

  /// Release lz4 resources.
  @override
  void doClose() {
    _destroyContext();
    _destroyPreferences();
    _destroyCompressOptions();
    _releaseDispatcher();
  }

  /// Allocate the native lz4 compression context.
  ///
  /// A [StateError] is thrown if the compression context could not be
  /// allocated.
  void _initContext() {
    _context = _dispatcher.callLz4FCreateCompressionContext();
  }

  /// Write the lz4 frame header to the compressed buffer.
  ///
  /// A [FormatException] is thrown if the encoding buffer is not big enough to
  /// hold at least the max size of an lz4 frame header.
  /// A [FormatException] is thrown if the lz4 frame header could not be
  /// written.
  void _writeHeader(NativeCodecBuffer outputBuffer) {
    if (outputBuffer.unwrittenCount < Lz4Constants.LZ4F_HEADER_SIZE_MAX) {
      FormatException('buffer capacity < LZ4F_HEADER_SIZE_MAX '
          '($Lz4Constants.LZ4F_HEADER_SIZE_MAX bytes)');
    }
    final numBytes = _dispatcher.callLz4FCompressBegin(_context,
        outputBuffer.writePtr, outputBuffer.unwrittenCount, _preferences);
    outputBuffer.incrementBytesWritten(numBytes);
  }

  /// Return the maximum length of an lz4 block, given its uncompressed
  /// [uncompressedLength] and header size.
  int _lz4CompressBound(int uncompressedLength) =>
      _dispatcher.callLz4FCompressBound(uncompressedLength, _preferences);

  /// Free the native context.
  ///
  /// A [StateError] is thrown if the context is invalid and can not be freed.
  void _destroyContext() {
    _dispatcher.callLz4FFreeCompressionContext(_context);
  }

  /// Free the native memory from the allocated [_preferences].
  void _destroyPreferences() {
    malloc.free(_preferences);
  }

  /// Free the native memory from the allocated [_options].
  void _destroyCompressOptions() {
    malloc.free(_options);
  }

  /// Release the Lz4 FFI call dispatcher.
  void _releaseDispatcher() {
    _dispatcher.release();
  }
}
