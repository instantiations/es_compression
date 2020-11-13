// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import '../../framework.dart';
import '../framework/converters.dart';
import '../framework/sinks.dart';
import 'codec.dart';
import 'stubs/decompress_filter.dart'
    if (dart.library.io) 'ffi/decompress_filter.dart';

/// Default input buffer length.
const lz4DecoderInputBufferLength = 256 * 1024;

/// Default output buffer length.
const lz4DecoderOutputBufferLength = lz4DecoderInputBufferLength * 2;

/// The [Lz4Decoder] decoder is used by [Lz4Codec] to decompress lz4 data.
class Lz4Decoder extends CodecConverter {
  /// Length in bytes of the buffer used for input data.
  final int inputBufferLength;

  /// Length in bytes of the buffer used for processed output data.
  final int outputBufferLength;

  /// Construct an [Lz4Decoder].
  Lz4Decoder(
      {this.inputBufferLength = lz4DecoderInputBufferLength,
      this.outputBufferLength = lz4DecoderOutputBufferLength});

  /// Start a chunked conversion using the options given to the [Lz4Decoder]
  /// constructor.
  ///
  /// While it accepts any [Sink] taking [List]'s,
  /// the optimal sink to be passed as [sink] is a [ByteConversionSink].
  @override
  ByteConversionSink startChunkedConversion(Sink<List<int>> sink) {
    final byteSink = asByteSink(sink);
    return _Lz4DecoderSink._(byteSink, inputBufferLength, outputBufferLength);
  }
}

/// Lz4 decoding sink internal implementation.
class _Lz4DecoderSink extends CodecSink {
  _Lz4DecoderSink._(
      ByteConversionSink sink, int inputBufferLength, int outputBufferLength)
      : super(sink,
            _makeLz4DecompressFilter(inputBufferLength, outputBufferLength));
}

/// Construct a new [Lz4DecompressFilter] which is configured with the options
/// provided.
///
/// There is a conditional import that determines the implementation of
/// [Lz4DecompressFilter] based on the environment.
CodecFilter _makeLz4DecompressFilter(
    int inputBufferLength, int outputBufferLength) {
  return Lz4DecompressFilter(inputBufferLength, outputBufferLength);
}
