// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart' as ffi;

import 'constants.dart';

/// Opaque Struct: *LZ4F_cctx*
/// File: *lz4frame.h*
class Lz4Cctx extends Struct {}

/// Opaque Struct: *LZ4F_dctx*
/// File: *lz4frame.h*
class Lz4Dctx extends Struct {}

/// Struct: *LZ4F_frameInfo_t*
/// File: *lz4frame.h*
///
/// Makes it possible to set or read frame parameters.
class Lz4FrameInfo extends Struct {
  /// [Lz4Constants.LZ4F_max64KB],
  /// [Lz4Constants.LZ4F_max256KB],
  /// [Lz4Constants.LZ4F_max1MB],
  /// [Lz4Constants.LZ4F_max4MB],
  /// Default: [Lz4Constants.LZ4F_max64KB].
  @Int32()
  int blockSizeID;

  /// [Lz4Constants.LZ4F_blockLinked],
  /// [Lz4Constants.LZ4F_blockIndependent],
  /// Default: [Lz4Constants.LZ4F_blockLinked].
  @Int32()
  int blockMode;

  /// [Lz4Constants.LZ4F_noContentChecksum],
  /// [Lz4Constants.LZ4F_contentChecksumEnabled],
  /// Default: [Lz4Constants.LZ4F_noContentChecksum].
  @Int32()
  int contentChecksumFlag;

  /// [Lz4Constants.LZ4F_frame],
  /// [Lz4Constants.LZ4F_skippableFrame],
  /// Default: [Lz4Constants.LZ4F_frame].
  @Int32()
  int frameType;

  /// Size of uncompressed content.
  /// Default: 0 (unknown).
  @Uint64()
  int contentSize;

  /// Dictionary ID, sent by compressor to help decoder select correct
  /// dictionary.
  /// Default: 0 (no dictID provided).
  @Int32()
  int dictID;

  /// [Lz4Constants.LZ4F_noBlockChecksum],
  /// [Lz4Constants.LZ4F_blockChecksumEnabled],
  /// Default: [Lz4Constants.LZ4F_noBlockChecksum].
  @Int32()
  int blockChecksumFlag;

  /// Return the block size, in bytes, for the id.
  int get blockSize => _blockSizeForId(blockSizeID);

  /// Free the memory associated with this struct.
  void free() => ffi.free(addressOf);

  /// Allocate a [Lz4FrameInfo] struct and provide default values.
  factory Lz4FrameInfo.allocate() {
    return ffi.allocate<Lz4FrameInfo>().ref
      ..blockSizeID = Lz4Constants.LZ4F_max64KB
      ..blockMode = Lz4Constants.LZ4F_blockLinked
      ..contentChecksumFlag = Lz4Constants.LZ4F_noContentChecksum
      ..frameType = Lz4Constants.LZ4F_frame
      ..contentSize = 0
      ..dictID = 0
      ..blockChecksumFlag = Lz4Constants.LZ4F_noBlockChecksum;
  }
}

/// Struct: *LZ4F_preferences_t*
/// File: *lz4frame.h*
///
/// Makes it possible to supply advanced compression instructions to
/// streaming interface.
class Lz4Preferences extends Struct {
  // Begin Nested Lz4FrameInfo

  /// Nested Struct Field
  /// @see [Lz4FrameInfo.blockSizeID]
  @Int32()
  int frameInfoBlockSizeID;

  /// Nested Struct Field
  /// @see [Lz4FrameInfo.blockMode]
  @Int32()
  int frameInfoBlockMode;

  /// Nested Struct Field
  /// @see [Lz4FrameInfo.contentChecksumFlag]
  @Int32()
  int frameInfoContentChecksumFlag;

  /// Nested Struct Field
  /// @see [Lz4FrameInfo.frameType]
  @Int32()
  int frameInfoFrameType;

  /// Nested Struct Field
  /// @see [Lz4FrameInfo.contentSize]
  @Uint64()
  int frameInfoContentSize;

  /// Nested Struct Field
  /// @see [Lz4FrameInfo.dictID]
  @Uint32()
  int frameInfoDictID;

  /// Nested Struct Field
  /// @see [Lz4FrameInfo.blockChecksumFlag]
  @Int32()
  int frameInfoBlockChecksumFlag;

  // End Nested Lz4FrameInfo

  /// 0: default (fast mode),
  /// values > [Lz4Constants.LZ4HC_CLEVEL_MAX] count as
  /// [Lz4Constants.LZ4HC_CLEVEL_MAX];
  /// values < 0 trigger "fast acceleration"
  @Int32()
  int compressionLevel;

  /// 1: always flush: reduces usage of internal buffers
  @Uint32()
  int autoFlush;

  /// 1: parser favors decompression speed vs compression ratio.
  /// Only works for high compression modes
  /// (>= [Lz4Constants.LZ4HC_CLEVEL_OPT_MIN].
  @Uint32()
  int favorDecSpeed;

  /// Return the block size, in bytes, for the id.
  int get blockSize => _blockSizeForId(frameInfoBlockSizeID);

  /// Free the memory associated with this struct.
  void free() => ffi.free(addressOf);

  /// Allocate a [Lz4Preferences] struct and provide default values.
  factory Lz4Preferences.allocate() {
    return ffi.allocate<Lz4Preferences>().ref
      ..frameInfoBlockSizeID = Lz4Constants.LZ4F_default
      ..frameInfoBlockMode = Lz4Constants.LZ4F_blockLinked
      ..frameInfoContentChecksumFlag = Lz4Constants.LZ4F_noContentChecksum
      ..frameInfoFrameType = Lz4Constants.LZ4F_frame
      ..frameInfoContentSize = 0
      ..frameInfoDictID = 0
      ..frameInfoBlockChecksumFlag = Lz4Constants.LZ4F_noBlockChecksum
      ..compressionLevel = 0
      ..autoFlush = 0
      ..favorDecSpeed = 0;
  }
}

/// Struct: *LZ4F_compressOptions_t*
/// File: *lz4frame.h*
class Lz4CompressOptions extends Struct {
  /// 1 == src content will remain present on future calls to LZ4F_compress();
  /// skip copying src content within tmp buffer
  @Uint32()
  int stableSrc;

  /// reserved[0]
  @Uint8()
  int reserved1;

  /// reserved[1]
  @Uint8()
  int reserved2;

  /// reserved[2]
  @Uint8()
  int reserved3;

  /// Free the memory associated with this struct.
  void free() => ffi.free(addressOf);

  /// Allocate a [Lz4CompressOptions] struct and provide default values.
  factory Lz4CompressOptions.allocate() {
    return ffi.allocate<Lz4CompressOptions>().ref
      ..stableSrc = 0
      ..reserved1 = 0
      ..reserved2 = 0
      ..reserved3 = 0;
  }
}

/// Struct: *LZ4F_decompressOptions_t*
/// File: *lz4frame.h*
class Lz4DecompressOptions extends Struct {
  /// 1 == src content will remain present on future calls to LZ4F_compress();
  /// skip copying src content within tmp buffer
  @Uint32()
  int stableSrc;

  /// reserved[0]
  @Uint8()
  int reserved1;

  /// reserved[1]
  @Uint8()
  int reserved2;

  /// reserved[2]
  @Uint8()
  int reserved3;

  /// Free the memory associated with this struct.
  void free() => ffi.free(addressOf);

  /// Allocate a [Lz4DecompressOptions] struct and provide default values.
  factory Lz4DecompressOptions.allocate() {
    return ffi.allocate<Lz4DecompressOptions>().ref
      ..stableSrc = 0
      ..reserved1 = 0
      ..reserved2 = 0
      ..reserved3 = 0;
  }
}

/// Contains refs to required types (structs...) referenced by the
/// following header files:
/// *lz4.h*
/// *lz4frame.h*
mixin Lz4Types {
  /// Return an allocated [Lz4Preferences] struct.
  Lz4Preferences newPreferences(
      {int level,
      bool fastAcceleration = false,
      bool contentChecksum = false,
      bool blockChecksum = false,
      bool blockLinked = true,
      int blockSize = Lz4Constants.LZ4F_max64KB,
      bool optimizeForCompression = false}) {
    return Lz4Preferences.allocate()
      ..compressionLevel = (fastAcceleration) ? -level : level
      ..frameInfoContentChecksumFlag = contentChecksum ? 1 : 0
      ..frameInfoBlockChecksumFlag = blockChecksum ? 1 : 0
      ..frameInfoBlockMode = blockLinked
          ? Lz4Constants.LZ4F_blockLinked
          : Lz4Constants.LZ4F_blockIndependent
      ..frameInfoBlockSizeID = blockSize
      ..favorDecSpeed = optimizeForCompression ? 1 : 0;
  }

  /// Return an allocated [Lz4FrameInfo] struct.
  Lz4FrameInfo newFrameInfo() => Lz4FrameInfo.allocate();

  /// Return an allocated [Lz4CompressOptions] struct.
  Lz4CompressOptions newCompressOptions() => Lz4CompressOptions.allocate();

  /// Return an allocated [Lz4DecompressOptions] struct.
  Lz4DecompressOptions newDecompressOptions() =>
      Lz4DecompressOptions.allocate();
}

/// Answer the block size in bytes for the block size [id].
///
/// Callers may provide a default [blockSize], if none then the default size
/// is 65536.
int _blockSizeForId(int id, [int blockSize = 65536]) {
  switch (id) {
    case Lz4Constants.LZ4F_max64KB:
      blockSize = 65536;
      break;
    case Lz4Constants.LZ4F_max256KB:
      blockSize = 262144;
      break;
    case Lz4Constants.LZ4F_max1MB:
      blockSize = 1048576;
      break;
    case Lz4Constants.LZ4F_max4MB:
      blockSize = 4194304;
      break;
  }
  return blockSize;
}
