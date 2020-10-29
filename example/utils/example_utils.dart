import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';

const tutoneConstant = 8675309;

/// Return a [List] of [length] random bytes
List<int> generateRandomBytes(int length) {
  final random = Random(tutoneConstant);
  final list = Uint8List(length);
  for (var i = 0; i < length; i++) {
    list[i] = random.nextInt(256);
  }
  return list;
}

/// Verify elements match in [list1] and [list2]
bool verifyEquality(List<int> list1, List<int> list2, {String header = ''}) {
  final bytesMatch = const ListEquality<int>().equals(list1, list2);
  (bytesMatch == true)
      ? print('$header: bytes match!')
      : print('$header: bytes do not match!');
  return bytesMatch;
}

/// Split [list] into [chunkCount] parts.
/// Any remainder will be added to the final bucket.
List<List<int>> splitIntoChunks(List<int> list, int chunkCount) {
  var chunks = <List<int>>[];
  var perPart = list.length ~/ chunkCount;
  var leftOver = list.length.remainder(chunkCount) as int;
  for (var i = 0, j = 0; i < chunkCount; i++, j += perPart) {
    chunks.add(list.sublist(
        j, i + 1 == chunkCount ? j + perPart + leftOver : j + perPart));
  }
  return chunks;
}
