import 'dart:ffi';
import 'dart:io';

import 'open_library.dart';

import 'open_library_strategy.dart';

/// An [OpenViaOsResolutionStrategy] will attempt to resolve the shared
/// library using the default rules of the operating system.
class OpenViaOsResolutionStrategy extends OpenLibraryStrategy {
  /// String path to open.
  final String path;

  /// Construct an instance of this strategy with the [path] to open.
  OpenViaOsResolutionStrategy(this.path) : super();

  /// Return the [String] id of the [OpenViaOsResolutionStrategy].
  @override
  String get strategyId => 'Os-Resolution-Strategy';

  /// Return [:true:] if the library was resolved via the os shared library
  /// looking rules and successfully opened, [:false:] otherwise.
  @override
  DynamicLibrary openFor(OpenLibrary openLibrary) {
    if (Platform.isIOS) return DynamicLibrary.process();
    return open(path);
  }
}
