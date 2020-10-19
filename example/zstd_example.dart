// Copyright (c) 2020, Seth Berman (Instantiations, Inc). Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:es_compression/zstd.dart';

const randomByteCount = 256;
const level = -1;
const tutoneConstant = 8675309;

/// This program demonstrates an zstd encode/decode of random bytes.
///
/// The [exitCode] of this script is 0 if the decoded bytes match the original,
/// otherwise the [exitCode] is -1.
void main() {
  final random = Random(tutoneConstant);
  final randomBytes =
      List<int>.generate(randomByteCount, (i) => random.nextInt(256));
  final codec = ZstdCodec(level: level);

  // One-shot encode/decode
  final encoded = codec.encode(randomBytes);
  final decoded = codec.decode(encoded);
  _verifyEquality(randomBytes, decoded);

  // Streaming encode/decode
  // Split the random bytes into 10 buckets
  final chunks = _splitIntoChunks(randomBytes, 10);
  final randomStream = Stream.fromIterable(chunks);
  randomStream
      .transform(codec.encoder)
      .transform(codec.decoder)
      .fold<List<int>>(<int>[], (buffer, data) {
    buffer.addAll(data);
    return buffer;
  }).then((decoded) {
    _verifyEquality(randomBytes, decoded);
  });
}

/// Verify elements match in [list1] and [list2]
void _verifyEquality(List<int> list1, List<int> list2) {
  final bytesMatch = const ListEquality<int>().equals(list1, list2);
  (bytesMatch == true) ? print('bytes match!') : print('bytes do not match!');
  exitCode = (bytesMatch == true) ? 0 : -1;
}

/// Split [list] into [chunkCount] parts.
/// Any remainder will be added to the final bucket.
List<List<int>> _splitIntoChunks(List<int> list, int chunkCount) {
  var chunks = <List<int>>[];
  var perPart = list.length ~/ chunkCount;
  var leftOver = list.length.remainder(chunkCount) as int;
  for (var i = 0, j = 0; i < chunkCount; i++, j += perPart) {
    chunks.add(list.sublist(
        j, i + 1 == chunkCount ? j + perPart + leftOver : j + perPart));
  }
  return chunks;
}
