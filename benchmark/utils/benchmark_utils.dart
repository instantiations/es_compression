import 'dart:math';
import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';

/// Constant used for RNG seed
const tutoneConstant = 8675309;

/// [Emitter] which prints total time in milliseconds, as well as the calculated
/// MB/sec based on the length of the uncompressed data.
class CodecPerformanceEmitter implements ScoreEmitter {
  final int dataLength;

  const CodecPerformanceEmitter(this.dataLength);

  @override
  void emit(String testName, double value) {
    final milliseconds = value / 1000;
    final mbSec = (dataLength / milliseconds) ~/ 1000;
    print('$testName(RunTime): ${milliseconds.round()} ms. $mbSec MB/sec');
  }
}

/// Return generated pseudo-random bytes
List<int> generateRandomBytes(int length) {
  final random = Random(tutoneConstant);
  final list = List<int>.generate(length, (i) => random.nextInt(256));
  return Uint8List.fromList(list);
}

/// Return bytes with a single value
List<int> generateConstantBytes(int length) {
  final list = List<int>.generate(length, (i) => 1);
  return Uint8List.fromList(list);
}

String compressionRatio(int uLength, int cLength) {
  return (uLength / cLength).toStringAsFixed(1) + ':1';
}
