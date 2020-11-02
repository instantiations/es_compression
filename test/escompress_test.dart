import 'dart:io';

import 'package:test/test.dart';

import '../bin/es_compress.dart' as escompress;

/// Test that benchmarks are in working order.
void main() {
  const tempFilename = 'helloDart.dart';
  const tempContents = 'hello dart';
  Directory tempDir;
  String inputFile;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('es_');
    File('${tempDir.path}/$tempFilename').writeAsStringSync(tempContents);
    inputFile = '${tempDir.path}${Platform.pathSeparator}$tempFilename';
  });

  tearDownAll(() {
    tempDir.delete(recursive: true);
  });

  test('Test Help', () {
    expect(escompress.main(['-h']), completion(equals(0)));
    expect(escompress.main(['--help']), completion(equals(0)));
  });

  test('Test Encode/Decode Brotli', () async {
    const algo = 'brotli';
    await _verifyEncodeDecodeImplicitAlgo(inputFile, algo);
    await _verifyEncodeDecodeExplicitAlgo(inputFile, algo);
  });

  test('Test Encode/Decode GZip', () async {
    const algo = 'gzip';
    await _verifyEncodeDecodeImplicitAlgo(inputFile, algo);
    await _verifyEncodeDecodeExplicitAlgo(inputFile, algo);
  });

  test('Test Encode/Decode Lz4', () async {
    const algo = 'lz4';
    await _verifyEncodeDecodeImplicitAlgo(inputFile, algo);
    await _verifyEncodeDecodeExplicitAlgo(inputFile, algo);
  });

  test('Test Encode/Decode Zstd', () async {
    const algo = 'zstd';
    await _verifyEncodeDecodeImplicitAlgo(inputFile, algo);
    await _verifyEncodeDecodeExplicitAlgo(inputFile, algo);
  });
}

/// Perform an encode/decode having the program guess the algorithm and context
/// based on the filename
void _verifyEncodeDecodeImplicitAlgo(String inputFile, String algo) async {
  final outputFile = '$inputFile.$algo';
  final compressed = await escompress.main(['-i$inputFile', '-o$outputFile']);
  expect(compressed, 0);
  final decompressed =
      await escompress.main(['-i$outputFile', '-o$inputFile.$algo.decoded']);
  expect(decompressed, 0);
  expect(File(inputFile).readAsBytesSync(),
      File('$inputFile.$algo.decoded').readAsBytesSync());
}

/// Perform an encode/decode having providing the algorithm and context
/// from the command line
void _verifyEncodeDecodeExplicitAlgo(String inputFile, String algo) async {
  final outputFile = '$inputFile.$algo';
  final compressed =
      await escompress.main(['-e', '-a$algo', '-i$inputFile', '-o$outputFile']);
  expect(compressed, 0);
  final decompressed = await escompress
      .main(['-d', '-a$algo', '-i$outputFile', '-o$inputFile.$algo.decoded']);
  expect(decompressed, 0);
  expect(File(inputFile).readAsBytesSync(),
      File('$inputFile.$algo.decoded').readAsBytesSync());
}
