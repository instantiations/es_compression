// Copyright (c) 2021, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'filters.dart';

/// The [CodecSink] is the base class for encode/decoder sinks.
///
/// This was modelled after the `_FilterSink` from the *data_transformer.dart*
/// library in the Dart SDK.
///
/// And additional concept was added to request the filter to close since there
/// may be potential native resources to cleanup.
class CodecSink extends ByteConversionSink {
  final CodecFilter _filter;
  final ByteConversionSink _sink;
  bool _closed = false;
  bool _empty = true;

  /// Construct new [CodecSink] which wraps a [ByteConversionSink] with a
  /// specified [CodecFilter] which will handle the algorithm details.
  CodecSink(this._sink, this._filter);

  @override
  void add(List<int> chunk) {
    addSlice(chunk, 0, chunk.length, false);
  }

  @override
  void addSlice(List<int> chunk, int start, int end, bool isLast) {
    if (_closed) return;
    RangeError.checkValidRange(start, end, chunk.length);
    try {
      _empty = false;
      final bufferAndStart =
          _PositionableBuffer.serializableByteData(chunk, start, end);
      _filter.process(bufferAndStart.buffer, bufferAndStart.start,
          end - (start - bufferAndStart.start));
      while (true) {
        final out = _filter.processed(flush: false);
        if (out == null) break;
        _sink.add(out);
      }
    } on Exception {
      _closed = true;
      _filter.close();
      rethrow;
    }

    if (isLast) close();
  }

  @override
  void close() {
    if (_closed) return;
    if (_empty) _filter.process(const [], 0, 0);
    try {
      while (true) {
        final out = _filter.processed(end: true);
        if (out == null) break;
        _sink.add(out);
      }
    } on Exception {
      _closed = true;
      _filter.close();
      rethrow;
    }
    _closed = true;
    _filter.close();
    _sink.close();
  }
}

class _PositionableBuffer {
  List<int> buffer;
  int start;

  // Ensure that the input List can be serialized through a native port.
  // Only Int8List and Uint8List Lists are serialized directly.
  // All other lists are first copied into a Uint8List. This has the added
  // benefit that it is faster to access from the C code as well.
  static _PositionableBuffer serializableByteData(
      List<int> buffer, int start, int end) {
    if (buffer is Uint8List || buffer is Int8List) {
      return _PositionableBuffer(buffer, start);
    }
    final length = end - start;
    final newBuffer = Uint8List(length);
    newBuffer.setRange(0, length, buffer, start);
    return _PositionableBuffer(newBuffer, 0);
  }

  _PositionableBuffer(this.buffer, this.start);
}

/// The [BufferSink] will efficiently collect up the results of codec filtering.
class BufferSink extends ByteConversionSink {
  /// Setup a new bytes builder the does not need to internally buffer since
  /// the wrapping filter will be passing copied data to it.
  final BytesBuilder builder = BytesBuilder(copy: false);

  @override
  void add(List<int> chunk) {
    builder.add(chunk);
  }

  @override
  void addSlice(List<int> chunk, int start, int end, bool isLast) {
    if (chunk is Uint8List) {
      final list = chunk;
      builder.add(Uint8List.view(list.buffer, start, end - start));
    } else {
      builder.add(chunk.sublist(start, end));
    }
  }

  @override
  void close() {}
}
