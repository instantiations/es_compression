// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:es_compression/zstd.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';

void main() {
  test('Test Empty Zstd Encode/Decode', () {
    final data = '';
    final header = [40, 181, 47, 253, 0, 88, 1, 0, 0];
    final dataBytes = utf8.encode(data);
    final codec = ZstdCodec();
    final encoded = codec.encode(dataBytes);
    expect(const ListEquality<int>().equals(encoded, header), true);
    final decoded = zstd.decode(encoded);
    expect(const ListEquality<int>().equals(dataBytes, decoded), true);
  });

  test('Test Simple Zstd Encode/Decode', () {
    final data = 'MyDart';
    final expected = [40, 181, 47, 253, 0, 88, 48, 0, 0, 77, 121, 68, 97, 114, 116, 1, 0, 0];
    final dataBytes = utf8.encode(data);
    final codec = ZstdCodec();
    final encoded = codec.encode(dataBytes);
    expect(const ListEquality<int>().equals(encoded, expected), true);
    final decoded = zstd.decode(encoded);
    expect(const ListEquality<int>().equals(dataBytes, decoded), true);
  });
}