// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import '../codec.dart';

/// Library function used by [BrotliCodec] static function that gets the custom
/// library path.
///
/// This is the stubbed version that be a no-op.
String brotliGetLibraryPath() => null;

/// Library function used by [BrotliCodec] static function that sets a custom
/// library path.
///
/// This is the stubbed version that be a no-op.
void brotliSetLibraryPath(String path) => null;

/// Extension that provides suitable stubs for [BrotliCodec]s in non-IO
/// environments.
///
/// This includes:
/// - Version number as 0
/// - No-Op for setting user defined library paths
/// - Encoder/Decoder getter stubs that throw [UnsupportedError]s
extension BrotliCodecStub on BrotliCodec {
  /// Return stubbed version number for the encoder.
  int get encoderVersionNumber => 0;

  /// Return stubbed version number for the decoder.
  int get decoderVersionNumber => 0;

  /// No-op stubbed user-defined library path setter.
  set userDefinedLibraryPath(String libraryPath) {}

  /// Raise an [UnsupportedError] for missing encoder.
  Converter<List<int>, List<int>> get encoderImpl =>
      throw UnsupportedError('No Encoder Implementation');

  /// Raise an [UnsupportedError] for missing decoder.
  Converter<List<int>, List<int>> get decoderImpl =>
      throw UnsupportedError('No Decoder Implementation');
}
