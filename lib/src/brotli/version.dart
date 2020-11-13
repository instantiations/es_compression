// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

/// Helper class to decode the version number returned from the brotli FFI
/// library.
class BrotliVersion {
  /// Encoded version number from brotli.
  final int versionNumber;

  /// Construct a new [BrotliVersion].
  const BrotliVersion(this.versionNumber);

  /// Return the major element of the version.
  int get major => versionNumber >> 24;

  /// Return the minor element of the version.
  int get minor => (versionNumber >> 12) & 0xFFF;

  /// Return the patch element of the version.
  int get patch => versionNumber & 0xFFF;

  /// Return the [String] repr of the [versionNumber].
  @override
  String toString() => '$major.$minor.$patch';
}
