// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
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

/// Provides the capability to locate and open native shared libraries
/// according to the layout standards in the package.
///
/// There are several mechanisms used to locate the shared libraries.
///
/// **Prebuilt Libraries:** There is a library layout convention used for
/// locating prebuilt shared libraries. This mixin requires a [moduleId], which
/// is a [String] identifier used to fully resolve prebuilt library locations on
/// the filesystem.
///
/// *Library layout convention:* The following convention is used for locating
/// prebuilt shared libraries. Every compression library is defined in its own
/// subdirectory of lib/src.
/// For example, the LZ4 implementation is in *lib/src/lz4*. The [moduleId] is
/// the basename in this path, in this example *lz4*. There will exist a *blobs*
/// subdirectory of the module or */lib/src/lz4/blobs* in the example.
/// The blobs directory will contain the shared libraries which have the name
/// of the form es$moduleId_c-$os$bitness.$extension.
/// In the case of lz4 on Win64, it is named *eslz4_c-win64.dll*.
///
/// **Environment Variable:** The user can also inject an environment variable
/// that defines the location of the shared library, or a directory that
/// contains the shared library with the name using the convention described
/// above. This is done by providing [moduleId]_LIBRARY_NAME envvar with the
/// path to the shared library. The [moduleId] should be uppercase.
/// For example, lz4 would look for the envvar *LZ4_LIBRARY_NAME*.
///
/// **[openLibrary] path argument:** The [openLibrary] method accepts a *path*
/// arguments that is expected to be the location of the shared library.
/// If provided, all other shared library resolution procedures will be
/// skipped. The included implementation libraries often pass these in via
/// static variables the user can set:
/// - [BrotliLibrary.userDefinedLibraryPath]
/// - [Lz4Library.userDefinedLibraryPath]
/// - [ZstdLibrary.userDefinedLibraryPath]
///
/// **Script Directory:** Check the directory that the script is running in
/// and detect if there is a shared library file whose name conforms to the
/// convention described above.
///
/// **Lookup Resolution:** As a last attempt to resolve, the name of the shared
/// library (named according to the convention above) is passed directly to the
/// [DynamicLibrary.open] function to be attempt resolution according the rules
/// of the operating system.
mixin OpenLibrary {
  /// Mixer Responsibility: Return the module id for path resolution.
  String get moduleId;

  /// Open the shared library whose path is resolved either by the supplied
  /// [path] or by the mixer [moduleId].
  ///
  /// IOS Platform just assumes the process is resolvable by global symbols.
  DynamicLibrary openLibrary({String path}) {
    return Platform.isIOS
        ? DynamicLibrary.process()
        : DynamicLibrary.open(path ?? _libraryFilePath());
  }

  /// Return a [String] describing the shared library path.
  ///
  /// First check if there is an environment variable defined for the module id.
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
    final packageLibrary = 'package:es_compression/$moduleId.dart';
    final packageUri = _resolvePackagedLibraryLocation(packageLibrary);
    final blobs = packageUri?.resolve('src/$moduleId/blobs/');
    final filePath = blobs?.resolve(libraryName);
    if (filePath != null) return filePath.toFilePath();

    final scriptBlobPath =
        '${File.fromUri(Platform.script).parent.path}/$libraryName';
    if (FileSystemEntity.typeSync(scriptBlobPath) !=
        FileSystemEntityType.notFound) return scriptBlobPath;
    return libraryName;
  }

  /// Resolve package-relative [packagePath] by converting it to a non-package
  /// relative [Uri]
  Uri _resolvePackagedLibraryLocation(String packagePath) {
    const timeoutSeconds = 5;
    final libraryUri = Uri.parse(packagePath);
    final packageUriFuture = Isolate.resolvePackageUri(libraryUri);
    final packageUri = cli.waitFor(packageUriFuture,
        timeout: const Duration(seconds: timeoutSeconds));
    return packageUri;
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
      extension = 'dylib';
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
