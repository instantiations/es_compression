// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:collection/collection.dart';
import 'package:es_compression/brotli.dart';
import 'package:es_compression/framework.dart';

import 'utils/benchmark_utils.dart';

/// An [BrotliEncodeBenchmark] calls [BrotliCodec.encode] on the incoming data
/// supplied by [BrotliData].
///
/// [warmup] is used to store of the encoded result.
/// [teardown] is used to reassign [BrotliData.bytes] with the result from this
/// codec.
class BrotliEncodeBenchmark extends BenchmarkBase {
  final BrotliData data;
  final BrotliCodec codec;
  List<int> encoded;

  BrotliEncodeBenchmark(this.data,
      {ScoreEmitter emitter = const PrintEmitter(),
      int inputBufferLength = CodecBufferHolder.autoLength,
      int outputBufferLength = CodecBufferHolder.autoLength})
      : codec = BrotliCodec(
            level: 0,
            inputBufferLength: inputBufferLength,
            outputBufferLength: outputBufferLength),
        super('brotli encode()', emitter: emitter);

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

/// An [BrotliDecodeBenchmark] calls [BrotliCodec.decode] on the incoming data
/// supplied by [BrotliData].
///
/// [warmup] is used to store of the decoded result.
/// [teardown] is used to reassign [BrotliData.bytes] with the result from this
/// codec.
class BrotliDecodeBenchmark extends BenchmarkBase {
  final BrotliData data;
  final BrotliCodec codec;
  List<int> decoded;

  BrotliDecodeBenchmark(this.data,
      {ScoreEmitter emitter = const PrintEmitter(),
      int inputBufferLength = CodecBufferHolder.autoLength,
      int outputBufferLength = CodecBufferHolder.autoLength})
      : codec = BrotliCodec(
            level: 0,
            inputBufferLength: inputBufferLength,
            outputBufferLength: outputBufferLength),
        super('brotli decode()', emitter: emitter);

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
class BrotliData {
  List<int> bytes;

  BrotliData(this.bytes);
}

/// Benchmark: Brotli Encoding/Decoding of seeded random data.
///
/// Encoding/Decoding must actually work for the benchmark to be useful.
/// This means the final decoded bytes should match the original input.
/// Verify this and report success (0) if good, failure (-1) if the bytes
/// don't match.
Future<int> main(List<String> arguments) async {
  final dataLength =
      arguments.isEmpty ? 50 * 1024 * 1024 : int.parse(arguments.first);
  exitCode = await _runBrotliBenchmark(dataLength);
  return exitCode;
}

/// Brotli Benchmark which answers 0 on success, -1 on error
Future<int> _runBrotliBenchmark(int dataLength) async {
  return Future(() {
    print('generating $dataLength bytes of random data');
    final bytes = generateRandomBytes(dataLength);
    final emitter = CodecPerformanceEmitter(bytes.length);

    print('Brotli encode/decode ${bytes.length} bytes of random data.');
    var data = BrotliData(bytes);
    BrotliEncodeBenchmark(data, emitter: emitter).report();
    print('compression ratio: '
        '${compressionRatio(bytes.length, data.bytes.length)}');
    BrotliDecodeBenchmark(data, emitter: emitter).report();
    var bytesMatch = const ListEquality<int>().equals(bytes, data.bytes);
    if (bytesMatch != true) return -1;

    print('');
    print('generating ${bytes.length} bytes of constant data');
    bytes.fillRange(0, bytes.length, 1);

    print('Brotli encode/decode ${bytes.length} bytes of constant data.');
    data = BrotliData(bytes);
    BrotliEncodeBenchmark(data, emitter: emitter).report();
    print('compression ratio: '
        '${compressionRatio(bytes.length, data.bytes.length)}');
    BrotliDecodeBenchmark(data, emitter: emitter).report();
    bytesMatch = const ListEquality<int>().equals(bytes, data.bytes);
    return (bytesMatch != true) ? -1 : 0;
  });
}
