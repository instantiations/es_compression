// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import '../../zstd.dart';

/// Validate the zstd compression level is within range.
void validateZstdLevel(int level) {
  if (ZstdOption.minLevel > level || ZstdOption.maxLevel < level) {
    throw RangeError.range(level, ZstdOption.minLevel, ZstdOption.maxLevel);
  }
}
