// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import '../../framework.dart';
import '../framework/buffers.dart';
import '../framework/converters.dart';
import '../framework/sinks.dart';
import 'ffi/constants.dart';
import 'stubs/decompress_filter.dart'
    if (dart.library.io) 'ffi/decompress_filter.dart';

/// ZSTD_BLOCKSIZE_MAX + ZSTD_blockHeaderSize.
const zstdDecoderInputBufferLength = ZstdConstants.ZSTD_BLOCKSIZE_MAX + 3;

/// Default output buffer length.
const zstdDecoderOutputBufferLength = CodecBufferHolder.autoLength;

/// The [ZstdDecoder] decoder is used by [ZstdCodec] to decompress zstd data.
class ZstdDecoder extends CodecConverter {
  /// Length in bytes of the buffer used for input data.
  final int inputBufferLength;

  /// Length in bytes of the buffer used for processed output data.
  final int outputBufferLength;

  /// Construct an [ZstdDecoder].
  ZstdDecoder(
      {this.inputBufferLength = zstdDecoderInputBufferLength,
      this.outputBufferLength = zstdDecoderOutputBufferLength});

  /// Start a chunked conversion using the options given to the [ZstdDecoder]
  /// constructor.
  ///
  /// While it accepts any [Sink] taking [List]'s,
  /// the optimal sink to be passed as [sink] is a [ByteConversionSink].
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
      : super(sink,
            _makeZstdCompressFilter(inputBufferLength, outputBufferLength));
}

/// Construct a new [ZstdDecompressFilter] which is configured with the options
/// provided.
///
/// There is a conditional import that determines the implementation of
/// [ZstdDecompressFilter] based on the environment.
CodecFilter _makeZstdCompressFilter(
    int inputBufferLength, int outputBufferLength) {
  return ZstdDecompressFilter(inputBufferLength, outputBufferLength);
}
