// Copyright (c) 2020, Seth Berman (Instantiations, Inc). Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:es_compression/brotli.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';

void main() {
  test('Test Empty Brotli Encode/Decode', () {
    final data = '';
    final header = [107, 0, 3];
    final dataBytes = utf8.encode(data);
    final codec = BrotliCodec();
    final encoded = codec.encode(dataBytes);
    expect(const ListEquality<int>().equals(encoded, header), true);
    final decoded = brotli.decode(encoded);
    expect(const ListEquality<int>().equals(dataBytes, decoded), true);
  });

  test('Test Simple Brotli Encode/Decode', () {
    final data = 'MyDart';
    final expected = [139, 2, 128, 77, 121, 68, 97, 114, 116, 3];
    final dataBytes = utf8.encode(data);
    final codec = BrotliCodec();
    final encoded = codec.encode(dataBytes);
    expect(const ListEquality<int>().equals(encoded, expected), true);
    final decoded = brotli.decode(encoded);
    expect(const ListEquality<int>().equals(dataBytes, decoded), true);
  });
}