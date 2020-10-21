// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

// ignore_for_file: public_member_api_docs, constant_identifier_names

/// Contains required constants referenced by the following header files:
/// *zstd.h*
mixin ZstdConstants {
  // HEADER FILE: zstd.h
  static const ZSTD_BLOCKSIZELOG_MAX = 17;
  static const ZSTD_BLOCKSIZE_MAX = 1 << ZSTD_BLOCKSIZELOG_MAX;
  static const ZSTD_CLEVEL_DEFAULT = 3;
  static const ZSTD_CONTENTSIZE_UNKNOWN = -1;
  static const ZSTD_CONTENTSIZE_ERROR = -2;
  static const ZSTD_FRAMEHEADERSIZE_MAX = 18;
  static const ZSTD_FRAMEHEADERSIZE_MIN = 6;
  static const ZSTD_FRAMEHEADERSIZE_PREFIX = 5;
  static const ZSTD_TARGETLENGTH_MAX = ZSTD_BLOCKSIZE_MAX;
}
