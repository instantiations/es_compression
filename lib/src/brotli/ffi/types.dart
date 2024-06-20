// Copyright (c) 2021, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

/// Opaque Struct: *BrotliDecoderState*
/// File: *decode.h*
final class BrotliDecoderState extends Opaque {}

/// Opaque Struct: *BrotliEncoderState*
/// File: *encode.h*
final class BrotliEncoderState extends Opaque {}

/// Contains refs to required types (structs...) referenced by the
/// following header files:
/// *decode.h*
mixin BrotliTypes {}
