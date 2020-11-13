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

/// A [ZstdDecompressFilter] is an FFI-based [CodecFilter] that implements the
/// zstd decompression algorithm.
class ZstdDecompressFilter extends NativeCodecFilterBase {
  /// Dispatcher to make calls via FFI to zstd shared library
  final ZstdDispatcher _dispatcher = ZstdDispatcher();

  /// Native zstd context object
  ZstdDStream _dStream;

  /// Construct the [ZstdDecompressFilter] with the optional parameters.
  ZstdDecompressFilter(int inputBufferLength, int outputBufferLength)
      : super(
            inputBufferLength: inputBufferLength,
            outputBufferLength: outputBufferLength);

  /// Init the filter
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
    _initDStream();

    if (!inputBufferHolder.isLengthSet()) {
      inputBufferHolder.length = _dispatcher.callZstdDStreamInSize();
    }

    // Formula from 'ZSTD_DStreamOutSize'
    final outputLength = _dispatcher.callZstdDStreamOutSize();
    outputBufferHolder.length = outputBufferHolder.isLengthSet()
        ? max(outputBufferHolder.length, outputLength)
        : outputLength;

    return 0;
  }

  /// Perform decompression.
  ///
  /// Answer an [CodecResult] that store how much was read, written and
  /// how many 'srcSize' bytes are expected for the next call.
  @override
  CodecResult doProcessing(
      NativeCodecBuffer inputBuffer, NativeCodecBuffer outputBuffer) {
    final result = _dispatcher.callZstdDecompressStream(
        _dStream,
        outputBuffer.writePtr,
        outputBuffer.unwrittenCount,
        inputBuffer.readPtr,
        inputBuffer.unreadCount);
    final read = result[0];
    final written = result[1];
    final hint = result[2];
    return _ZstdDecodingResult(read, written, hint);
  }

  /// Release zstd resources
  @override
  void doClose() {
    _destroyDStream();
    _releaseDispatcher();
  }

  /// Allocate and initialize the native zstd decompression context
  ///
  /// A [StateError] is thrown if the decompression context could not be
  /// allocated.
  void _initDStream() {
    final result = _dispatcher.callZstdCreateDStream();
    if (result == nullptr) throw StateError('Could not allocate zstd context');
    _dStream = result.ref;
    _dispatcher.callZstdInitDStream(_dStream);
  }

  /// Free the native context
  ///
  /// A [FormatException] is thrown if the context is invalid and can not be
  /// freed
  void _destroyDStream() {
    if (_dStream != null) {
      try {
        _dispatcher.callZstdFreeDStream(_dStream);
      } finally {
        _dStream = null;
      }
    }
  }

  /// Release the Zstd FFI call dispatcher.
  void _releaseDispatcher() {
    _dispatcher.release();
  }
}

/// Result object for an Zstd Decompression operation.
class _ZstdDecodingResult extends CodecResult {
  /// How many 'srcSize' bytes expected to be decompressed for next call.
  /// When a frame is fully decoded, this will be 0.
  final int hint;

  /// Return a new instance of [_ZstdDecodingResult].
  const _ZstdDecodingResult(int bytesRead, int bytesWritten, this.hint)
      : super(bytesRead, bytesWritten);
}
