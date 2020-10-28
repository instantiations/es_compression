// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:ffi';
import 'dart:math';

import '../framework/buffers.dart';
import '../framework/converters.dart';
import '../framework/filters.dart';
import '../framework/sinks.dart';
import '../framework/native/buffers.dart';

import 'ffi/constants.dart';
import 'ffi/dispatcher.dart';
import 'ffi/types.dart';

import 'codec.dart';

/// Default input buffer length
const defaultInputBufferLength = 256 * 1024;

/// Default output buffer length
const defaultOutputBufferLength = defaultInputBufferLength * 2;

/// The [Lz4Decoder] decoder is used by [Lz4Codec] to decompress lz4 data.
class Lz4Decoder extends CodecConverter {
  /// Length in bytes of the buffer used for input data.
  final int inputBufferLength;

  /// Length in bytes of the buffer used for processed output data.
  final int outputBufferLength;

  /// Construct an [Lz4Decoder]
  Lz4Decoder(
      {this.inputBufferLength = defaultInputBufferLength,
      this.outputBufferLength = defaultOutputBufferLength});

  @override
  ByteConversionSink startChunkedConversion(Sink<List<int>> sink) {
    final byteSink = asByteSink(sink);
    return _Lz4DecoderSink._(byteSink, inputBufferLength, outputBufferLength);
  }
}

class _Lz4DecoderSink extends CodecSink {
  _Lz4DecoderSink._(
      ByteConversionSink sink, int inputBufferLength, int outputBufferLength)
      : super(
            sink, _Lz4DecompressFilter(inputBufferLength, outputBufferLength));
}

class _Lz4DecompressFilter
    extends CodecFilter<Pointer<Uint8>, NativeCodecBuffer, _Lz4DecodingResult> {
  /// Dispatcher to make calls via FFI to lz4 shared library
  final Lz4Dispatcher _dispatcher = Lz4Dispatcher();

  /// Native lz4 frame info
  Lz4FrameInfo _frameInfo;

  /// Native lz4 context
  Lz4Dctx _ctx;

  /// Native lz4 decompress options
  Lz4DecompressOptions _options;

  /// Construct the [_Lz4DecompressFilter] with the defined buffer lengths.
  _Lz4DecompressFilter(int inputBufferLength, int outputBufferLength)
      : super(
            inputBufferLength: inputBufferLength,
            outputBufferLength: outputBufferLength) {
    _options = _dispatcher.library.newDecompressOptions();
  }

  @override
  CodecBufferHolder<Pointer<Uint8>, NativeCodecBuffer> newBufferHolder(
      int length) {
    return NativeCodecBufferHolder(length);
  }

  /// Init the filter
  ///
  /// 1. Provide appropriate buffer lengths to codec builders
  /// [inputBufferHolder.length] decoding buffer length and
  /// [outputBufferHolder.length] encoding buffer length
  /// Ensure that the [outputBufferHolder.length] is at least as large as the
  /// maximum size of an lz4 block given the [inputBufferHolder.length]
  ///
  /// 2. Allocate and setup the native lz4 context
  ///
  /// 3. Write the lz4 header out to the compressed buffer
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
        : defaultInputBufferLength;

    final numBytes = inputBufferHolder.buffer.nextPutAll(bytes, start, end);
    if (numBytes > 0) _readFrameInfo(inputBufferHolder.buffer);

    outputBufferHolder.length = max(
        _frameInfo.blockSize,
        outputBufferHolder.isLengthSet()
            ? outputBufferHolder.length
            : max(defaultOutputBufferLength, inputBufferHolder.length));

    return numBytes;
  }

  @override
  _Lz4DecodingResult doProcessing(
      NativeCodecBuffer inputBuffer, NativeCodecBuffer outputBuffer) {
    final result = _dispatcher.callLz4FDecompress(
        _ctx,
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

  @override
  int doFlush(CodecBuffer outputBuffer) {
    return 0;
  }

  @override
  int doFinalize(CodecBuffer outputBuffer) {
    return 0;
  }

  @override
  void doClose() {
    _destroyContext();
    _destroyFrameInfo();
    _releaseDispatcher();
  }

  void _initContext() {
    _ctx = _dispatcher.callLz4FCreateDecompressionContext();
  }

  int _readFrameInfo(NativeCodecBuffer encoderBuffer, {bool reset = false}) {
    final result = _dispatcher.callLz4FGetFrameInfo(
        _ctx, encoderBuffer.readPtr, encoderBuffer.unreadCount);
    _frameInfo = result[1] as Lz4FrameInfo;
    final read = result[2] as int;
    encoderBuffer.incrementBytesRead(read);
    if (reset == true) _reset();
    return read;
  }

  void _reset() {
    if (_ctx != null) _dispatcher.callLz4FResetDecompressionContext(_ctx);
  }

  void _destroyContext() {
    if (_ctx != null) {
      try {
        _dispatcher.callLz4FFreeDecompressionContext(_ctx);
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
class _Lz4DecodingResult extends CodecResult {
  /// How many 'srcSize' bytes expected to be decompressed for next call.
  /// When a frame is fully decoded, this will be 0.
  final int hint;

  const _Lz4DecodingResult(int bytesRead, int bytesWritten, this.hint)
      : super(bytesRead, bytesWritten);
}
