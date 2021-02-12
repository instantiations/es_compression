// Copyright (c) 2021, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'constants.dart';

/// Opaque Struct: *LZ4F_cctx*
/// File: *lz4frame.h*
class Lz4Cctx extends Opaque {}

/// Opaque Struct: *LZ4F_dctx*
/// File: *lz4frame.h*
class Lz4Dctx extends Opaque {}

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
  external int blockSizeID;

  /// [Lz4Constants.LZ4F_blockLinked],
  /// [Lz4Constants.LZ4F_blockIndependent],
  /// Default: [Lz4Constants.LZ4F_blockLinked].
  @Int32()
  external int blockMode;

  /// [Lz4Constants.LZ4F_noContentChecksum],
  /// [Lz4Constants.LZ4F_contentChecksumEnabled],
  /// Default: [Lz4Constants.LZ4F_noContentChecksum].
  @Int32()
  external int contentChecksumFlag;

  /// [Lz4Constants.LZ4F_frame],
  /// [Lz4Constants.LZ4F_skippableFrame],
  /// Default: [Lz4Constants.LZ4F_frame].
  @Int32()
  external int frameType;

  /// Size of uncompressed content.
  /// Default: 0 (unknown).
  @Uint64()
  external int contentSize;

  /// Dictionary ID, sent by compressor to help decoder select correct
  /// dictionary.
  /// Default: 0 (no dictID provided).
  @Int32()
  external int dictID;

  /// [Lz4Constants.LZ4F_noBlockChecksum],
  /// [Lz4Constants.LZ4F_blockChecksumEnabled],
  /// Default: [Lz4Constants.LZ4F_noBlockChecksum].
  @Int32()
  external int blockChecksumFlag;

  /// Return the block size, in bytes, for the id.
  int get blockSize => _blockSizeForId(blockSizeID);

  /// Allocate a [Lz4FrameInfo] struct and provide default values.
  static Pointer<Lz4FrameInfo> allocate() {
    final frameInfo = malloc<Lz4FrameInfo>();
    frameInfo.ref
      ..blockSizeID = Lz4Constants.LZ4F_max64KB
      ..blockMode = Lz4Constants.LZ4F_blockLinked
      ..contentChecksumFlag = Lz4Constants.LZ4F_noContentChecksum
      ..frameType = Lz4Constants.LZ4F_frame
      ..contentSize = 0
      ..dictID = 0
      ..blockChecksumFlag = Lz4Constants.LZ4F_noBlockChecksum;
    return frameInfo;
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
  external int frameInfoBlockSizeID;

  /// Nested Struct Field
  /// @see [Lz4FrameInfo.blockMode]
  @Int32()
  external int frameInfoBlockMode;

  /// Nested Struct Field
  /// @see [Lz4FrameInfo.contentChecksumFlag]
  @Int32()
  external int frameInfoContentChecksumFlag;

  /// Nested Struct Field
  /// @see [Lz4FrameInfo.frameType]
  @Int32()
  external int frameInfoFrameType;

  /// Nested Struct Field
  /// @see [Lz4FrameInfo.contentSize]
  @Uint64()
  external int frameInfoContentSize;

  /// Nested Struct Field
  /// @see [Lz4FrameInfo.dictID]
  @Uint32()
  external int frameInfoDictID;

  /// Nested Struct Field
  /// @see [Lz4FrameInfo.blockChecksumFlag]
  @Int32()
  external int frameInfoBlockChecksumFlag;

  // End Nested Lz4FrameInfo

  /// 0: default (fast mode),
  /// values > [Lz4Constants.LZ4HC_CLEVEL_MAX] count as
  /// [Lz4Constants.LZ4HC_CLEVEL_MAX];
  /// values < 0 trigger "fast acceleration"
  @Int32()
  external int compressionLevel;

  /// 1: always flush: reduces usage of internal buffers
  @Uint32()
  external int autoFlush;

  /// 1: parser favors decompression speed vs compression ratio.
  /// Only works for high compression modes
  /// (>= [Lz4Constants.LZ4HC_CLEVEL_OPT_MIN].
  @Uint32()
  external int favorDecSpeed;

  /// Return the block size, in bytes, for the id.
  int get blockSize => _blockSizeForId(frameInfoBlockSizeID);

  /// Allocate a [Lz4Preferences] struct and provide default values.
  static Pointer<Lz4Preferences> allocate() {
    final prefs = malloc<Lz4Preferences>();
    prefs.ref
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
    return prefs;
  }
}

/// Struct: *LZ4F_compressOptions_t*
/// File: *lz4frame.h*
class Lz4CompressOptions extends Struct {
  /// 1 == src content will remain present on future calls to LZ4F_compress();
  /// skip copying src content within tmp buffer
  @Uint32()
  external int stableSrc;

  /// reserved[0]
  @Uint8()
  external int reserved1;

  /// reserved[1]
  @Uint8()
  external int reserved2;

  /// reserved[2]
  @Uint8()
  external int reserved3;

  /// Allocate a [Lz4CompressOptions] struct and provide default values.
  static Pointer<Lz4CompressOptions> allocate() {
    final options = malloc<Lz4CompressOptions>();
    options.ref
      ..stableSrc = 0
      ..reserved1 = 0
      ..reserved2 = 0
      ..reserved3 = 0;
    return options;
  }
}

/// Struct: *LZ4F_decompressOptions_t*
/// File: *lz4frame.h*
class Lz4DecompressOptions extends Struct {
  /// 1 == src content will remain present on future calls to LZ4F_compress();
  /// skip copying src content within tmp buffer
  @Uint32()
  external int stableSrc;

  /// reserved[0]
  @Uint8()
  external int reserved1;

  /// reserved[1]
  @Uint8()
  external int reserved2;

  /// reserved[2]
  @Uint8()
  external int reserved3;

  /// Allocate a [Lz4DecompressOptions] struct and provide default values.
  static Pointer<Lz4DecompressOptions> allocate() {
    final options = malloc<Lz4DecompressOptions>();
    options.ref
      ..stableSrc = 0
      ..reserved1 = 0
      ..reserved2 = 0
      ..reserved3 = 0;
    return options;
  }
}

/// Contains refs to required types (structs...) referenced by the
/// following header files:
/// *lz4.h*
/// *lz4frame.h*
mixin Lz4Types {
  /// Return an allocated [Lz4Preferences] struct.
  Pointer<Lz4Preferences> newPreferences(
      {int? level = 0,
      bool? fastAcceleration = false,
      bool? contentChecksum = false,
      bool? blockChecksum = false,
      bool? blockLinked = true,
      int? blockSize = Lz4Constants.LZ4F_max64KB,
      bool? optimizeForCompression = false}) {
    final prefs = Lz4Preferences.allocate();
    prefs.ref
      ..compressionLevel =
          (fastAcceleration ?? false) ? -(level ?? 0) : level ?? 0
      ..frameInfoContentChecksumFlag = (contentChecksum ?? false) ? 1 : 0
      ..frameInfoBlockChecksumFlag = (blockChecksum ?? false) ? 1 : 0
      ..frameInfoBlockMode = (blockLinked ?? true)
          ? Lz4Constants.LZ4F_blockLinked
          : Lz4Constants.LZ4F_blockIndependent
      ..frameInfoBlockSizeID = blockSize ?? Lz4Constants.LZ4F_max64KB
      ..favorDecSpeed = (optimizeForCompression ?? false) ? 1 : 0;
    return prefs;
  }

  /// Return an allocated [Lz4FrameInfo] struct.
  Pointer<Lz4FrameInfo> newFrameInfo() => Lz4FrameInfo.allocate();

  /// Return an allocated [Lz4CompressOptions] struct.
  Pointer<Lz4CompressOptions> newCompressOptions() =>
      Lz4CompressOptions.allocate();

  /// Return an allocated [Lz4DecompressOptions] struct.
  Pointer<Lz4DecompressOptions> newDecompressOptions() =>
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
