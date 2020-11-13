// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'ffi/constants.dart';

/// Exposes Lz4 options for input parameters.
abstract class Lz4Option {
  /// Default value for [Lz4Codec.level] and [Lz4Encoder.level].
  static const int defaultLevel = 0;

  /// Minimal value for [Lz4Codec.level] and [Lz4Encoder.level].
  static const int minLevel = -1;

  /// Maximal value for [Lz4Codec.level] and [Lz4Encoder.level].
  static const int maxLevel = 16;

  /// Default max block size for [Lz4Codec.blockSize] and
  /// [Lz4Encoder.blockSize].
  static const int defaultBlockSize = Lz4Constants.LZ4F_default;

  /// 64KB max block size for [Lz4Codec.blockSize] and [Lz4Encoder.blockSize].
  static const int blockSize64KB = Lz4Constants.LZ4F_max64KB;

  /// 256KB max block size for [Lz4Codec.blockSize] and [Lz4Encoder.blockSize].
  static const int blockSize256KB = Lz4Constants.LZ4F_max256KB;

  /// 1MB max block size for [Lz4Codec.blockSize] and [Lz4Encoder.blockSize].
  static const int blockSize1MB = Lz4Constants.LZ4F_max1MB;

  /// 4MB max block size for [Lz4Codec.blockSize] and [Lz4Encoder.blockSize].
  static const int blockSize4MB = Lz4Constants.LZ4F_max4MB;
}
