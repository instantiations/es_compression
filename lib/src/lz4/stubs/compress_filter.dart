// Copyright (c) 2021, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import '../../../framework.dart';

// ignore_for_file: avoid_unused_constructor_parameters

/// Class that provides suitable stubs for [Lz4CompressFilter]s in non-IO
/// environments.
///
/// This includes:
/// - [doProcessing] stubs that throw [UnsupportedError].
class Lz4CompressFilter extends DartCodecFilterBase {
  /// Create a stubbed [Lz4CompressFilter] filter.
  Lz4CompressFilter(
      {int? level,
      bool? fastAcceleration,
      bool? contentChecksum,
      bool? blockChecksum,
      bool? blockLinked,
      int? blockSize,
      bool? optimizeForCompression,
      int inputBufferLength = 16386,
      int outputBufferLength = 16386})
      : super(
            inputBufferLength: inputBufferLength,
            outputBufferLength: outputBufferLength);

  /// Raise an [UnsupportedError] for missing codec filter.
  @override
  CodecResult doProcessing(
      DartCodecBuffer inputBuffer, DartCodecBuffer outputBuffer) {
    throw UnsupportedError('No CodecFilter Implementation');
  }
}
