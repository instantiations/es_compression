import 'package:test/test.dart';

import '../example/brotli_example.dart';
import '../example/lz4_example.dart';
import '../example/rle_example.dart';
import '../example/zstd_example.dart';

/// Test that examples are in working order
void main() {
  test('Test Brotli Example', () {
    expect(runBrotliExample(), completion(equals(0)));
  });
  test('Test Lz4 Example', () {
    expect(runLz4Example(), completion(equals(0)));
  });
  test('Test Rle Example', () {
    expect(runRleExample(), completion(equals(0)));
  });
  test('Test Zstd Example', () {
    expect(runZstdExample(), completion(equals(0)));
  });
}
