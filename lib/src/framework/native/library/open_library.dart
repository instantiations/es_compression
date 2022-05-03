// Copyright (c) 2021, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io';

import 'envvar_strategy.dart';
import 'open_library_strategy.dart';
import 'os_resolution_strategy.dart';
import 'script_relative_strategy.dart';
import 'stubs/package_relative_strategy.dart'
    if (dart.library.cli) 'package_relative_strategy.dart';

/// Its expected that internal libraries are prefixed with es
/// This is also referenced in CMakeLists.txt file in
/// [blob_builder tool](tool/blob_builder/CMakeLists.txt)
const _esPrefix = 'es';
var _startPrefix = '';

/// Provides the capability to locate and open native shared libraries.
///
/// There are several mechanisms used to resolve shared libraries.
/// The implementation for each mechanism is defined by subclasses of
/// [OpenLibraryStrategy].
mixin OpenLibrary {
  /// Mixer Responsibility: Return the module id for path resolution.
  String get moduleId;

  /// Ordered list of strategies for resolving and opening shared libraries.
  final List<OpenLibraryStrategy> _strategies = [];

  /// Open the shared library whose path is resolved either by the supplied
  /// [path] or by the mixer [moduleId].
  ///
  /// If [path] is provided, then it acts as an override to any other lookup
  /// mechanisms.
  ///
  /// Each strategy in [_strategies] will be requested to open the shared
  /// library in order.
  DynamicLibrary? openLibrary({String? path}) {
    _initStrategies(path);
    for (final strategy in _strategies) {
      final library = strategy.openFor(this);
      if (library != null) return library;
    }
    return null;
  }

  /// Computes the library filename for this os and architecture.
  ///
  /// Throws an exception if invoked on an unsupported platform.
  String get defaultLibraryFileName {
    final bitness = sizeOf<IntPtr>() == 4 ? '32' : '64';
    String os, extension;
    if (Platform.isLinux) {
      os = 'linux';
      extension = 'so';
    } else if (Platform.isMacOS) {
      os = 'mac';
      extension = 'dylib';
    } else if (Platform.isWindows) {
      os = 'win';
      extension = 'dll';
    } else if (Platform.isAndroid) {
      os = 'android';
      extension = 'so';
      _startPrefix = 'lib';
    } else if (Platform.isIOS) {
      os = 'ios';
      extension = 'dylib';
    } else {
      throw Exception('Unsupported platform!');
    }

    final result = os + bitness;
    return '$_startPrefix$_esPrefix$moduleId-$result.$extension';
  }

  /// Add the [strategy] to the list of [_strategies].
  void add(OpenLibraryStrategy strategy) => strategy.addTo(_strategies);

  /// Initialize the strategies used to open shared libraries.
  void _initStrategies(String? userDefinedPath) {
    _strategies.clear();
    if (userDefinedPath != null) {
      _strategies.add(OpenViaOsResolutionStrategy(userDefinedPath));
    } else {
      _strategies
        ..add(OpenViaEnvVarStrategy())
        ..add(OpenViaPackageRelativeStrategy())
        ..add(OpenViaScriptRelativeStrategy())
        ..add(OpenViaOsResolutionStrategy(defaultLibraryFileName));
    }
  }
}
