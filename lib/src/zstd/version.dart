// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

/// Helper class to decode the version number returned from the zstd FFI
/// library.
class ZstdVersion {
  /// Encoded version number from zstd.
  final int versionNumber;

  /// Construct a new [ZstdVersion].
  const ZstdVersion(this.versionNumber);

  /// Return the major element of the version.
  int get major => versionNumber ~/ (100 * 100);

  /// Return the minor element of the version.
  int get minor => (versionNumber ~/ 100) - 100;

  /// Return the patch element of the version.
  int get patch => versionNumber - (major * (100 * 100)) - (minor * 100);

  /// Return the [String] repr of the [versionNumber].
  @override
  String toString() => '$major.$minor.$patch';
}
