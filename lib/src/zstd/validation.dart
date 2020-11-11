import '../../zstd.dart';

/// Validate the zstd compression level is within range.
void validateZstdLevel(int level) {
  if (ZstdOption.minLevel > level || ZstdOption.maxLevel < level) {
    throw RangeError.range(level, ZstdOption.minLevel, ZstdOption.maxLevel);
  }
}
