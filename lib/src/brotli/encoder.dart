// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import '../framework/buffers.dart';
import '../framework/converters.dart';
import '../framework/filters.dart';
import '../framework/sinks.dart';
import 'options.dart';
import 'stubs/compress_filter.dart'
    if (dart.library.io) 'ffi/compress_filter.dart';
import 'validation.dart';

/// Default input buffer length.
const brotliEncoderInputBufferLength = 64 * 1024;

/// Default output buffer length.
const brotliEncoderOutputBufferLength = brotliEncoderInputBufferLength;

/// The [BrotliEncoder] encoder is used by [BrotliCodec] to brotli compress
/// data.
class BrotliEncoder extends CodecConverter {
  /// The compression-[level] or quality can be set in the range of
  /// [BrotliOption.minLevel]..[BrotliOption.maxLevel].
  /// The higher the level, the slower the compression.
  /// Default: [BrotliOption.defaultLevel].
  final int level;

  /// Tune the encoder for a specific input.
  /// The allowable values are:
  /// [BrotliOption.fontMode], [BrotliOption.genericMode],
  /// [BrotliOption.textMode], [BrotliOption.defaultMode].
  /// Default: [BrotliOption.defaultMode].
  final int mode;

  /// Recommended sliding LZ77 windows bit size.
  /// The encoder may reduce this value if the input is much smaller than the
  /// windows size.
  /// Range: [BrotliOption.minWindowBits]..[BrotliOption.maxWindowBits].
  /// Default: [BrotliOption.defaultWindowBits].
  final int windowBits;

  /// Recommended input block size.
  /// Encoder may reduce this value, e.g. if the input is much smalltalk than
  /// the input block size.
  /// Range: [BrotliOption.minBlockBits]..[BrotliOption.maxBlockBits].
  /// Default: nil (dynamically computed).
  final int blockBits;

  /// Recommended number of postfix bits.
  /// Encode may change this value.
  /// Range: [BrotliOption.minPostfixBits]..[BrotliOption.maxPostfixBits].
  final int postfixBits;

  /// Flag that affects usage of "literal context modeling" format feature.
  /// This flag is a "decoding-speed vs compression ratio" trade-off.
  /// Default: [:true:].
  final bool literalContextModeling;

  /// Estimated total input size for all encoding compress stream calls.
  /// Default: 0 (means the total input size if unknown).
  final int sizeHint;

  /// Flag that determines if "Large Window Brotli" is used.
  /// If set to [:true:], then the LZ-Window can be set up to 30-bits but the
  /// result will not be RFC7932 compliant.
  /// Default: [:false:].
  final bool largeWindow;

  /// Recommended number of direct distance codes.
  /// Encoder may change this value.
  final int directDistanceCodeCount;

  /// Length in bytes of the buffer used for input data.
  final int inputBufferLength;

  /// Length in bytes of the buffer used for processed output data.
  final int outputBufferLength;

  /// Construct an [BrotliEncoder] with the supplied parameters used by the
  /// Brotli encoder.
  ///
  /// Validation will be performed which may result in a [RangeError] or
  /// [ArgumentError].
  BrotliEncoder(
      {this.level = BrotliOption.defaultLevel,
      this.mode = BrotliOption.defaultMode,
      this.windowBits = BrotliOption.defaultWindowBits,
      this.blockBits,
      this.postfixBits,
      this.literalContextModeling = true,
      this.sizeHint = 0,
      this.largeWindow = false,
      this.directDistanceCodeCount,
      this.inputBufferLength = CodecBufferHolder.autoLength,
      this.outputBufferLength = CodecBufferHolder.autoLength}) {
    validateBrotliLevel(level);
    validateBrotliWindowBits(windowBits);
    validateBrotliBlockBits(blockBits);
    validateBrotliPostfixBits(postfixBits);
  }

  /// Start a chunked conversion using the options given to the [BrotliEncoder]
  /// constructor.
  ///
  /// While it accepts any [Sink] taking [List]'s,
  /// the optimal sink to be passed as [sink] is a [ByteConversionSink].
  @override
  ByteConversionSink startChunkedConversion(Sink<List<int>> sink) {
    final byteSink = asByteSink(sink);
    return _BrotliEncoderSink._(
        byteSink,
        level,
        mode,
        windowBits,
        blockBits,
        postfixBits,
        literalContextModeling,
        sizeHint,
        largeWindow,
        directDistanceCodeCount,
        inputBufferLength,
        outputBufferLength);
  }
}

/// Brotli encoding sink internal implementation.
class _BrotliEncoderSink extends CodecSink {
  _BrotliEncoderSink._(
      ByteConversionSink sink,
      int level,
      int mode,
      int windowBits,
      int blockBits,
      int postfixBits,
      bool literalContextModeling,
      int sizeHint,
      bool largeWindow,
      int directDistanceCodeCount,
      int inputBufferLength,
      int outputBufferLength)
      : super(
            sink,
            _makeBrotliCompressFilter(
                level,
                mode,
                windowBits,
                blockBits,
                postfixBits,
                literalContextModeling,
                sizeHint,
                largeWindow,
                directDistanceCodeCount,
                inputBufferLength,
                outputBufferLength));
}

/// Construct a new [BrotliCompressFilter] which is configured with the options
/// provided.
///
/// There is a conditional import that determines the implementation of
/// [BrotliCompressFilter] based on the environment.
CodecFilter _makeBrotliCompressFilter(
    int level,
    int mode,
    int windowBits,
    int blockBits,
    int postfixBits,
    bool literalContextModeling,
    int sizeHint,
    bool largeWindow,
    int directDistanceCodeCount,
    int inputBufferLength,
    int outputBufferLength) {
  return BrotliCompressFilter(
      level: level,
      mode: mode,
      windowBits: windowBits,
      blockBits: blockBits,
      postfixBits: postfixBits,
      literalContextModeling: literalContextModeling,
      sizeHint: sizeHint,
      largeWindow: largeWindow,
      directDistanceCodeCount: directDistanceCodeCount,
      inputBufferLength: inputBufferLength,
      outputBufferLength: outputBufferLength);
}
