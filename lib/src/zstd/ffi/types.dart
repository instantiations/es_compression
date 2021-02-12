// Copyright (c) 2021, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

/// Opaque Struct: *ZSTD_CStream*
/// File: *zstd.h*
class ZstdCStream extends Opaque {}

/// Opaque Struct: *ZSTD_DStream*
/// File: *zstd.h*
class ZstdDStream extends Opaque {}

/// Struct: *ZSTD_inBuffer_s
/// File: *zstd.h*
class ZstdInBuffer extends Struct {
  /// Start of input buffer.
  external Pointer<Void> src;

  /// Size of input buffer
  @IntPtr()
  external int size;

  /// Position where reading stopped.
  /// Will be updated.
  /// Necessarily 0 <= pos <= size
  @IntPtr()
  external int pos;
}

/// Struct: *ZSTD_outBuffer_s
/// File: *zstd.h*
class ZstdOutBuffer extends Struct {
  /// Start of output buffer.
  external Pointer<Void> dst;

  /// Size of output buffer
  @IntPtr()
  external int size;

  /// Position where writing stopped.
  /// Will be updated.
  /// Necessarily 0 <= pos <= size
  @IntPtr()
  external int pos;
}

/// Contains refs to required types (structs...) referenced by the
/// following header files:
/// *zstd.h*
mixin ZstdTypes {}
