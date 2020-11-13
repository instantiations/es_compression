// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

/// Zstd (Zstandard) encoder and decoder using a fast FFI-based implementation.
///
/// To use this library in your code:
/// ```
/// import 'package:es_compression/zstd.dart';
/// ```
library zstd;

export 'src/zstd/codec.dart';
export 'src/zstd/decoder.dart';
export 'src/zstd/encoder.dart';
export 'src/zstd/options.dart';
export 'src/zstd/version.dart';
