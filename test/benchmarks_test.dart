import 'package:test/test.dart';

import '../benchmark/brotli_benchmark.dart';
import '../benchmark/gzip_benchmark.dart';
import '../benchmark/lz4_benchmark.dart';
import '../benchmark/zstd_benchmark.dart';

/// Test that benchmarks are in working order
void main() {
  const dataLength = 1 * 1024 * 1024;

  test('Test Brotli Benchmark', () {
    expect(runBrotliBenchmark(dataLength), completion(equals(0)));
  });
  test('Test GZip Benchmark', () {
    expect(runGZipBenchmark(dataLength), completion(equals(0)));
  });
  test('Test Lz4 Benchmark', () {
    expect(runLz4Benchmark(dataLength), completion(equals(0)));
  });
  test('Test Zstd Benchmark', () {
    expect(runZstdBenchmark(dataLength), completion(equals(0)));
  });
}
