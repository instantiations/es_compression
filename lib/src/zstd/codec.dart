// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:es_compression/src/zstd/ffi/dispatcher.dart';

import '../../framework.dart';
import 'decoder.dart';
import 'encoder.dart';
import 'ffi/library.dart';
import 'options.dart';

/// The [ZstdCodec] encodes/decodes raw bytes using the Zstd (ZStandard)
/// algorithm.
class ZstdCodec extends Codec<List<int>, List<int>> {
  /// The compression-[level] can be set in the range of `0..16`, with
  /// 0 (fast mode) being the default compression level.
  final int level;

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
  ZstdVersion get bindingVersion => ZstdVersion(10405);

  /// Return the actual library version of the shared library.
  ZstdVersion get libraryVersion => ZstdVersion(ZstdDispatcher.versionNumber);

  /// Construct an [ZstdCodec] that is configured with the following parameters.
  ///
  /// Default values are provided for unspecified parameters.
  /// Validation is performed which may result in throwing a [RangeError] or
  /// [ArgumentError]
  ZstdCodec(
      {this.level = ZstdOption.defaultLevel,
      this.inputBufferLength = CodecBufferHolder.autoLength,
      this.outputBufferLength = CodecBufferHolder.autoLength,
      String libraryPath}) {
    validateZstdLevel(level);
    if (libraryPath != null) ZstdLibrary.userDefinedLibraryPath = libraryPath;
  }

  const ZstdCodec._default()
      : level = ZstdOption.defaultLevel,
        inputBufferLength = CodecBufferHolder.autoLength,
        outputBufferLength = CodecBufferHolder.autoLength;

  @override
  Converter<List<int>, List<int>> get encoder => ZstdEncoder(
      level: level,
      inputBufferLength: inputBufferLength,
      outputBufferLength: outputBufferLength);

  @override
  Converter<List<int>, List<int>> get decoder => ZstdDecoder(
      inputBufferLength: inputBufferLength,
      outputBufferLength: outputBufferLength);
}

/// Helper class to decode the version number returned from the zstd FFI
/// library.
class ZstdVersion {
  /// Encoded version number from zstd.
  final int versionNumber;

  const ZstdVersion(this.versionNumber);

  /// Return the major element of the version.
  int get major => versionNumber ~/ (100 * 100);

  /// Return the minor element of the version.
  int get minor => (versionNumber ~/ 100) - 100;

  /// Return the patch element of the version.
  int get patch => versionNumber - (major * (100 * 100)) - (minor * 100);

  @override
  String toString() => '$major.$minor.$patch';
}

/// An instance of the default implementation of the [ZstdCodec].
const ZstdCodec zstd = ZstdCodec._default();
