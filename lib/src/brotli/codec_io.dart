import 'dart:convert';

import 'codec.dart';
import 'decoder.dart';
import 'encoder.dart';
import 'ffi/dispatcher.dart';
import 'ffi/library.dart';

/// Extension that provides the `dart:io` dependent part of [BrotliCodec].
///
/// This includes:
/// - Version number which is queried from FFI call
/// - Overriding library path which communicates with an FFI library object
/// - Encoder/Decoder which has dependencies on FFI
extension BrotliCodecIO on BrotliCodec {
  /// Return the brotli encoding version number.
  int get encoderVersionNumber => BrotliDispatcher.encoderVersionNumber;

  /// Return the brotli decoding version number.
  int get decoderVersionNumber => BrotliDispatcher.decoderVersionNumber;

  /// Set the user override library path by forwarding to [BrotliLibrary].
  set userDefinedLibraryPath(String libraryPath) =>
      BrotliLibrary.userDefinedLibraryPath = libraryPath;

  /// Return a [BrotliEncoder] configured with the relevant encoding parameters.
  Converter<List<int>, List<int>> get encoderImpl => BrotliEncoder(
      level: level,
      mode: mode,
      windowBits: windowBits,
      blockBits: blockBits,
      postfixBits: postfixBits,
      literalContextModeling: literalContextModeling,
      sizeHint: sizeHint,
      largeWindow: largeWindow,
      directDistanceCodeCount: directDistanceCodeCount,
      inputBufferLength: inputBufferLength,
      outputBufferLength: outputBufferLength);

  /// Return a [BrotliDecoder] configured with the relevant decoding parameters.
  Converter<List<int>, List<int>> get decoderImpl => BrotliDecoder(
      ringBufferReallocation: ringBufferReallocation,
      largeWindow: largeWindow,
      inputBufferLength: inputBufferLength,
      outputBufferLength: outputBufferLength);
}
