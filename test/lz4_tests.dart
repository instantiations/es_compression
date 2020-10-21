// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:es_compression/lz4.dart';
import 'package:collection/collection.dart';
import 'package:es_compression/src/lz4/ffi/constants.dart';
import 'package:test/test.dart';

void main() {
  void performEncodeDecode(List<int> expected,
      {int blockSizeId,
      int blockLinked,
      int autoFlush,
      int checksum,
      int compressionLevel}) {
    final codec = Lz4Codec();
    final encoded = codec.encode(expected);
    final actual = codec.decode(encoded);
    expect(const ListEquality<int>().equals(expected, actual), true);
  }

  test('Test Simple LZ4 Encode/Decode', () {
    final data = 'MyDart';
    final dataBytes = utf8.encode(data);
    final codec = Lz4Codec();
    final encoded = codec.encode(dataBytes);
    final decoded = lz4.decode(encoded);
    expect(const ListEquality<int>().equals(dataBytes, decoded), true);
  });

  test('Test Exhaustive LZ4 Encode/Decode', () {
    for (final bufferLength in <int>[
      65534,
      65535,
      65536,
      65537,
      65538,
      262144,
      1048576,
      4194304
    ]) {
      final expected = List<int>.generate(bufferLength, (i) => i % 255);
      for (final exhaustive in <bool>[true, false]) {
        if (exhaustive == true) {
          for (final blockSizeId in <int>[
            Lz4Constants.LZ4F_max64KB,
            Lz4Constants.LZ4F_max256KB,
            Lz4Constants.LZ4F_max1MB,
            Lz4Constants.LZ4F_max4MB
          ]) {
            for (final autoFlush in <bool>[true, false]) {
              for (final blockLinked in <bool>[true, false]) {
                for (final checksum in <bool>[true, false]) {
                  final list = [for (var i = -3; i < 16; i++) i];
                  for (final level in list) {
                    performEncodeDecode(expected,
                        blockSizeId: blockSizeId,
                        autoFlush: autoFlush ? 1 : 0,
                        blockLinked: blockLinked ? 1 : 0,
                        checksum: checksum ? 1 : 0,
                        compressionLevel: level);
                  }
                }
              }
            }
          }
        } else {
          performEncodeDecode(expected);
        }
      }
    }
  });
}
