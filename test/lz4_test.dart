// Copyright (c) 2021, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:es_compression/lz4.dart';
import 'package:test/test.dart';

void main() {
  test('Test Lz4 Version Number', () {
    const codec = lz4;
    const bindingVersion = '1.9.4';
    const libraryVersion = '1.9.4';
    expect(codec.bindingVersion.toString(), bindingVersion);
    expect(codec.libraryVersion.toString(), libraryVersion);
  });

  test('Test Bad Lz4 Decode', () {
    expect(() => lz4.decode(<int>[1, 2, 3]), throwsFormatException);
  });

  test('Test Empty Lz4 Encode/Decode', () {
    const data = '';
    final header = [4, 34, 77, 24, 68, 64, 94, 0, 0, 0, 0, 5, 93, 204, 2];
    final dataBytes = utf8.encode(data);
    final codec = Lz4Codec(contentChecksum: true);
    final encoded = codec.encode(dataBytes);
    expect(const ListEquality<int>().equals(encoded, header), true);
    final decoded = codec.decode(encoded);
    expect(const ListEquality<int>().equals(dataBytes, decoded), true);
  });

  test('Test Lz4 Decode Empty Stream Produces No Chunks', () async {
    final result =
        await const Stream<List<int>>.empty().transform(lz4.decoder).isEmpty;
    expect(result, isTrue,
        reason: "Stream should be empty and emit no chunks.");
  });

  test('Test Simple Lz4 Encode/Decode', () {
    const data = 'MyDart';
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
