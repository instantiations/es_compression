// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:collection/collection.dart';
import 'package:es_compression/zstd_io.dart';

/// An [ZstdEncodeBenchmark] calls [ZstdCodec.encode] on the incoming data
/// supplied by [ZstdData].
///
/// [warmup] is used to store of the encoded result.
/// [teardown] is used to reassign [ZstdData.bytes] with the result from this
/// codec.
class ZstdEncodeBenchmark extends BenchmarkBase {
  final ZstdData data;
  final ZstdCodec codec;
  List<int> encoded;

  ZstdEncodeBenchmark(this.data)
      : codec = ZstdCodec(level: -1),
        super('zstd encode()');

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

/// An [ZstdDecodeBenchmark] calls [ZstdCodec.decode] on the incoming data
/// supplied by [ZstdData].
///
/// [warmup] is used to store of the decoded result.
/// [teardown] is used to reassign [ZstdData.bytes] with the result from this
/// codec.
class ZstdDecodeBenchmark extends BenchmarkBase {
  final ZstdData data;
  final ZstdCodec codec;
  List<int> decoded;

  ZstdDecodeBenchmark(this.data)
      : codec = ZstdCodec(level: -1),
        super('zstd decode()');

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
class ZstdData {
  List<int> bytes;

  ZstdData(this.bytes);
}

const tutoneConstant = 8675309;

/// Benchmark: Zstd Encoding/Decoding of seeded random data.
///
/// Encoding/Decoding must actually work for the benchmark to be useful.
/// This means the final decoded bytes should match the original input.
/// Verify this and report success (0) if good, failure (-1) if the bytes
/// don't match.
void main() {
  // Generate 100MB of seeded pseudo-random bytes to encode/decode
  final random = Random(tutoneConstant);
  final randomBytes =
      List<int>.generate(100 * 1024 * 1024, (i) => random.nextInt(256));
  final data = ZstdData(Uint8List.fromList(randomBytes));

  ZstdEncodeBenchmark(data).report();
  ZstdDecodeBenchmark(data).report();

  final bytesMatch = const ListEquality<int>().equals(randomBytes, data.bytes);
  exitCode = (bytesMatch == true) ? 0 : -1;
}
