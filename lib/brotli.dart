// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

/// Brotli encoder and decoder using a fast FFI-based implementation.
///
/// To use this library in your code:
/// ```
/// import 'package:es_compression/brotli.dart';
/// ```
library brotli;

export 'src/brotli/codec.dart';
export 'src/brotli/decoder.dart';
export 'src/brotli/encoder.dart';
export 'src/brotli/options.dart';
export 'src/brotli/version.dart';
