// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:es_compression/zstd.dart';
import 'package:test/test.dart';

void main() {
  test('Test Zstd Version Number', () {
    const codec = zstd;
    const bindingVersion = '1.5.4';
    expect(codec.bindingVersion.toString(), bindingVersion);
    expect(codec.libraryVersion.toString(), bindingVersion);
  });

  test('Test Bad Zstd Decode', () {
    expect(() => zstd.decode(<int>[1, 2, 3, -2]), throwsFormatException);
  });

  test('Test Empty Zstd Encode/Decode', () {
    const data = '';
    final header = [40, 181, 47, 253, 0, 88, 1, 0, 0];
    final dataBytes = utf8.encode(data);
    final codec = ZstdCodec();
    final encoded = codec.encode(dataBytes);
    expect(const ListEquality<int>().equals(encoded, header), true);
    final decoded = codec.decode(encoded);
    expect(const ListEquality<int>().equals(dataBytes, decoded), true);
  });

  test('Test Zstd Decode Empty Stream Produces No Chunks', () async {
    final result =
        await const Stream<List<int>>.empty().transform(zstd.decoder).isEmpty;
    expect(result, isTrue,
        reason: "Stream should be empty and emit no chunks.");
  });

  test('Test Simple Zstd Encode/Decode', () {
    const data = 'MyDart';
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
