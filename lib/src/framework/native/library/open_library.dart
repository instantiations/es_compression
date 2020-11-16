// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
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
const _esprefix = 'es';

/// Provides the capability to locate and open native shared libraries.
///
/// There are several mechanisms used to resolve shared libraries.
/// The implementation for each mechanism is defined by subclasses of
/// [OpenLibraryStrategy].
mixin OpenLibrary {
  /// Mixer Responsibility: Return the module id for path resolution.
  String get moduleId;

  /// Ordered list of strategies for resolving and opening shared libraries.
  List<OpenLibraryStrategy> strategies = [];

  /// Open the shared library whose path is resolved either by the supplied
  /// [path] or by the mixer [moduleId].
  ///
  /// Each strategy in [strategies] will be requested to open the shared
  /// library in order.
  DynamicLibrary openLibrary({String path}) {
    _initStrategies(path);
    for (final strategy in strategies) {
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
    } else {
      throw Exception('Unsupported platform!');
    }

    final result = os + bitness;
    return '$_esprefix$moduleId-$result.$extension';
  }

  /// Initialize the strategies used to open shared libraries.
  void _initStrategies(String userDefinedPath) {
    strategies.clear();
    if (userDefinedPath != null) {
      strategies.add(OpenViaOsResolutionStrategy(userDefinedPath));
    }
    strategies
      ..add(OpenViaEnvVarStrategy())
      ..add(OpenViaPackageRelativeStrategy())
      ..add(OpenViaScriptRelativeStrategy())
      ..add(OpenViaOsResolutionStrategy(defaultLibraryFileName));
  }
}
