// Copyright (c) 2020, Seth Berman (Instantiations, Inc). Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'sinks.dart';

/// A [CodecConverter] either encodes or decodes incoming data.
class CodecConverter extends Converter<List<int>, List<int>> {
  /// Encode/Decode a [List] of bytes
  @override
  List<int> convert(List<int> bytes) {
    var sink = BufferSink();
    startChunkedConversion(sink)
      ..add(bytes)
      ..close();
    return sink.builder.takeBytes();
  }
}
