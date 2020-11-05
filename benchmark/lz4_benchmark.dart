// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:collection/collection.dart';
import 'package:es_compression/framework.dart';
import 'package:es_compression/lz4.dart';

import 'utils/benchmark_utils.dart';

/// An [Lz4EncodeBenchmark] calls [Lz4Codec.encode] on the incoming data
/// supplied by [Lz4Data].
///
/// [warmup] is used to store of the encoded result.
/// [teardown] is used to reassign [Lz4Data.bytes] with the result from this
/// codec.
class Lz4EncodeBenchmark extends BenchmarkBase {
  final Lz4Data data;
  final Lz4Codec codec;
  List<int> encoded;

  Lz4EncodeBenchmark(this.data,
      {ScoreEmitter emitter = const PrintEmitter(),
      int inputBufferLength = CodecBufferHolder.autoLength,
      int outputBufferLength = CodecBufferHolder.autoLength})
      : codec = Lz4Codec(
            level: -1,
            inputBufferLength: inputBufferLength,
            outputBufferLength: outputBufferLength),
        super('lz4 encode()', emitter: emitter);

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

/// An [Lz4DecodeBenchmark] calls [Lz4Codec.decode] on the incoming data
/// supplied by [Lz4Data].
///
/// [warmup] is used to store of the decoded result.
/// [teardown] is used to reassign [Lz4Data.bytes] with the result from this
/// codec.
class Lz4DecodeBenchmark extends BenchmarkBase {
  final Lz4Data data;
  final Lz4Codec codec;
  List<int> decoded;

  Lz4DecodeBenchmark(this.data,
      {ScoreEmitter emitter = const PrintEmitter(),
      int inputBufferLength = CodecBufferHolder.autoLength,
      int outputBufferLength = CodecBufferHolder.autoLength})
      : codec = Lz4Codec(
            level: -1,
            inputBufferLength: inputBufferLength,
            outputBufferLength: outputBufferLength),
        super('lz4 decode()', emitter: emitter);

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
class Lz4Data {
  List<int> bytes;

  Lz4Data(this.bytes);
}

/// Benchmark: Lz4 Encoding/Decoding of seeded random data.
///
/// Encoding/Decoding must actually work for the benchmark to be useful.
/// This means the final decoded bytes should match the original input.
/// Verify this and report success (0) if good, failure (-1) if the bytes
/// don't match.
Future<int> main(List<String> arguments) async {
  final dataLength =
      arguments.isEmpty ? 50 * 1024 * 1024 : int.parse(arguments.first);
  exitCode = await _runLz4Benchmark(dataLength);
  return exitCode;
}

/// Lz4 Benchmark which answers 0 on success, -1 on error
Future<int> _runLz4Benchmark(int dataLength) async {
  return Future(() {
    print('generating $dataLength bytes of random data');
    final bytes = generateRandomBytes(dataLength);
    final emitter = CodecPerformanceEmitter(bytes.length);

    print('Lz4 encode/decode ${bytes.length} bytes of random data.');
    var data = Lz4Data(bytes);
    Lz4EncodeBenchmark(data, emitter: emitter).report();
    print('compression ratio: '
        '${compressionRatio(bytes.length, data.bytes.length)}');
    Lz4DecodeBenchmark(data, emitter: emitter).report();
    var bytesMatch = const ListEquality<int>().equals(bytes, data.bytes);
    if (bytesMatch != true) return -1;

    print('');
    print('generating ${bytes.length} bytes of constant data');
    bytes.fillRange(0, bytes.length, 1);

    print('Lz4 encode/decode ${bytes.length} bytes of constant data.');
    data = Lz4Data(bytes);
    Lz4EncodeBenchmark(data, emitter: emitter).report();
    print('compression ratio: '
        '${compressionRatio(bytes.length, data.bytes.length)}');
    Lz4DecodeBenchmark(data, emitter: emitter).report();
    bytesMatch = const ListEquality<int>().equals(bytes, data.bytes);
    return (bytesMatch != true) ? -1 : 0;
  });
}
