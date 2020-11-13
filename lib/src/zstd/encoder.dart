// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import '../framework/buffers.dart';
import '../framework/converters.dart';
import '../framework/filters.dart';
import '../framework/sinks.dart';
import 'ffi/constants.dart';
import 'options.dart';
import 'stubs/compress_filter.dart'
    if (dart.library.io) 'ffi/compress_filter.dart';
import 'validation.dart';

/// Default input buffer length.
const zstdEncoderInputBufferLength = ZstdConstants.ZSTD_BLOCKSIZE_MAX;

/// Default output buffer length.
const zstdEncoderOutputBufferLength = CodecBufferHolder.autoLength;

/// The [ZstdEncoder] encoder is used by [ZstdCodec] to zstd compress data.
class ZstdEncoder extends CodecConverter {
  /// The compression-[level] can be set in the range of
  /// `-[ZstdConstants.ZSTD_TARGETLENGTH_MAX]..22`,
  /// with [ZstdOption.defaultLevel] being the default compression level.
  final int level;

  /// Length in bytes of the buffer used for input data.
  final int inputBufferLength;

  /// Length in bytes of the buffer used for processed output data.
  final int outputBufferLength;

  /// Construct an [ZstdEncoder] with the supplied parameters used by the Zstd
  /// encoder.
  ///
  /// Validation will be performed which may result in a [RangeError] or
  /// [ArgumentError].
  ZstdEncoder(
      {this.level = ZstdOption.defaultLevel,
      this.inputBufferLength = zstdEncoderInputBufferLength,
      this.outputBufferLength = zstdEncoderOutputBufferLength}) {
    validateZstdLevel(level);
  }

  /// Start a chunked conversion using the options given to the [ZstdEncoder]
  /// constructor.
  ///
  /// While it accepts any [Sink] taking [List]'s,
  /// the optimal sink to be passed as [sink] is a [ByteConversionSink].
  @override
  ByteConversionSink startChunkedConversion(Sink<List<int>> sink) {
    final byteSink = asByteSink(sink);
    return _ZstdEncoderSink._(
        byteSink, level, inputBufferLength, outputBufferLength);
  }
}

/// Zstd encoding sink internal implementation.
class _ZstdEncoderSink extends CodecSink {
  _ZstdEncoderSink._(ByteConversionSink sink, int level, int inputBufferLength,
      int outputBufferLength)
      : super(
            sink,
            _makeZstdCompressFilter(
                level, inputBufferLength, outputBufferLength));
}

/// Construct a new [ZstdCompressFilter] which is configured with the options
/// provided.
///
/// There is a conditional import that determines the implementation of
/// [ZstdCompressFilter] based on the environment.
CodecFilter _makeZstdCompressFilter(
    int level, int inputBufferLength, int outputBufferLength) {
  return ZstdCompressFilter(
      level: level,
      inputBufferLength: inputBufferLength,
      outputBufferLength: outputBufferLength);
}
