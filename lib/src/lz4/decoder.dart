// Copyright (c) 2020, Seth Berman (Instantiations, Inc). Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:math';

import '../common/buffers.dart';
import '../common/converters.dart';
import '../common/filters.dart';
import '../common/sinks.dart';

import 'ffi/constants.dart';
import 'ffi/dispatcher.dart';
import 'ffi/types.dart';

/// 64k default input buffer length
const defaultInputBufferLength = 64 * 1024;

/// The [Lz4Decoder] decoder is used by [Lz4Codec] to decompress lz4 data.
class Lz4Decoder extends CodecConverter {
  @override
  ByteConversionSink startChunkedConversion(Sink<List<int>> sink) {
    ByteConversionSink byteSink;
    if (sink is! ByteConversionSink) {
      byteSink = ByteConversionSink.from(sink);
    } else {
      byteSink = sink as ByteConversionSink;
    }
    return _Lz4DecoderSink(byteSink);
  }
}

class _Lz4DecoderSink extends CodecSink {
  _Lz4DecoderSink(ByteConversionSink sink)
      : super(sink, _Lz4DecompressFilter());
}

class _Lz4DecompressFilter extends CodecFilter<_Lz4DecompressionResult>
    with Lz4DispatchErrorCheckerMixin {
  /// Dispatcher to make calls via FFI to lz4 shared library
  final Lz4Dispatcher _dispatcher = Lz4Dispatcher();

  Lz4FrameInfo _frameInfo;

  /// Native lz4 context
  Lz4Dctx _ctx;

  /// Native lz4 decompress options
  Lz4DecompressOptions _options;

  _Lz4DecompressFilter() : super(inputBufferLength: defaultInputBufferLength) {
    _options = _dispatcher.library.newDecompressOptions();
  }

  /// Lz4DispatchMixin: Answer lz4 dispatcher
  @override
  Lz4Dispatcher get dispatcher => _dispatcher;

  /// Init the filter
  ///
  /// 1. Provide appropriate buffer lengths to codec builders
  /// [decBuilder.length] decoding buffer length and
  /// [encBuilder.length] encoding buffer length
  /// Ensure that the [encBuilder.length] is at least as large as the
  /// maximum size of an lz4 block given the [decBuilder.length]
  ///
  /// 2. Allocate and setup the native lz4 context
  ///
  /// 3. Write the lz4 header out to the compressed buffer
  @override
  int doInit(
      CodecBufferHolder inputBufferHolder,
      CodecBufferHolder outputBufferHolder,
      List<int> bytes,
      int start,
      int end) {
    _initContext();
    inputBufferHolder.length = inputBufferHolder.isLengthSet()
        ? max(inputBufferHolder.length, Lz4Constants.LZ4F_HEADER_SIZE_MAX)
        : defaultInputBufferLength;
    final numBytes = inputBufferHolder.buffer.nextPutAll(bytes, start, end);
    if (numBytes > 0) _readFrameInfo(inputBufferHolder.buffer);
    outputBufferHolder.length = outputBufferHolder.isLengthSet()
        ? max(outputBufferHolder.length, _frameInfo.blockSize)
        : _frameInfo.blockSize;
    return numBytes;
  }

  @override
  _Lz4DecompressionResult doProcessing(
      CodecBuffer inputBuffer, CodecBuffer outputBuffer) {
    final result = _dispatcher.callLz4FDecompress(
        _ctx,
        outputBuffer.writePtr,
        outputBuffer.unwrittenCount,
        inputBuffer.readPtr,
        inputBuffer.unreadCount,
        _options);
    checkError(result[2]);
    final read = result[0];
    final written = result[1];
    final hint = result[2];
    return _Lz4DecompressionResult(read, written, hint);
  }

  @override
  int doFlush(CodecBuffer outputBuffer) {
    return 0;
  }

  @override
  int doFinalize(CodecBuffer outputBuffer) {
    return 0;
  }

  /// Release lz4 resources
  @override
  void doClose() {
    _destroyContext();
    _destroyFrameInfo();
    _releaseDispatcher();
  }

  void _initContext() {
    final result = _dispatcher.callLz4FCreateDecompressionContext();
    checkError(result[0] as int);
    _ctx = result[1] as Lz4Dctx;
  }

  int _readFrameInfo(CodecBuffer encoderBuffer, {bool reset = false}) {
    final result = _dispatcher.callLz4FGetFrameInfo(
        _ctx, encoderBuffer.readPtr, encoderBuffer.unreadCount);
    checkError(result[0] as int);
    _frameInfo = result[1] as Lz4FrameInfo;
    final read = result[2] as int;
    encoderBuffer.incrementBytesRead(read);
    if (reset == true) _reset();
    return read;
  }

  void _reset() {
    assert(_ctx != null);
    _dispatcher.callLz4FResetDecompressionContext(_ctx);
  }

  void _destroyContext() {
    if (_ctx != null) {
      try {
        checkError(_dispatcher.callLz4FFreeDecompressionContext(_ctx));
      } finally {
        _ctx = null;
      }
    }
  }

  /// Free the native memory from the allocated [_preferences].
  void _destroyFrameInfo() {
    _frameInfo?.free();
    _frameInfo = null;
  }

  void _releaseDispatcher() {
    _dispatcher.release();
  }
}

/// Result object for an Lz4 Decompression operation
class _Lz4DecompressionResult extends CodecResult {
  /// How many 'srcSize' bytes expected to be decompressed for next call.
  /// When a frame is fully decoded, this will be 0.
  final int hint;

  const _Lz4DecompressionResult(int bytesRead, int bytesWritten, this.hint)
      : super(bytesRead, bytesWritten);
}
