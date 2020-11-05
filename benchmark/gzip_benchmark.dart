// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:collection/collection.dart';
import 'package:es_compression/framework.dart';

import 'utils/benchmark_utils.dart';

/// An [GZipEncodeBenchmark] calls [GZipCodec.encode] on the incoming data
/// supplied by [GZipData].
///
/// [warmup] is used to store of the encoded result.
/// [teardown] is used to reassign [GZipData.bytes] with the result from this
/// codec.
class GZipEncodeBenchmark extends BenchmarkBase {
  final GZipData data;
  final GZipCodec codec;
  List<int> encoded;

  GZipEncodeBenchmark(this.data,
      {ScoreEmitter emitter = const PrintEmitter(),
      int inputBufferLength = CodecBufferHolder.autoLength,
      int outputBufferLength = CodecBufferHolder.autoLength})
      : codec = GZipCodec(level: -1),
        super('gzip encode()', emitter: emitter);

  @override
  void warmup() {
    encoded = codec.encode(data.bytes);
  }

  @override
  void exercise() {
    codec.encode(data.bytes);
  }

  @override
  void teardown() {
    data.bytes = encoded;
  }
}

/// An [GZipDecodeBenchmark] calls [GZipCodec.decode] on the incoming data
/// supplied by [GZipData].
///
/// [warmup] is used to store of the decoded result.
/// [teardown] is used to reassign [GZipData.bytes] with the result from this
/// codec.
class GZipDecodeBenchmark extends BenchmarkBase {
  final GZipData data;
  final GZipCodec codec;
  List<int> decoded;

  GZipDecodeBenchmark(this.data,
      {ScoreEmitter emitter = const PrintEmitter(),
      int inputBufferLength = CodecBufferHolder.autoLength,
      int outputBufferLength = CodecBufferHolder.autoLength})
      : codec = GZipCodec(level: -1),
        super('gzip decode()', emitter: emitter);

  @override
  void warmup() {
    decoded = codec.decode(data.bytes);
  }

  @override
  void exercise() {
    codec.decode(data.bytes);
  }

  @override
  void teardown() {
    data.bytes = decoded;
  }
}

/// Small single-slot container class to flow between benchmarks as data is
/// transformed.
class GZipData {
  List<int> bytes;

  GZipData(this.bytes);
}

/// Benchmark: GZip Encoding/Decoding of seeded random data.
///
/// Encoding/Decoding must actually work for the benchmark to be useful.
/// This means the final decoded bytes should match the original input.
/// Verify this and report success (0) if good, failure (-1) if the bytes
/// don't match.
Future<int> main(List<String> arguments) async {
  final dataLength =
      arguments.isEmpty ? 50 * 1024 * 1024 : int.parse(arguments.first);
  exitCode = await _runGZipBenchmark(dataLength);
  return exitCode;
}

/// GZip Benchmark which answers 0 on success, -1 on error
Future<int> _runGZipBenchmark(int dataLength) async {
  return Future(() {
    print('generating $dataLength bytes of random data');
    final bytes = generateRandomBytes(dataLength);
    final emitter = CodecPerformanceEmitter(bytes.length);

    print('GZip encode/decode ${bytes.length} bytes of random data.');
    var data = GZipData(bytes);
    GZipEncodeBenchmark(data, emitter: emitter).report();
    print('compression ratio:'
        '${compressionRatio(bytes.length, data.bytes.length)}');
    GZipDecodeBenchmark(data, emitter: emitter).report();
    var bytesMatch = const ListEquality<int>().equals(bytes, data.bytes);
    if (bytesMatch != true) return -1;

    print('');
    print('generating ${bytes.length} bytes of constant data');
    bytes.fillRange(0, bytes.length, 1);

    print('GZip encode/decode ${bytes.length} bytes of constant data.');
    data = GZipData(bytes);
    GZipEncodeBenchmark(data, emitter: emitter).report();
    print('compression ratio: '
        '${compressionRatio(bytes.length, data.bytes.length)}');
    GZipDecodeBenchmark(data, emitter: emitter).report();
    bytesMatch = const ListEquality<int>().equals(bytes, data.bytes);
    return (bytesMatch != true) ? -1 : 0;
  });
}
