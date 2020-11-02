// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:es_compression/zstd.dart';
import 'package:test/test.dart';

void main() {
  test('Test Zstd Version Number', () {
    final codec = zstd;
    final bindingVersion = '1.4.5';
    expect(codec.bindingVersion.toString(), bindingVersion);
    expect(codec.libraryVersion.toString(), bindingVersion);
  });

  test('Test Bad Zstd Decode', () {
    expect(zstd.decode(<int>[1, 2, 3, -2]), <int>[]);
  });

  test('Test Empty Zstd Encode/Decode', () {
    final data = '';
    final header = [40, 181, 47, 253, 0, 88, 1, 0, 0];
    final dataBytes = utf8.encode(data);
    final codec = ZstdCodec();
    final encoded = codec.encode(dataBytes);
    expect(const ListEquality<int>().equals(encoded, header), true);
    final decoded = codec.decode(encoded);
    expect(const ListEquality<int>().equals(dataBytes, decoded), true);
  });

  test('Test Simple Zstd Encode/Decode', () {
    final data = 'MyDart';
    final expected = [
      40,
      181,
      47,
      253,
      0,
      88,
      48,
      0,
      0,
      77,
      121,
      68,
      97,
      114,
      116,
      1,
      0,
      0
    ];
    final dataBytes = utf8.encode(data);
    final codec = ZstdCodec();
    final encoded = codec.encode(dataBytes);
    expect(const ListEquality<int>().equals(encoded, expected), true);
    final decoded = codec.decode(encoded);
    expect(const ListEquality<int>().equals(dataBytes, decoded), true);
  });
}
