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
    final seconds = milliseconds / 1000;
    final bytesPerSecond = seconds > 0 ? dataLength / seconds : 0;
    final megabytesPerSecond = bytesPerSecond / 1048576;
    print('$testName(RunTime): ${milliseconds.round()} '
        'ms. ${megabytesPerSecond.toStringAsFixed(2)} MB/sec');
  }
}

/// Return generated pseudo-random bytes
List<int> generateRandomBytes(int length) {
  final random = Random(tutoneConstant);
  final list = Uint8List(length);
  for (var i = 0; i < length; i++) {
    list[i] = random.nextInt(256);
  }
  return list;
}

/// Return bytes with a single value
List<int> generateConstantBytes(int length) {
  final list = Uint8List(length);
  list.fillRange(0, length, 1);
  return list;
}

String compressionRatio(int uLength, int cLength) {
  return '${(uLength / cLength).toStringAsFixed(1)}:1';
}
