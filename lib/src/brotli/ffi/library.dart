// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import '../../framework/native/openlibrary.dart';

import 'constants.dart';
import 'functions.dart';
import 'types.dart';

/// An [BrotliLibrary] is the gateway to the native Brotli shared library.
///
/// It has a series of mixins for making available constants, types and
/// functions that are described in C header files.
class BrotliLibrary
    with OpenLibrary, BrotliConstants, BrotliFunctions, BrotliTypes {
  static final BrotliLibrary _instance = BrotliLibrary._();

  DynamicLibrary _libraryImpl;

  @override
  String get moduleId => 'brotli';

  /// Return the [BrotliLibrary] singleton library instance.
  factory BrotliLibrary() {
    return _instance;
  }

  BrotliLibrary._() {
    _libraryImpl = openLibrary();
    resolveFunctions(_libraryImpl);
  }
}
