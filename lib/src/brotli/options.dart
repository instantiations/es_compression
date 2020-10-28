// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

/// Exposes Brotli options for input parameters
abstract class BrotliOption {
  /// Default value for [BrotliCodec.level] and [BrotliEncoder.level].
  static const int defaultLevel = 11;

  /// Minimal value for [BrotliCodec.level] and [BrotliEncoder.level].
  static const int minLevel = 0;

  /// Maximal value for [BrotliCodec.level] and [BrotliEncoder.level].
  static const int maxLevel = 11;

  /// Default mode is [genericMode]
  static const int defaultMode = genericMode;

  /// Compression mode used in WOFF 2.0.
  static const int fontMode = 2;

  /// In this mode compressor does not know anything in advance about the
  /// properties of the input.
  static const int genericMode = 0;

  /// Compression mode for UTF-8 formatted text input.
  static const int textMode = 0;

  static const int defaultWindowBits = 22;

  static const int minWindowBits = 10;

  static const int maxWindowBits = 24;

  static const int minBlockBits = 16;

  static const int maxBlockBits = 24;

  static const int minPostfixBits = 0;

  static const int maxPostfixBits = 3;
}

/// Validate the brotli compression level is within range.
void validateBrotliLevel(int level) {
  if (BrotliOption.minLevel > level || BrotliOption.maxLevel < level) {
    throw RangeError.range(level, BrotliOption.minLevel, BrotliOption.maxLevel);
  }
}

/// Validate the brotli window bits is within range.
void validateBrotliWindowBits(int windowBits) {
  if (BrotliOption.minWindowBits > windowBits ||
      BrotliOption.maxWindowBits < windowBits) {
    throw RangeError.range(
        windowBits, BrotliOption.minWindowBits, BrotliOption.maxWindowBits);
  }
}

/// Validate the brotli block bits is within range.
void validateBrotliBlockBits(int blockBits) {
  if (blockBits != null &&
      blockBits != 0 &&
      (BrotliOption.minBlockBits > blockBits ||
          BrotliOption.maxWindowBits < blockBits)) {
    throw RangeError.range(
        blockBits, BrotliOption.minBlockBits, BrotliOption.maxWindowBits);
  }
}

/// Validate the brotli postfix bits is within range.
void validateBrotliPostfixBits(int postfixBits) {
  if (postfixBits != null &&
      (BrotliOption.minPostfixBits > postfixBits ||
          BrotliOption.maxPostfixBits < postfixBits)) {
    throw RangeError.range(
        postfixBits, BrotliOption.minPostfixBits, BrotliOption.maxPostfixBits);
  }
}
