// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import '../../../framework.dart';

/// Class that provides suitable stubs for [ZstdDecompressFilter]s in non-IO
/// environments.
///
/// This includes:
/// - [doProcessing] stubs that throw [UnsupportedError].
class ZstdDecompressFilter extends DartCodecFilterBase {
  /// Create a stubbed [ZstdDecompressFilter] filter.
  ZstdDecompressFilter(int inputBufferLength, int outputBufferLength)
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
