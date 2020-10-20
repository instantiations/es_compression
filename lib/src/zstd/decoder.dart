// Copyright (c) 2020, Seth Berman (Instantiations, Inc). Please see the AUTHORS
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

/// ZSTD_BLOCKSIZE_MAX + ZSTD_blockHeaderSize;
const defaultInputBufferLength = ZstdConstants.ZSTD_BLOCKSIZE_MAX + 3;

/// The [ZstdDecoder] decoder is used by [ZstdCodec] to decompress zstd data.
class ZstdDecoder extends CodecConverter {
  @override
  ByteConversionSink startChunkedConversion(Sink<List<int>> sink) {
    ByteConversionSink byteSink;
    if (sink is! ByteConversionSink) {
      byteSink = ByteConversionSink.from(sink);
    } else {
      byteSink = sink as ByteConversionSink;
    }
    return _ZstdDecoderSink._(byteSink);
  }
}

class _ZstdDecoderSink extends CodecSink {
  _ZstdDecoderSink._(ByteConversionSink sink)
      : super(sink, _ZstdDecompressFilter());
}

class _ZstdDecompressFilter extends CodecFilter<Pointer<Uint8>,
    NativeCodecBuffer, _ZstdDecodingResult> {
  /// Dispatcher to make calls via FFI to lz4 shared library
  final ZstdDispatcher _dispatcher = ZstdDispatcher();

  /// Native zstd context object
  ZstdDStream _dStream;

  _ZstdDecompressFilter() : super(inputBufferLength: defaultInputBufferLength);

  @override
  CodecBufferHolder<Pointer<Uint8>, NativeCodecBuffer> newBufferHolder(
      int length) {
    final holder = CodecBufferHolder<Pointer<Uint8>, NativeCodecBuffer>(length);
    return holder..bufferBuilderFunc = (length) => NativeCodecBuffer(length);
  }

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

  @override
  _ZstdDecodingResult doProcessing(
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
    _destroyDStream();
    _releaseDispatcher();
  }

  void _initDStream() {
    final result = _dispatcher.callZstdCreateDStream();
    if (result == nullptr) throw StateError('Could not allocate zstd context');
    _dStream = result.ref;
    _dispatcher.callZstdInitDStream(_dStream);
  }

  void _destroyDStream() {
    if (_dStream != null) {
      try {
        _dispatcher.callZstdFreeDStream(_dStream);
      } finally {
        _dStream = null;
      }
    }
  }

  void _releaseDispatcher() {
    _dispatcher.release();
  }
}

/// Result object for an Zstd Decompression operation
class _ZstdDecodingResult extends CodecResult {
  /// How many 'srcSize' bytes expected to be decompressed for next call.
  /// When a frame is fully decoded, this will be 0.
  final int hint;

  const _ZstdDecodingResult(int bytesRead, int bytesWritten, this.hint)
      : super(bytesRead, bytesWritten);
}
