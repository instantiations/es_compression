// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

/// Opaque Struct: *ZSTD_CStream*
/// File: *zstd.h*
class ZstdCStream extends Struct {}

/// Opaque Struct: *ZSTD_DStream*
/// File: *zstd.h*
class ZstdDStream extends Struct {}

/// Struct: *ZSTD_inBuffer_s
/// File: *zstd.h*
class ZstdInBuffer extends Struct {
  /// Start of input buffer.
  Pointer<Void> src;

  /// Size of input buffer
  @IntPtr()
  int size;

  /// Position where reading stopped.
  /// Will be updated.
  /// Necessarily 0 <= pos <= size
  @IntPtr()
  int pos;
}

/// Struct: *ZSTD_outBuffer_s
/// File: *zstd.h*
class ZstdOutBuffer extends Struct {
  /// Start of output buffer.
  Pointer<Void> dst;

  /// Size of output buffer
  @IntPtr()
  int size;

  /// Position where writing stopped.
  /// Will be updated.
  /// Necessarily 0 <= pos <= size
  @IntPtr()
  int pos;
}

/// Contains refs to required types (structs...) referenced by the
/// following header files:
/// *zstd.h*
mixin ZstdTypes {}
