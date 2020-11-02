// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:es_compression/brotli.dart';

import 'utils/example_utils.dart';

const randomByteCount = 256;
const level = 0;

/// This program demonstrates a brotli encode/decode of random bytes.
///
/// The [exitCode] of this script is 0 if the decoded bytes match the original,
/// otherwise the [exitCode] is -1.
Future<int> main() async {
  exitCode = await _runBrotliExample();
  return exitCode;
}

/// Brotli Example which answers 0 on success, -1 on error
Future<int> _runBrotliExample() async {
  final randomBytes = generateRandomBytes(randomByteCount);
  final codec = BrotliCodec(level: level);

  print('Brotli Encoder Version: ${codec.encoderVersion}');
  print('Brotli Decoder Version: ${codec.decoderVersion}');

  // One-shot encode/decode
  final encoded = codec.encode(randomBytes);
  var decoded = codec.decode(encoded);
  final oneShotResult =
      verifyEquality(randomBytes, decoded, header: 'One-shot: ');

  // Streaming encode/decode
  // Split the random bytes into 10 buckets
  final chunks = splitIntoChunks(randomBytes, 10);
  final randomStream = Stream.fromIterable(chunks);
  decoded = await randomStream
      .transform(codec.encoder)
      .transform(codec.decoder)
      .fold<List<int>>(<int>[], (buffer, data) {
    buffer.addAll(data);
    return buffer;
  });
  final streamResult =
      verifyEquality(randomBytes, decoded, header: 'Streaming: ');
  return (oneShotResult == true && streamResult == true) ? 0 : -1;
}
