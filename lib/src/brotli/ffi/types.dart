// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

/// Opaque Struct: *BrotliDecoderState*
/// File: *decode.h*
class BrotliDecoderState extends Struct {}

/// Opaque Struct: *BrotliEncoderState*
/// File: *encode.h*
class BrotliEncoderState extends Struct {}

/// Contains refs to required types (structs...) referenced by the
/// following header files:
/// *decode.h*
mixin BrotliTypes {}
