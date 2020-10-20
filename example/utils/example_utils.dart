import 'package:collection/collection.dart';

/// Verify elements match in [list1] and [list2]
bool verifyEquality(List<int> list1, List<int> list2) {
  final bytesMatch = const ListEquality<int>().equals(list1, list2);
  (bytesMatch == true) ? print('bytes match!') : print('bytes do not match!');
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
