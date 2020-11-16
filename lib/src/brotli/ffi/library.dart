// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import '../../framework/native/library/open_library.dart';
import 'constants.dart';
import 'functions.dart';
import 'types.dart';

/// An [BrotliLibrary] is the gateway to the native Brotli shared library.
///
/// It has a series of mixins for making available constants, types and
/// functions that are described in C header files.
class BrotliLibrary
    with OpenLibrary, BrotliConstants, BrotliFunctions, BrotliTypes {
  /// Library path the user can define to override normal resolution.
  static String _userDefinedLibraryPath;

  /// Return the library path defined by the user.
  static String get userDefinedLibraryPath => _userDefinedLibraryPath;

  /// Set the library [path] defined by the user.
  ///
  /// Throw a [StateError] if this library has already been initialized.
  static set userDefinedLibraryPath(String path) {
    if (_initialized == true) {
      throw StateError('BrotliLibrary already initialized.');
    }
    _userDefinedLibraryPath = path;
  }

  /// Singleton instance.
  static final BrotliLibrary _instance =
      BrotliLibrary._(_userDefinedLibraryPath);

  /// Tracks library init state.
  ///
  /// Set to [:true:] if this library is opened and all functions are resolved.
  static bool _initialized = false;

  /// Dart native library object.
  DynamicLibrary _libraryImpl;

  /// Unique id of this library module.
  @override
  String get moduleId => 'brotli';

  /// Return the [BrotliLibrary] singleton library instance.
  factory BrotliLibrary() {
    return _instance;
  }

  /// Internal constructor that opens the native shared library and resolves
  /// all the functions.
  BrotliLibrary._(String libraryPath) {
    _libraryImpl = openLibrary(path: libraryPath);
    resolveFunctions(_libraryImpl);
    _initialized = true;
  }
}
