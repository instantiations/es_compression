// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'ffi/constants.dart';

/// Exposes Zstd options for input parameters.
abstract class ZstdOption {
  /// Default value for [ZstdCodec.level] and [ZstdEncoder.level].
  static const int defaultLevel = ZstdConstants.ZSTD_CLEVEL_DEFAULT;

  /// Minimal value for [ZstdCodec.level] and [ZstdEncoder.level].
  static const int minLevel = -ZstdConstants.ZSTD_BLOCKSIZE_MAX;

  /// Maximal value for [ZstdCodec.level] and [ZstdEncoder.level].
  static const int maxLevel = 22;
}
