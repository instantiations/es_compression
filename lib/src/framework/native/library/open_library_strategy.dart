import 'dart:ffi';
import 'dart:io';

import 'open_library.dart';

/// An [OpenLibraryStrategy] is the mechanism used to resolve and open a shared
/// library.
///
/// All [OpenLibraryStrategy] subclasses will have a
/// [OpenLibraryStrategy.strategyId] so they can easily be identified.
///
/// An [OpenLibraryStrategy] will be requested to add itself to a list of
/// strategies.
///
/// All [OpenLibraryStrategy] will provide an implementation of
/// [OpenLibraryStrategy.openFor] which will answer [:true:] if successful,
/// [:false:] if not successful.
abstract class OpenLibraryStrategy {
  /// Return the [String] id of the strategy.
  String get strategyId;

  /// Add this strategy to the list of strategies.
  ///
  /// By default, this strategy will be appended to the end of the list of
  /// [strategies].
  void addTo(List<OpenLibraryStrategy> strategies) {
    strategies.add(this);
  }

  /// Open the shared library located at the provided [path].
  ///
  /// Return [:null:] if there is a problem opening the library at the [path].
  /// Return the opened [DynamicLibrary] on success.
  DynamicLibrary? open(String path) {
    try {
      return Platform.isIOS
          ? DynamicLibrary.process()
          : DynamicLibrary.open(path);
    } on Exception {
      return null;
    }
  }

  /// Subclass Responsibility: Open the shared library for the [OpenLibrary]
  /// mixin.
  ///
  /// Return the opened [DynamicLibrary] on success, [:null:] on failure.
  DynamicLibrary? openFor(OpenLibrary openLibrary);
}
