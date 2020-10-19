// Copyright (c) 2020, Seth Berman (Instantiations, Inc). Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import '../../framework/native/openlibrary.dart';

import 'constants.dart';
import 'functions.dart';
import 'types.dart';

/// An [ZstdLibrary] is the gateway to the native Zstd shared library.
///
/// It has a series of mixins for making available constants, types and
/// functions that are described in C header files.
class ZstdLibrary with OpenLibrary, ZstdConstants, ZstdFunctions, ZstdTypes {
  static final ZstdLibrary _instance = ZstdLibrary._();

  DynamicLibrary _libraryImpl;

  /// Zstd Version Number
  int versionNumber;

  @override
  String get moduleId => 'zstd';

  /// Return the [ZstdLibrary] singleton library instance.
  factory ZstdLibrary() {
    return _instance;
  }

  ZstdLibrary._() {
    _libraryImpl = openLibrary();
    resolveFunctions(_libraryImpl);
  }
}
