// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import '../codec.dart';
import '../decoder.dart';
import '../encoder.dart';
import 'dispatcher.dart';
import 'library.dart';

/// Library function used by [Lz4Codec] static function that gets the custom
/// library path.
///
/// Return the [String] library path or [:null:] if none is set.
String lz4GetLibraryPath() => Lz4Library.userDefinedLibraryPath;

/// Library function used by [Lz4Codec] static function that sets a custom
/// library path.
///
/// This forwards the request to the [Lz4Library].
void lz4SetLibraryPath(String path) => Lz4Library.userDefinedLibraryPath = path;

/// Extension that provides the `dart:io` dependent part of [Lz4Codec],
/// specifically FFI.
///
/// This includes:
/// - Version number which is queried from FFI call.
/// - Overriding library path which communicates with an FFI library object.
/// - Encoder/Decoder which has dependencies on FFI.
extension Lz4CodecFFI on Lz4Codec {
  /// Return the Lz4 version number.
  int get libraryVersionNumber => Lz4Dispatcher.versionNumber;

  /// Set the user override library path by forwarding to [Lz4Library].
  set userDefinedLibraryPath(String libraryPath) =>
      Lz4Library.userDefinedLibraryPath = libraryPath;

  /// Return a [Lz4Encoder] configured with the relevant encoding parameters.
  Converter<List<int>, List<int>> get encoderImpl => Lz4Encoder(
      level: level,
      fastAcceleration: fastAcceleration,
      contentChecksum: contentChecksum,
      blockChecksum: blockChecksum,
      blockLinked: blockLinked,
      blockSize: blockSize,
      optimizeForDecompression: optimizeForDecompression,
      inputBufferLength: inputBufferLength,
      outputBufferLength: outputBufferLength);

  /// Return a [Lz4Decoder] configured with the relevant decoding parameters.
  Converter<List<int>, List<int>> get decoderImpl => Lz4Decoder(
      inputBufferLength: inputBufferLength,
      outputBufferLength: outputBufferLength);
}
