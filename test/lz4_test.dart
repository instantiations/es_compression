// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:es_compression/lz4.dart';
import 'package:test/test.dart';

void main() {
  test('Test Lz4 Version Number', () {
    final codec = lz4;
    final bindingVersion = '1.9.2';
    final libraryVersion = '1.9.3';
    expect(codec.bindingVersion.toString(), bindingVersion);
    expect(codec.libraryVersion.toString(), libraryVersion);
  });

  test('Test Bad Lz4 Decode', () {
    expect(() => lz4.decode(<int>[1, 2, 3]), throwsFormatException);
  });

  test('Test Empty Lz4 Encode/Decode', () {
    final data = '';
    final header = [4, 34, 77, 24, 68, 64, 94, 0, 0, 0, 0, 5, 93, 204, 2];
    final dataBytes = utf8.encode(data);
    final codec = Lz4Codec(contentChecksum: true);
    final encoded = codec.encode(dataBytes);
    expect(const ListEquality<int>().equals(encoded, header), true);
    final decoded = codec.decode(encoded);
    expect(const ListEquality<int>().equals(dataBytes, decoded), true);
  });

  test('Test Simple Lz4 Encode/Decode', () {
    final data = 'MyDart';
    final expected = [
      4,
      34,
      77,
      24,
      68,
      64,
      94,
      6,
      0,
      0,
      128,
      77,
      121,
      68,
      97,
      114,
      116,
      0,
      0,
      0,
      0,
      216,
      176,
      253,
      223
    ];
    final dataBytes = utf8.encode(data);
    final codec = Lz4Codec(contentChecksum: true);
    final encoded = codec.encode(dataBytes);
    expect(const ListEquality<int>().equals(encoded, expected), true);
    final decoded = lz4.decode(encoded);
    expect(const ListEquality<int>().equals(dataBytes, decoded), true);
  });
}
