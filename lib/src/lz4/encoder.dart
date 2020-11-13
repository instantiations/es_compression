// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import '../framework/converters.dart';
import '../framework/filters.dart';
import '../framework/sinks.dart';
import 'codec.dart';
import 'options.dart';
import 'stubs/compress_filter.dart'
    if (dart.library.io) 'ffi/compress_filter.dart';
import 'validation.dart';

/// Default input buffer length.
const lz4EncoderInputBufferLength = 256 * 1024;

/// Default output buffer length.
const lz4EncoderOutputBufferLength = lz4EncoderInputBufferLength;

/// The [Lz4Encoder] encoder is used by [Lz4Codec] to lz4 compress data.
class Lz4Encoder extends CodecConverter {
  /// The compression-[level] can be set in the range of `0..16`, with
  /// 0 (fast mode) being the default compression level.
  final int level;

  /// When true, use ultra-fast compression speed mode, at the cost of some
  /// compression ratio. The default value is false.
  final bool fastAcceleration;

  /// When true, a checksum is added to the end of a frame during compression,
  /// and checked during decompression. An enabled, all blocks are present and
  /// in the correct order. The default value is false.
  final bool contentChecksum;

  /// When true, a checksum is added to the end of each block during
  /// compression, and validates the block data during decompression.
  /// The default value is false.
  final bool blockChecksum;

  /// When true, blocks are compressed in linked mode which dramatically
  /// improves compression, specifically for small blocks.
  /// The default value is true.
  final bool blockLinked;

  /// The maximum size to use for blocks. The larger the block, the (slightly)
  /// better compression ratio. However, more memory is consumed for both
  /// compression and decompression. The default value is blockSize64KB.
  final int blockSize;

  /// When true, generate compress data optimized for decompression speed.
  /// The size of the compressed data may be slightly larger, however the
  /// decompression speed should be improved.
  /// **Note: This option will be ignored if [level] < 9**.
  final bool optimizeForDecompression;

  /// Length in bytes of the buffer used for input data.
  final int inputBufferLength;

  /// Length in bytes of the buffer used for processed output data.
  final int outputBufferLength;

  /// Construct an [Lz4Encoder] with the supplied parameters used by the Lz4
  /// encoder.
  ///
  /// Validation will be performed which may result in a [RangeError] or
  /// [ArgumentError].
  Lz4Encoder(
      {this.level = Lz4Option.defaultLevel,
      this.fastAcceleration = false,
      this.contentChecksum = false,
      this.blockChecksum = false,
      this.blockLinked = true,
      this.blockSize = Lz4Option.defaultBlockSize,
      this.optimizeForDecompression = false,
      this.inputBufferLength = lz4EncoderInputBufferLength,
      this.outputBufferLength = lz4EncoderOutputBufferLength}) {
    validateLz4Level(level);
    validateLz4BlockSize(blockSize);
  }

  /// Start a chunked conversion using the options given to the [Lz4Encoder]
  /// constructor.
  ///
  /// While it accepts any [Sink] taking [List]'s,
  /// the optimal sink to be passed as [sink] is a [ByteConversionSink].
  @override
  ByteConversionSink startChunkedConversion(Sink<List<int>> sink) {
    final byteSink = asByteSink(sink);
    return _Lz4EncoderSink._(
        byteSink,
        level,
        fastAcceleration,
        contentChecksum,
        blockChecksum,
        blockLinked,
        blockSize,
        optimizeForDecompression,
        inputBufferLength,
        outputBufferLength);
  }
}

/// Lz4 encoding sink internal implementation.
class _Lz4EncoderSink extends CodecSink {
  _Lz4EncoderSink._(
      ByteConversionSink sink,
      int level,
      bool fastAcceleration,
      bool contentChecksum,
      bool blockChecksum,
      bool blockLinked,
      int blockSize,
      bool optimizeForDecompression,
      int inputBufferLength,
      int outputBufferLength)
      : super(
            sink,
            _makeLz4CompressFilter(
                level,
                fastAcceleration,
                contentChecksum,
                blockChecksum,
                blockLinked,
                blockSize,
                optimizeForDecompression,
                inputBufferLength,
                outputBufferLength));
}

/// Construct a new [Lz4CompressFilter] which is configured with the options
/// provided.
///
/// There is a conditional import that determines the implementation of
/// [Lz4CompressFilter] based on the environment.
CodecFilter _makeLz4CompressFilter(
    int level,
    bool fastAcceleration,
    bool contentChecksum,
    bool blockChecksum,
    bool blockLinked,
    int blockSize,
    bool optimizeForCompression,
    int inputBufferLength,
    int outputBufferLength) {
  return Lz4CompressFilter(
      level: level,
      fastAcceleration: fastAcceleration,
      contentChecksum: contentChecksum,
      blockChecksum: blockChecksum,
      blockLinked: blockLinked,
      blockSize: blockSize,
      optimizeForCompression: optimizeForCompression,
      inputBufferLength: inputBufferLength,
      outputBufferLength: outputBufferLength);
}
