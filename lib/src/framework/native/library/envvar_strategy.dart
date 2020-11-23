import 'dart:ffi';
import 'dart:io';

import 'open_library.dart';
import 'open_library_strategy.dart';

/// An [OpenViaEnvVarStrategy] will attempt to resolve the shared library
/// via environment variable.
///
/// The user may inject an environment variable of the form
/// [moduleId]_LIBRARY_NAME. For example, if the [moduleId] is lz4, then the
/// name of the env-var is LZ4_LIBRARY_PATH.
///
/// The value of the environment variable may contain either the directory
/// that the shared library can be found in, or a full path to the shared
/// library itself. In the case that a directory is defined, then the filename
/// should be es${moduleId}_${os}${bitness}.${extension}.
///
/// For example on Win64:
/// LZ4_LIBRARY_PATH=C:\MyLibs   (will look for eslz4_win64.dll)
/// or
/// LZ4_LIBRARY_PATH=C:\MyLibs\lz4.dll
class OpenViaEnvVarStrategy extends OpenLibraryStrategy {
  /// Return the [String] id of the [OpenViaEnvVarStrategy].
  @override
  String get strategyId => 'Env-Var-Strategy';

  /// Return the opened [DynamicLibrary] if the library was resolved via
  /// environment variable, [:null:] otherwise.
  @override
  DynamicLibrary openFor(OpenLibrary openLibrary) {
    final path = _envLibraryFilePath(openLibrary);
    return open(path);
  }

  /// Returns the absolute path of the shared library defined by the user-def
  /// library path.
  String _envLibraryFilePath(OpenLibrary openLibrary) {
    final moduleId = openLibrary.moduleId;
    var envPath =
        Platform.environment['${moduleId.toUpperCase()}_LIBRARY_PATH'];
    if (envPath != null) {
      if (FileSystemEntity.typeSync(envPath) ==
          FileSystemEntityType.directory) {
        if (envPath[envPath.length - 1] == Platform.pathSeparator) {
          envPath = envPath.substring(0, envPath.length - 1);
        }
        envPath = '$envPath${Platform.pathSeparator}'
            '${openLibrary.defaultLibraryFileName}';
      }
      envPath =
          (FileSystemEntity.typeSync(envPath) == FileSystemEntityType.file)
              ? File(envPath).absolute.path
              : null;
    }
    return envPath;
  }
}
