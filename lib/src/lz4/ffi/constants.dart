// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

// ignore_for_file: public_member_api_docs, constant_identifier_names

/// Contains required constants referenced by the following header files:
/// *lz4.h*
/// *lz4hc.h*
/// *lz4frame.h*
mixin Lz4Constants {
  // HEADER FILE: lz4.h
  static const LZ4_MAX_INPUT_SIZE = 0x7E000000;

  // HEADER FILE: lz4hc.h
  static const LZ4HC_CLEVEL_MIN = 3;
  static const LZ4HC_CLEVEL_DEFAULT = 9;
  static const LZ4HC_CLEVEL_OPT_MIN = 10;
  static const LZ4HC_CLEVEL_MAX = 12;

  // HEADER FILE: lz4frame.h

  // This number can be used to check for an incompatible API breaking change
  static const LZ4F_VERSION = 100;

  // LZ4 Frame header size can vary, depending on selected parameters
  static const LZ4F_HEADER_SIZE_MIN = 7;
  static const LZ4F_HEADER_SIZE_MAX = 19;

  // enum LZ4F_blockMode_t
  static const LZ4F_blockLinked = 0;
  static const LZ4F_blockIndependent = 1;

  // enum LZ4F_contentChecksum_t
  static const LZ4F_noContentChecksum = 0;
  static const LZ4F_contentChecksumEnabled = 1;

  // enum LZ4F_blockChecksum_t
  static const LZ4F_noBlockChecksum = 0;
  static const LZ4F_blockChecksumEnabled = 1;

  // enum LZ4F_blockSizeID_t
  static const LZ4F_default = 0;
  static const LZ4F_max64KB = 4;
  static const LZ4F_max256KB = 5;
  static const LZ4F_max1MB = 6;
  static const LZ4F_max4MB = 7;

  // enum LZ4F_frameType_t
  static const LZ4F_frame = 0;
  static const LZ4F_skippableFrame = 1;
}
