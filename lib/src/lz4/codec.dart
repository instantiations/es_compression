// Copyright (c) 2021, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import '../../framework.dart';
import 'options.dart';
import 'stubs/codec.dart' if (dart.library.io) 'ffi/codec.dart';
import 'validation.dart';
import 'version.dart';

/// The [Lz4Codec] encodes raw bytes to Lz4 compressed bytes and decodes Lz4
/// compressed bytes to raw bytes using the Lz4 frame format.
class Lz4Codec extends Codec<List<int>, List<int>> {
  /// Return the library path [String] or [:null:] if not set.
  static String? get libraryPath => lz4GetLibraryPath();

  /// Set the custom library [path]
  ///
  /// Throw a [StateError] if the library has already been initialized.
  static set libraryPath(String? path) => lz4SetLibraryPath(path);

  /// The compression-[level] can be set in the range of `0..16`, with
  /// 0 (fast mode) being the default compression level.
  final int level;

  /// When true, use ultra-fast compression speed mode, at the cost of some
  /// compression ratio. The default value is false.
  final bool fastAcceleration;

  /// When true, a checksum is added to the end of a frame during compression,
  /// and checked during decompression. An enabled, all blocks are present and
  /// in the correct order. The default value is false.
  final bool contentChecksum;

  /// When true, a checksum is added to the end of each block during
  /// compression, and validates the block data during decompression.
  /// The default value is false.
  final bool blockChecksum;

  /// When true, blocks are compressed in linked mode which dramatically
  /// improves compression, specifically for small blocks.
  /// The default value is true.
  final bool blockLinked;

  /// The maximum size to use for blocks. The larger the block, the (slightly)
  /// better compression ratio. However, more memory is consumed for both
  /// compression and decompression. The default value is blockSize64KB.
  final int blockSize;

  /// When true, generate compress data optimized for decompression speed.
  /// The size of the compressed data may be slightly larger, however the
  /// decompression speed should be improved.
  /// **Note: This option will be ignored if [level] < 9**.
  final bool optimizeForDecompression;

  /// Length in bytes of the buffer used for input data.
  ///
  /// Note: This is a preferred value. There are algorithm specific
  /// constraints that may need to coerce this value to a required minimum or
  /// maximum.
  final int inputBufferLength;

  /// Length in bytes of the buffer used for processed output data.
  ///
  /// Note: This is a preferred value. There are algorithm specific
  /// constraints that may need to coerce this value to a required minimum or
  /// maximum.
  final int outputBufferLength;

  /// Return the base binding version this binding code was developed for.
  Lz4Version get bindingVersion => const Lz4Version(10904);

  /// Return the actual library version of the shared library.
  Lz4Version get libraryVersion => Lz4Version(libraryVersionNumber);

  /// Construct an [Lz4Codec] that is configured with the following parameters.
  ///
  /// Default values are provided for unspecified parameters.
  /// Validation is performed which may result in throwing a [RangeError] or
  /// [ArgumentError].
  Lz4Codec(
      {this.level = Lz4Option.defaultLevel,
      this.fastAcceleration = false,
      this.contentChecksum = false,
      this.blockChecksum = false,
      this.blockLinked = true,
      this.blockSize = Lz4Option.defaultBlockSize,
      this.optimizeForDecompression = false,
      this.inputBufferLength = CodecBufferHolder.autoLength,
      this.outputBufferLength = CodecBufferHolder.autoLength}) {
    validateLz4Level(level);
    validateLz4BlockSize(blockSize);
  }

  /// Internal Constructor for building the [lz4] instance.
  const Lz4Codec._default()
      : level = Lz4Option.defaultLevel,
        fastAcceleration = false,
        contentChecksum = false,
        blockChecksum = false,
        blockLinked = true,
        blockSize = Lz4Option.defaultBlockSize,
        optimizeForDecompression = false,
        inputBufferLength = CodecBufferHolder.autoLength,
        outputBufferLength = CodecBufferHolder.autoLength;

  /// Return the lz4 encoder configured implementation.
  @override
  Converter<List<int>, List<int>> get encoder => encoderImpl;

  /// Return the lz4 decoder configured implementation.
  @override
  Converter<List<int>, List<int>> get decoder => decoderImpl;
}

/// An instance of the default implementation of the [Lz4Codec].
const Lz4Codec lz4 = Lz4Codec._default();
