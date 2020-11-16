import 'dart:ffi';

import '../open_library.dart';
import '../open_library_strategy.dart';

/// Placeholder for [OpenViaPackageRelativeStrategy].
///
/// The purpose of this is to be a placeholder for build
/// configurations that do not support `dart:cli`.
class OpenViaPackageRelativeStrategy extends OpenLibraryStrategy {
  /// Return the [String] id of the [OpenViaPackageRelativeStrategy].
  @override
  String get strategyId => 'Package-Relative-Strategy';

  /// Return [:null:].
  @override
  DynamicLibrary openFor(OpenLibrary openLibrary) {
    return null;
  }
}
