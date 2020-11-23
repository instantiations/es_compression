import 'dart:cli' as cli;
import 'dart:ffi';
import 'dart:isolate' show Isolate;

import 'open_library.dart';
import 'open_library_strategy.dart';

/// Package name used as the root for package uri resolution.
const _espackage = 'es_compression';

/// An [OpenViaPackageRelativeStrategy] will attempt to resolve the shared
/// library via a location based on a package-relative convention.
///
/// **Prebuilt Libraries:** There is a library layout convention used for
/// locating prebuilt shared libraries. This strategy requires a
/// [OpenLibrary.moduleId], which is a [String] identifier used to fully resolve
/// prebuilt library locations on the filesystem.
///
/// **Library layout convention:** The following convention is used for locating
/// prebuilt shared libraries. Every compression library is defined in its own
/// subdirectory of lib/src.
/// For example, the LZ4 implementation is in *lib/src/lz4*. The
/// [OpenLibrary.moduleId] is the basename in this path, in this example *lz4*.
/// There will exist a *blobs* subdirectory of the module or
/// */lib/src/lz4/blobs* in the example. The blobs directory will contain the
/// shared libraries which have the name of the form
/// es$moduleId_c-$os$bitness.$extension.
/// In the case of lz4 on Win64, it is named *eslz4_c-win64.dll*.
class OpenViaPackageRelativeStrategy extends OpenLibraryStrategy {
  /// Return the [String] id of the [OpenViaEnvironmentStrategy].
  @override
  String get strategyId => 'Package-Relative-Strategy';

  /// Return the opened [DynamicLibrary] if the library was resolved via
  /// package relative resolution, [:null:] otherwise.
  @override
  DynamicLibrary openFor(OpenLibrary openLibrary) {
    final moduleId = openLibrary.moduleId;
    final packageLibrary = 'package:$_espackage/$moduleId.dart';
    final packageUri = _resolvePackagedLibraryLocation(packageLibrary);
    final blobs = packageUri?.resolve('src/$moduleId/blobs/');
    final filePath = blobs?.resolve(openLibrary.defaultLibraryFileName);
    return open(filePath?.toFilePath());
  }

  /// Resolve package-relative [packagePath] by converting it to a non-package
  /// relative [Uri].
  Uri _resolvePackagedLibraryLocation(String packagePath) {
    const timeoutSeconds = 5;
    final libraryUri = Uri.parse(packagePath);
    final packageUriFuture = Isolate.resolvePackageUri(libraryUri);
    final packageUri = cli.waitFor(packageUriFuture,
        timeout: const Duration(seconds: timeoutSeconds));
    return packageUri;
  }
}
