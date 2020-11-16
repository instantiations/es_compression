// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import '../codec.dart';

/// Library function used by [Lz4Codec] static function that gets the custom
/// library path.
///
/// This is the stubbed version that be a no-op.
String lz4GetLibraryPath() => null;

/// Library function used by [Lz4Codec] static function that sets a custom
/// library path.
///
/// This is the stubbed version that be a no-op.
void lz4SetLibraryPath(String path) => null;

/// Extension that provides suitable stubs for [Lz4Codec]s in non-IO
/// environments.
///
/// This includes:
/// - Version number as 0.
/// - No-Op for setting user defined library path.
/// - Encoder/Decoder getter stubs that throw [UnsupportedError]s.
extension Lz4CodecStub on Lz4Codec {
  /// Return stubbed version number for the encoder.
  int get libraryVersionNumber => 0;

  /// No-op stubbed user-defined library path setter.
  set userDefinedLibraryPath(String libraryPath) {}

  /// Raise an [UnsupportedError] for missing encoder.
  Converter<List<int>, List<int>> get encoderImpl =>
      throw UnsupportedError('No Encoder Implementation');

  /// Raise an [UnsupportedError] for missing decoder.
  Converter<List<int>, List<int>> get decoderImpl =>
      throw UnsupportedError('No Decoder Implementation');
}
