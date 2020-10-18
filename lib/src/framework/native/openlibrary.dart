// Copyright (c) 2020, Seth Berman (Instantiations, Inc). Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:cli' as cli;
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate' show Isolate;

/// Its expected that internal libraries are prefixed with es
/// This is also referenced in CMakeLists.txt file in
/// [blob_builder tool](tool/blob_builder/CMakeLists.txt)
const _esprefix = 'es';

/// List of supported platforms.
const Set<String> _supported = {'linux64', 'mac64', 'win64'};

/// Provides the capability to locate and open the native shared libraries
/// according to the layout standards in the package.
///
/// A [moduleId] is the only data that the mixer needs to provide in order to
/// fully resolve the library to use on the filesystem.
///
/// The following standard is in place.
/// Every compression algorithm is in its own subdirectory of lib/src.
/// For example, the LZ4 implementation is in lib/src/lz4. The [moduleId] is the
/// basename in this path, in this example *lz4*.
/// There will exist a blobs subdirectory of the module or
/// /lib/src/$moduleId/blobs in the example.
/// The blobs directory will contain the shared libraries which have the name
/// of the form es$moduleId_c-$os$bitness.$extension.
/// In the case of lz4 on Win64, it is named *eslz4_c-win64.dll*
///
/// The user has the capability to inject an environment variable with either
/// the location of the shared library, or a directory that should contain the
/// shared library with the name using the rules defined above.
mixin OpenLibrary {
  /// Mixer Responsibility: Return the module id for path resolution.
  String get moduleId;

  /// Open the shared library whose path is resolved by the mixer [moduleId].
  DynamicLibrary openLibrary() {
    return DynamicLibrary.open(_libraryFilePath());
  }

  /// Return a [String] describing the shared library path.
  ///
  /// First check if there is an environment variable defined for the module id.
  /// If so, then check if the value represents a valid path and return if it
  /// does.
  /// For example, for the lz4 module, the environment variable would be named
  /// LZ4_LIBRARY_PATH
  ///
  /// Next check for the library within the module package's blob folder.
  /// package:es_compression/lib/src/$moduleId/blobs/<shared library>.
  /// Return the path if that exists.
  ///
  /// Next check the script directory for the shared library sitting next to it
  /// and answer that string path if it exists.
  ///
  /// Finally, just answer the shared library name and use the OS resolution
  /// rules used by [DynamicLibrary.open] to locate it.
  String _libraryFilePath() {
    final envPath = _envLibraryFilePath();
    if (envPath != null) return envPath;

    final libraryName = _libraryFileName();
    final rootLibrary = 'package:es_compression/$moduleId.dart';
    final packageUri =
        cli.waitFor(Isolate.resolvePackageUri(Uri.parse(rootLibrary)));
    final blobs = packageUri?.resolve('src/$moduleId/blobs/');
    final filePath = blobs?.resolve(libraryName);
    if (filePath != null) return filePath.toFilePath();

    final scriptBlobPath =
        '${File.fromUri(Platform.script).parent.path}/$libraryName';
    if (FileSystemEntity.typeSync(scriptBlobPath) !=
        FileSystemEntityType.notFound) return scriptBlobPath;
    return libraryName;
  }

  /// Returns the absolute path of the shared library defined by the user-def
  /// library path.
  ///
  /// The user may inject an environment variable of the form
  /// [moduleId]_LIBRARY_NAME. For example, if the [moduleId] is lz4, then the
  /// name of the env-var is LZ4_LIBRARY_PATH.
  ///
  /// The value of the environment variable may contain either the directory
  /// that the shared library can be found in, or a full path to the shared
  /// library itself. In the case that a directory is defined, then the filename
  /// should be es${moduleId}_${os}${bitness}.${extension}
  ///
  /// For example on Win64:
  /// LZ4_LIBRARY_PATH=C:\MyLibs   (will look for eslz4_win64.dll)
  /// or
  /// LZ4_LIBRARY_PATH=C:\MyLibs\lz4.dll
  String _envLibraryFilePath() {
    var envPath =
        Platform.environment['${moduleId.toUpperCase()}_LIBRARY_PATH'];
    if (envPath != null) {
      if (FileSystemEntity.typeSync(envPath) ==
          FileSystemEntityType.directory) {
        if (envPath[envPath.length - 1] == Platform.pathSeparator) {
          envPath = envPath.substring(0, envPath.length - 1);
        }
        envPath = '$envPath${Platform.pathSeparator}${_libraryFileName()}';
      }
      envPath =
          (FileSystemEntity.typeSync(envPath) == FileSystemEntityType.file)
              ? File(envPath).absolute.path
              : null;
    }
    return envPath;
  }

  /// Computes the library filename for this os and architecture.
  ///
  /// Throws an exception if invoked on an unsupported platform.
  String _libraryFileName() {
    final bitness = sizeOf<IntPtr>() == 4 ? '32' : '64';
    String os, extension;
    if (Platform.isLinux) {
      os = 'linux';
      extension = 'so';
    } else if (Platform.isMacOS) {
      os = 'mac';
      extension = 'so';
    } else if (Platform.isWindows) {
      os = 'win';
      extension = 'dll';
    } else {
      throw Exception('Unsupported platform!');
    }

    final result = os + bitness;
    if (!_supported.contains(result)) {
      throw Exception('Unsupported platform: $result!');
    }

    return '$_esprefix$moduleId-$result.$extension';
  }
}
