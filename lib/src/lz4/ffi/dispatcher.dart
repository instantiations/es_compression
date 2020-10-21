// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart' as ffi;

import 'constants.dart';
import 'library.dart';
import 'types.dart';

// ignore_for_file: public_member_api_docs
class Lz4Dispatcher with Lz4DispatchErrorCheckerMixin {
  static final Lz4Dispatcher _instance = Lz4Dispatcher._();

  /// Library accessor to the Lz4 shared lib.
  Lz4Library library;

  int versionNumber;

  // These 2 Used in decompression routine to cut down on alloc/free
  final Pointer<IntPtr> _srcSizePtr = ffi.allocate<IntPtr>();
  final Pointer<IntPtr> _destSizePtr = ffi.allocate<IntPtr>();

  /// Return the [Lz4Dispatcher] singleton instance
  factory Lz4Dispatcher() {
    return _instance;
  }

  Lz4Dispatcher._() {
    library = Lz4Library();
    versionNumber = callLz4VersionNumber();
  }

  /// Release any temporary resources.
  ///
  /// The [Lz4Dispatcher] is a singleton instance, so care must be taken in
  /// what resources will be released.
  void release() {}

  int callLz4VersionNumber() {
    return library.lz4VersionNumber();
  }

  int callLz4FIsError(int code) {
    return library.lz4FIsError(code);
  }

  Pointer<ffi.Utf8> callLz4FGetErrorName(int code) {
    return library.lz4FGetErrorName(code);
  }

  Lz4Cctx callLz4FCreateCompressionContext(
      {int version = Lz4Constants.LZ4F_VERSION}) {
    final newCtxPtr = ffi.allocate<Pointer<Lz4Cctx>>();
    checkError(library.lz4FCreateCompressionContext(newCtxPtr, version));
    final newCtx = newCtxPtr[0].ref;
    ffi.free(newCtxPtr);
    return newCtx;
  }

  int callLz4FFreeCompressionContext(Lz4Cctx context) {
    return checkError(library.lz4FFreeCompressionContext(context.addressOf));
  }

  int callLz4FCompressBegin(Lz4Cctx context, Pointer<Uint8> destBuffer,
      int destSize, Lz4Preferences preferences) {
    return checkError(library.lz4FCompressBegin(
        context.addressOf, destBuffer, destSize, preferences.addressOf));
  }

  int callLz4FCompressBound(int srcSize, Lz4Preferences preferences) {
    return checkError(
        library.lz4FCompressBound(srcSize, preferences.addressOf));
  }

  int callLz4FCompressUpdate(
      Lz4Cctx context,
      Pointer<Uint8> destBuffer,
      int destSize,
      Pointer<Uint8> srcBuffer,
      int srcSize,
      Lz4CompressOptions options) {
    return checkError(library.lz4FCompressUpdate(context.addressOf, destBuffer,
        destSize, srcBuffer, srcSize, options.addressOf));
  }

  int callLz4FFlush(Lz4Cctx context, Pointer<Uint8> destBuffer, int destSize,
      Lz4CompressOptions options) {
    return checkError(library.lz4FFlush(
        context.addressOf, destBuffer, destSize, options.addressOf));
  }

  int callLz4FCompressEnd(Lz4Cctx context, Pointer<Uint8> destBuffer,
      int destSize, Lz4CompressOptions options) {
    return checkError(library.lz4FCompressEnd(
        context.addressOf, destBuffer, destSize, options.addressOf));
  }

  Lz4Dctx callLz4FCreateDecompressionContext(
      {int version = Lz4Constants.LZ4F_VERSION}) {
    final newCtxPtr = ffi.allocate<Pointer<Lz4Dctx>>();
    checkError(library.lz4FCreateDecompressionContext(newCtxPtr, version));
    final newCtx = newCtxPtr[0].ref;
    ffi.free(newCtxPtr);
    return newCtx;
  }

  int callLz4FFreeDecompressionContext(Lz4Dctx context) {
    return checkError(library.lz4FFreeDecompressionContext(context.addressOf));
  }

  List callLz4FGetFrameInfo(
      Lz4Dctx context, Pointer<Uint8> srcBuffer, int compressedSize) {
    final frameInfo = library.newFrameInfo();
    final sizePtr = ffi.allocate<IntPtr>();
    sizePtr.value = compressedSize;
    final result = checkError(library.lz4FGetFrameInfo(
        context.addressOf, frameInfo.addressOf, srcBuffer, sizePtr));
    final read = sizePtr.value;
    ffi.free(sizePtr);
    return <dynamic>[result, frameInfo, read];
  }

  void callLz4FResetDecompressionContext(Lz4Dctx context) {
    return library.lz4FResetDecompressionContext(context.addressOf);
  }

  List<int> callLz4FDecompress(
      Lz4Dctx context,
      Pointer<Uint8> destBuffer,
      int destSize,
      Pointer<Uint8> srcBuffer,
      int srcSize,
      Lz4DecompressOptions options) {
    _destSizePtr.value = destSize;
    _srcSizePtr.value = srcSize;
    final hint = checkError(library.lz4FDecompress(context.addressOf,
        destBuffer, _destSizePtr, srcBuffer, _srcSizePtr, options.addressOf));
    final read = _srcSizePtr.value;
    final written = _destSizePtr.value;
    return <int>[read, written, hint];
  }

  @override
  Lz4Dispatcher get dispatcher => this;
}

/// A [Lz4DispatchErrorCheckerMixin] provides error handling capability for
/// APIs in the native Lz4 library.
mixin Lz4DispatchErrorCheckerMixin {
  /// Dispatcher to make calls via FFI to lz4 shared library
  Lz4Dispatcher get dispatcher;

  /// This function wraps all lz4 calls and throws a [StateError] if [code]
  /// is an error code.
  int checkError(int code) {
    if (dispatcher.callLz4FIsError(code) != 0) {
      final errorNamePtr = dispatcher.callLz4FGetErrorName(code);
      final errorName = ffi.Utf8.fromUtf8(errorNamePtr);
      throw StateError(errorName);
    } else {
      return code;
    }
  }
}
