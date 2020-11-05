// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:ffi';
import 'dart:math';

import '../framework/buffers.dart';
import '../framework/converters.dart';
import '../framework/filters.dart';
import '../framework/native/buffers.dart';
import '../framework/native/filters.dart';
import '../framework/sinks.dart';
import 'ffi/constants.dart';
import 'ffi/dispatcher.dart';
import 'ffi/types.dart';

/// ZSTD_BLOCKSIZE_MAX + ZSTD_blockHeaderSize;
const defaultInputBufferLength = ZstdConstants.ZSTD_BLOCKSIZE_MAX + 3;

/// Default output buffer length
const defaultOutputBufferLength = CodecBufferHolder.autoLength;

/// The [ZstdDecoder] decoder is used by [ZstdCodec] to decompress zstd data.
class ZstdDecoder extends CodecConverter {
  /// Length in bytes of the buffer used for input data.
  final int inputBufferLength;

  /// Length in bytes of the buffer used for processed output data.
  final int outputBufferLength;

  /// Construct an [ZstdDecoder].
  ZstdDecoder(
      {this.inputBufferLength = defaultInputBufferLength,
      this.outputBufferLength = defaultOutputBufferLength});

  @override
  ByteConversionSink startChunkedConversion(Sink<List<int>> sink) {
    final byteSink = asByteSink(sink);
    return _ZstdDecoderSink._(byteSink, inputBufferLength, outputBufferLength);
  }
}

/// Zstd decoding sink internal implementation.
class _ZstdDecoderSink extends CodecSink {
  _ZstdDecoderSink._(
      ByteConversionSink sink, int inputBufferLength, int outputBufferLength)
      : super(
            sink, _ZstdDecompressFilter(inputBufferLength, outputBufferLength));
}

/// Internal filter that decompresses lz4 bytes.
class _ZstdDecompressFilter extends NativeCodecFilterBase {
  /// Dispatcher to make calls via FFI to zstd shared library
  final ZstdDispatcher _dispatcher = ZstdDispatcher();

  /// Native zstd context object
  ZstdDStream _dStream;

  /// Construct the [_ZstdDecompressFilter] with the optional parameters.
  _ZstdDecompressFilter(int inputBufferLength, int outputBufferLength)
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
  /// Answer an [_ZstdDecodingResult] that store how much was read, written and
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
