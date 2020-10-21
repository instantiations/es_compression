// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'sinks.dart';

/// A [CodecConverter] either encodes or decodes incoming data.
class CodecConverter extends Converter<List<int>, List<int>> {
  /// Encode/Decode a [List] of bytes.
  ///
  /// Attempt one-shot all in-memory conversion first.
  /// If this attempt fails (since it may not be supported), then perform
  /// chunked conversion.
  @override
  List<int> convert(List<int> bytes) {
    var sink = BufferSink();
    if (performOneShotConversion(sink, bytes) == false) {
      startChunkedConversion(sink)
        ..add(bytes)
        ..close();
    }
    return sink.builder.takeBytes();
  }

  /// Subclasses may override to perform a one-shot optimized conversion of
  /// [bytes] to the [sink].
  ///
  /// Return [:false:] if one-shot is not to be (or could not be) performed,
  /// otherwise answer [:true:]
  bool performOneShotConversion(Sink<List<int>> sink, List<int> bytes) {
    return false;
  }

  /// Ensure a conversion to [ByteConversionSink] which provides an interface
  /// for converters to efficiently transmit byte data.
  ByteConversionSink asByteSink(Sink<List<int>> sink) {
    ByteConversionSink byteSink;
    if (sink is! ByteConversionSink) {
      byteSink = ByteConversionSink.from(sink);
    } else {
      byteSink = sink as ByteConversionSink;
    }
    return byteSink;
  }
}
