// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import '../../framework.dart';
import 'options.dart';
import 'stubs/codec.dart' if (dart.library.io) 'ffi/codec.dart';
import 'validation.dart';
import 'version.dart';

/// The [ZstdCodec] encodes/decodes raw bytes using the Zstd (ZStandard)
/// algorithm.
class ZstdCodec extends Codec<List<int>, List<int>> {
  /// Return the library path [String] or [:null:] if not set.
  static String get libraryPath => zstdGetLibraryPath();

  /// Set the custom library [path]
  ///
  /// Throw a [StateError] if the library has already been initialized.
  static set libraryPath(String path) => zstdSetLibraryPath(path);

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
  ZstdVersion get libraryVersion => ZstdVersion(libraryVersionNumber);

  /// Construct an [ZstdCodec] that is configured with the following parameters.
  ///
  /// Default values are provided for unspecified parameters.
  /// Validation is performed which may result in throwing a [RangeError] or
  /// [ArgumentError]
  ZstdCodec(
      {this.level = ZstdOption.defaultLevel,
      this.inputBufferLength = CodecBufferHolder.autoLength,
      this.outputBufferLength = CodecBufferHolder.autoLength}) {
    validateZstdLevel(level);
  }

  /// Internal Constructor for building the [zstd] instance.
  const ZstdCodec._default()
      : level = ZstdOption.defaultLevel,
        inputBufferLength = CodecBufferHolder.autoLength,
        outputBufferLength = CodecBufferHolder.autoLength;

  /// Return the [ZstdEncoder] configured implementation.
  @override
  Converter<List<int>, List<int>> get encoder => encoderImpl;

  /// Return the [ZstdDecoder] configured implementation.
  @override
  Converter<List<int>, List<int>> get decoder => decoderImpl;
}

/// An instance of the default implementation of the [ZstdCodec].
const ZstdCodec zstd = ZstdCodec._default();
