// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

/// Compression framework for non-web contexts.
/// This is required for FFI-based implementations.
///
/// To use this library in your code:
/// ```
/// import 'package:es_compression/framework_io.dart';
/// ```
library framework_io;

export 'framework.dart';
export 'src/framework/dart/buffers.dart'
    if (dart.library.io) 'src/framework/native/buffers.dart';
