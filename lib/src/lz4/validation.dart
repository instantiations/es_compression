// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import '../../lz4.dart';

/// Validate the lz4 compression level is within range.
void validateLz4Level(int level) {
  if (Lz4Option.minLevel > level || Lz4Option.maxLevel < level) {
    throw RangeError.range(level, Lz4Option.minLevel, Lz4Option.maxLevel);
  }
}

/// Validate the block size is a known block size.
void validateLz4BlockSize(int blockSize) {
  const blockSizes = [
    Lz4Option.defaultBlockSize,
    Lz4Option.blockSize64KB,
    Lz4Option.blockSize256KB,
    Lz4Option.blockSize1MB,
    Lz4Option.blockSize4MB
  ];
  if (!blockSizes.contains(blockSize)) {
    throw ArgumentError('Invalid blockSize argument');
  }
}
