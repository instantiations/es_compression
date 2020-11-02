import 'package:test/test.dart';

import '../benchmark/brotli_benchmark.dart' as brotli_benchmark;
import '../benchmark/gzip_benchmark.dart' as gzip_benchmark;
import '../benchmark/lz4_benchmark.dart' as lz4_benchmark;
import '../benchmark/zstd_benchmark.dart' as zstd_benchmark;

/// Test that benchmarks are in working order
void main() {
  const dataLength = 1 * 1024 * 1024;

  test('Test Brotli Benchmark', () {
    expect(brotli_benchmark.main(['$dataLength']), completion(equals(0)));
  });
  test('Test GZip Benchmark', () {
    expect(gzip_benchmark.main(['$dataLength']), completion(equals(0)));
  });
  test('Test Lz4 Benchmark', () {
    expect(lz4_benchmark.main(['$dataLength']), completion(equals(0)));
  });
  test('Test Zstd Benchmark', () {
    expect(zstd_benchmark.main(['$dataLength']), completion(equals(0)));
  });
}
