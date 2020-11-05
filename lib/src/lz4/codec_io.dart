import 'dart:convert';

import 'codec.dart';
import 'decoder.dart';
import 'encoder.dart';
import 'ffi/dispatcher.dart';
import 'ffi/library.dart';

/// Extension that provides the `dart:io` dependent part of [Lz4Codec].
///
/// This includes:
/// - Version number which is queried from FFI call
/// - Overriding library path which communicates with an FFI library object
/// - Encoder/Decoder which has dependencies on FFI
extension Lz4CodecIO on Lz4Codec {
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
