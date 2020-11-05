import 'dart:convert';

import 'codec.dart';
import 'decoder.dart';
import 'encoder.dart';
import 'ffi/dispatcher.dart';
import 'ffi/library.dart';

/// Extension that provides the `dart:io` dependent part of [ZstdCodec].
///
/// This includes:
/// - Version number which is queried from FFI call
/// - Overriding library path which communicates with an FFI library object
/// - Encoder/Decoder which has dependencies on FFI
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
