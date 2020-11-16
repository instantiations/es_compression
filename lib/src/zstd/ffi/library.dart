// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import '../../framework/native/library/open_library.dart';
import 'constants.dart';
import 'functions.dart';
import 'types.dart';

/// An [ZstdLibrary] is the gateway to the native Zstd shared library.
///
/// It has a series of mixins for making available constants, types and
/// functions that are described in C header files.
class ZstdLibrary with OpenLibrary, ZstdConstants, ZstdFunctions, ZstdTypes {
  /// Library path the user can define to override normal resolution.
  static String userDefinedLibraryPath;

  /// Singleton instance.
  static final ZstdLibrary _instance = ZstdLibrary._(userDefinedLibraryPath);

  /// Dart native library object.
  DynamicLibrary _libraryImpl;

  /// Zstd Version Number.
  int versionNumber;

  /// Unique id of this library module.
  @override
  String get moduleId => 'zstd';

  /// Return the [ZstdLibrary] singleton library instance.
  factory ZstdLibrary() {
    return _instance;
  }

  /// Internal constructor that opens the native shared library and resolves
  /// all the functions.
  ZstdLibrary._(String libraryPath) {
    _libraryImpl = openLibrary(path: libraryPath);
    resolveFunctions(_libraryImpl);
  }
}
