// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:math';

import '../../../framework.dart';
import '../../framework/native/buffers.dart';
import '../../framework/native/filters.dart';
import 'dispatcher.dart';
import 'types.dart';

/// A [ZstdCompressFilter] is an FFI-based [CodecFilter] that implements the
/// zstd compression algorithm.
class ZstdCompressFilter extends NativeCodecFilterBase {
  /// Dispatcher to make calls via FFI to zstd shared library.
  final ZstdDispatcher _dispatcher = ZstdDispatcher();

  /// Compression level.
  final int level;

  /// Native zstd context object.
  ZstdCStream _cStream;

  /// Construct the [ZstdCompressFilter] with the optional parameters.
  ZstdCompressFilter(
      {this.level, int inputBufferLength, int outputBufferLength})
      : super(
            inputBufferLength: inputBufferLength,
            outputBufferLength: outputBufferLength);

  /// Init the filter.
  ///
  /// Provide appropriate buffer lengths to codec builders
  /// [inputBufferHolder.length] decoding buffer length and
  /// [outputBufferHolder.length] encoding buffer length.
  @override
  int doInit(
      CodecBufferHolder<Pointer<Uint8>, NativeCodecBuffer> inputBufferHolder,
      CodecBufferHolder<Pointer<Uint8>, NativeCodecBuffer> outputBufferHolder,
      List<int> bytes,
      int start,
      int end) {
    _initCStream();

    if (!inputBufferHolder.isLengthSet()) {
      inputBufferHolder.length = _dispatcher.callZstdCStreamInSize();
    }

    // Formula from 'ZSTD_CStreamOutSize'
    final outputLength = _zstdCompressBound(inputBufferHolder.length);
    outputBufferHolder.length = outputBufferHolder.isLengthSet()
        ? max(outputBufferHolder.length, outputLength)
        : outputLength;

    return 0;
  }

  /// Zstd flush implementation.
  ///
  /// Return the number of bytes flushed.
  @override
  int doFlush(NativeCodecBuffer outputBuffer) {
    return _dispatcher.callZstdFlushStream(
        _cStream, outputBuffer.writePtr, outputBuffer.unwrittenCount);
  }

  /// Perform an zstd encoding of [inputBuffer.unreadCount] bytes in
  /// and put the resulting encoded bytes into [outputBuffer] of length
  /// [outputBuffer.unwrittenCount].
  ///
  /// Return an [CodecResult] which describes the amount read/write.
  @override
  CodecResult doProcessing(
      NativeCodecBuffer inputBuffer, NativeCodecBuffer outputBuffer) {
    final result = _dispatcher.callZstdCompressStream(
        _cStream,
        outputBuffer.writePtr,
        outputBuffer.unwrittenCount,
        inputBuffer.readPtr,
        inputBuffer.unreadCount);
    final read = result[0];
    final written = result[1];
    final hint = result[2];
    return _ZstdEncodingResult(read, written, hint);
  }

  /// Zstd finalize implementation.
  ///
  /// A [FormatException] is thrown if writing out the zstd end stream fails.
  @override
  int doFinalize(NativeCodecBuffer outputBuffer) {
    final numBytes = _dispatcher.callZstdEndStream(
        _cStream, outputBuffer.writePtr, outputBuffer.unwrittenCount);
    state = CodecFilterState.finalized;
    return numBytes;
  }

  /// Release zstd resources.
  @override
  void doClose() {
    _destroyCStream();
    _releaseDispatcher();
  }

  /// Allocate and initialize the native zstd compression context.
  ///
  /// A [StateError] is thrown if the compression context could not be
  /// allocated.
  void _initCStream() {
    final result = _dispatcher.callZstdCreateCStream();
    if (result == nullptr) throw StateError('Could not allocate zstd context');
    _cStream = result.ref;
    _dispatcher.callZstdInitCStream(_cStream, level);
  }

  /// Return the maximum compressed size in worst case single-pass scenario.
  int _zstdCompressBound(int uncompressedLength) =>
      _dispatcher.callZstdCompressBound(uncompressedLength);

  /// Free the native context.
  ///
  /// A [FormatException] is thrown if the context is invalid and can not be
  /// freed.
  void _destroyCStream() {
    if (_cStream != null) {
      try {
        _dispatcher.callZstdFreeCStream(_cStream);
      } finally {
        _cStream = null;
      }
    }
  }

  /// Release the Zstd FFI call dispatcher.
  void _releaseDispatcher() {
    _dispatcher.release();
  }
}

/// Result object for an Zstd Encoding operation.
class _ZstdEncodingResult extends CodecResult {
  /// The hint for the next read size.
  final int hint;

  /// Return a new instance of [_ZstdEncodingResult].
  const _ZstdEncodingResult(int bytesRead, int bytesWritten, this.hint)
      : super(bytesRead, bytesWritten);
}
