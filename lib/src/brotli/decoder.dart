// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import '../framework/buffers.dart';
import '../framework/converters.dart';
import '../framework/filters.dart';
import '../framework/sinks.dart';
import 'stubs/decompress_filter.dart'
    if (dart.library.io) 'ffi/decompress_filter.dart';

/// Default input buffer length.
const brotliDecoderInputBufferLength = 64 * 1024;

/// Default output buffer length.
const brotliDecoderOutputBufferLength = brotliDecoderInputBufferLength;

/// The [BrotliDecoder] decoder is used by [BrotliCodec] to decompress brotli
/// data.
class BrotliDecoder extends CodecConverter {
  /// Flag the determines if "canny" ring buffer allocation is enabled.
  /// Ring buffer is allocated according to window size, despite the real size
  /// of content.
  final bool ringBufferReallocation;

  /// Flag that determines if "Large Window Brotli" is used.
  /// If set to [:true:], then the LZ-Window can be set up to 30-bits but the
  /// result will not be RFC7932 compliant.
  /// Default: [:false:].
  final bool largeWindow;

  /// Length in bytes of the buffer used for input data.
  final int inputBufferLength;

  /// Length in bytes of the buffer used for processed output data.
  final int outputBufferLength;

  /// Construct an [BrotliDecoder] with the supplied parameters.
  ///
  /// Validation will be performed which may result in a [RangeError] or
  /// [ArgumentError].
  BrotliDecoder(
      {this.ringBufferReallocation = true,
      this.largeWindow = false,
      this.inputBufferLength = CodecBufferHolder.autoLength,
      this.outputBufferLength = CodecBufferHolder.autoLength});

  /// Start a chunked conversion using the options given to the [BrotliDecoder]
  /// constructor.
  ///
  /// While it accepts any [Sink] taking [List]'s,
  /// the optimal sink to be passed as [sink] is a [ByteConversionSink].
  @override
  ByteConversionSink startChunkedConversion(Sink<List<int>> sink) {
    final byteSink = asByteSink(sink);
    return _BrotliDecoderSink._(byteSink, ringBufferReallocation, largeWindow);
  }
}

/// Brotli decoding sink internal implementation.
class _BrotliDecoderSink extends CodecSink {
  _BrotliDecoderSink._(
      ByteConversionSink sink, bool ringBufferReallocation, bool largeWindow)
      : super(sink,
            _makeBrotliDecompressFilter(ringBufferReallocation, largeWindow));
}

/// Construct a new [BrotliDecompressFilter] which is configured with the
/// options provided.
///
/// There is a conditional import that determines the implementation of
/// [BrotliDecompressFilter] based on the environment.
CodecFilter _makeBrotliDecompressFilter(
    bool ringBufferReallocation, bool largeWindow) {
  return BrotliDecompressFilter(
      ringBufferReallocation: ringBufferReallocation, largeWindow: largeWindow);
}
