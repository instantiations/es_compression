import 'package:test/test.dart';

import '../example/brotli_example.dart' as brotli_example;
import '../example/lz4_example.dart' as lz4_example;
import '../example/rle_example.dart' as rle_example;
import '../example/zstd_example.dart' as zstd_example;

/// Test that examples are in working order
void main() {
  test('Test Brotli Example', () {
    expect(brotli_example.main(), completion(equals(0)));
  });
  test('Test Lz4 Example', () {
    expect(lz4_example.main(), completion(equals(0)));
  });
  test('Test Rle Example', () {
    expect(rle_example.main(), completion(equals(0)));
  });
  test('Test Zstd Example', () {
    expect(zstd_example.main(), completion(equals(0)));
  });
}
