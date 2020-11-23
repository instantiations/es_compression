import 'dart:ffi';
import 'dart:io';

import 'open_library.dart';
import 'open_library_strategy.dart';

/// An [OpenViaScriptRelativeStrategy] will attempt to resolve the shared
/// library via the directory location that the current script lives in.
///
/// **Script Directory:** Check the directory that the script is running in
/// and detect if there is a shared library file whose name conforms to the
/// convention described above.
class OpenViaScriptRelativeStrategy extends OpenLibraryStrategy {
  /// Return the [String] id of the [OpenViaScriptRelativeStrategy].
  @override
  String get strategyId => 'Script-Relative-Strategy';

  /// Return the opened [DynamicLibrary] if the library was resolved via
  /// script relative resolution, [:null:] otherwise.
  @override
  DynamicLibrary? openFor(OpenLibrary openLibrary) {
    final libraryName = openLibrary.defaultLibraryFileName;
    final scriptBlobPath =
        '${File.fromUri(Platform.script).parent.path}/$libraryName';
    final scriptType = FileSystemEntity.typeSync(scriptBlobPath);
    return scriptType != FileSystemEntityType.notFound
        ? open(scriptBlobPath)
        : null;
  }
}
