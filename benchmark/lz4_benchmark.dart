// Copyright (c) 2020, Seth Berman (Instantiations, Inc). Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:collection/collection.dart';
import 'package:es_compression/lz4.dart';

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

  Lz4EncodeBenchmark(this.data)
      : codec = Lz4Codec(level: -1),
        super('lz4 encode()');

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

  Lz4DecodeBenchmark(this.data)
      : codec = Lz4Codec(level: -1),
        super('lz4 decode()');

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

const tutoneConstant = 8675309;

/// Benchmark: Lz4 Encoding/Decoding of seeded random data.
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
  final data = Lz4Data(Uint8List.fromList(randomBytes));

  Lz4EncodeBenchmark(data).report();
  Lz4DecodeBenchmark(data).report();

  final bytesMatch = const ListEquality<int>().equals(randomBytes, data.bytes);
  exitCode = (bytesMatch == true) ? 0 : -1;
}
