// Copyright (c) 2020, Seth Berman (Instantiations, Inc). Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:es_compression/lz4.dart';

const randomByteCount = 256;
const level = -1;
const tutoneConstant = 8675309;

/// This program demonstrates an lz4 encode/decode of random bytes.
///
/// The [exitCode] of this script is 0 if the decoded bytes match the original,
/// otherwise the [exitCode] is -1.
void main() {
  final random = Random(tutoneConstant);
  final randomBytes =
      List<int>.generate(randomByteCount, (i) => random.nextInt(256));
  final codec = Lz4Codec(level: level);

  final encoded = codec.encode(randomBytes);
  final decoded = codec.decode(encoded);

  final bytesMatch = const ListEquality<int>().equals(randomBytes, decoded);
  (bytesMatch == true) ? print('bytes match!') : print('bytes do not match!');
  exitCode = (bytesMatch == true) ? 0 : -1;
}
