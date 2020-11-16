// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import '../../../zstd.dart';
import 'dispatcher.dart';
import 'library.dart';

/// Library function used by [ZstdCodec] static function that gets the custom
/// library path.
///
/// Return the [String] library path or [:null:] if none is set.
String zstdGetLibraryPath() => ZstdLibrary.userDefinedLibraryPath;

/// Library function used by [ZstdCodec] static function that sets a custom
/// library path.
///
/// This forwards the request to the [ZstdLibrary].
void zstdSetLibraryPath(String path) =>
    ZstdLibrary.userDefinedLibraryPath = path;

/// Extension that provides the `dart:io` dependent part of [ZstdCodec].
///
/// This includes:
/// - Version number which is queried from FFI call.
/// - Overriding library path which communicates with an FFI library object.
/// - Encoder/Decoder which has dependencies on FFI.
extension ZstdCodecIO on ZstdCodec {
  /// Return the Zstd version number.
  int get libraryVersionNumber => ZstdDispatcher.versionNumber;

  /// Set the user override library path by forwarding to [ZstdLibrary].
  set userDefinedLibraryPath(String libraryPath) =>
      ZstdLibrary.userDefinedLibraryPath = libraryPath;

  /// Return a [ZstdEncoder] configured with the relevant encoding parameters.
  Converter<List<int>, List<int>> get encoderImpl => ZstdEncoder(
      level: level,
      inputBufferLength: inputBufferLength,
      outputBufferLength: outputBufferLength);

  /// Return a [ZstdDecoder] configured with the relevant decoding parameters.
  Converter<List<int>, List<int>> get decoderImpl => ZstdDecoder(
      inputBufferLength: inputBufferLength,
      outputBufferLength: outputBufferLength);
}
