// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import '../../brotli.dart';

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
