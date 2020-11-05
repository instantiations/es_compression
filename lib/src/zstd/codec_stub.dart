import 'dart:convert';

import 'codec.dart';

/// Extension that provides suitable stubs for [ZstdCodec]s in non-IO
/// environments.
///
/// This includes:
/// - Version number as 0
/// - No-Op for setting user defined library path
/// - Encoder/Decoder getter stubs that throw [UnsupportedError]s
extension ZstdCodecStub on ZstdCodec {
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
