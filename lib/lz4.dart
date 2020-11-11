// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

/// Lz4 encoder and decoder using a fast FFI-based implementation.
///
/// To use this library in your code:
/// ```
/// import 'package:es_compression/lz4.dart';
/// ```
library lz4;

export 'src/lz4/codec.dart';
export 'src/lz4/decoder.dart';
export 'src/lz4/encoder.dart';
export 'src/lz4/options.dart';
export 'src/lz4/version.dart';
