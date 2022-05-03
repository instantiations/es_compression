// Copyright (c) 2021, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'constants.dart';
import 'library.dart';
import 'types.dart';

// ignore_for_file: public_member_api_docs

/// The [Lz4Dispatcher] prepares arguments intended for FFI calls and instructs
/// the [Lz4Library] which native call to make.
///
/// Impl: To cut down on FFI malloc/free and native heap fragmentation, the
/// native src/dest size pointers are pre-allocated.
class Lz4Dispatcher with Lz4DispatchErrorCheckerMixin {
  /// Answer the version number of the library.
  static int get versionNumber {
    try {
      final dispatcher = Lz4Dispatcher();
      final versionNumber = dispatcher._versionNumber;
      dispatcher.release();
      return versionNumber;
    } on Exception {
      return 0;
    }
  }

  /// Library accessor to the Lz4 shared lib.
  final Lz4Library library;

  /// Version number of the shared library.
  late final int _versionNumber;

  /// For safety to prevent double free.
  bool released = false;

  // These 2 Used in decompression routine to cut down on alloc/free
  final Pointer<IntPtr> _srcSizePtr = malloc<IntPtr>();
  final Pointer<IntPtr> _destSizePtr = malloc<IntPtr>();

  /// Construct the [Lz4Dispatcher].
  Lz4Dispatcher() : library = Lz4Library() {
    _versionNumber = callLz4VersionNumber();
  }

  /// Release native resources.
  void release() {
    if (released == false) {
      malloc.free(_srcSizePtr);
      malloc.free(_destSizePtr);
      released = true;
    }
  }

  int callLz4VersionNumber() => library.lz4VersionNumber();

  int callLz4FIsError(int code) => library.lz4FIsError(code);

  Pointer<Utf8> callLz4FGetErrorName(int code) =>
      library.lz4FGetErrorName(code);

  Pointer<Lz4Cctx> callLz4FCreateCompressionContext(
      {int version = Lz4Constants.LZ4F_VERSION}) {
    final newCtxPtr = malloc<Pointer<Lz4Cctx>>();
    checkError(library.lz4FCreateCompressionContext(newCtxPtr, version));
    final newCtx = newCtxPtr[0];
    malloc.free(newCtxPtr);
    return newCtx;
  }

  int callLz4FFreeCompressionContext(Pointer<Lz4Cctx> context) =>
      checkError(library.lz4FFreeCompressionContext(context));

  int callLz4FCompressBegin(Pointer<Lz4Cctx> context, Pointer<Uint8> destBuffer,
          int destSize, Pointer<Lz4Preferences> preferences) =>
      checkError(library.lz4FCompressBegin(
          context, destBuffer, destSize, preferences));

  int callLz4FCompressBound(int srcSize, Pointer<Lz4Preferences> preferences) =>
      checkError(library.lz4FCompressBound(srcSize, preferences));

  int callLz4FCompressFrameBound(
          int srcSize, Pointer<Lz4Preferences> preferences) =>
      checkError(library.lz4FCompressFrameBound(srcSize, preferences));

  int callLz4CompressFrame(
          Pointer<Uint8> dstBuffer,
          int dstCapacity,
          Pointer<Uint8> srcBuffer,
          int srcSize,
          Pointer<Lz4Preferences> preferences) =>
      checkError(library.lz4FCompressFrame(
          dstBuffer, dstCapacity, srcBuffer, srcSize, preferences));

  int callLz4FCompressUpdate(
          Pointer<Lz4Cctx> context,
          Pointer<Uint8> destBuffer,
          int destSize,
          Pointer<Uint8> srcBuffer,
          int srcSize,
          Pointer<Lz4CompressOptions> options) =>
      checkError(library.lz4FCompressUpdate(
          context, destBuffer, destSize, srcBuffer, srcSize, options));

  int callLz4FFlush(Pointer<Lz4Cctx> context, Pointer<Uint8> destBuffer,
          int destSize, Pointer<Lz4CompressOptions> options) =>
      checkError(library.lz4FFlush(context, destBuffer, destSize, options));

  int callLz4FCompressEnd(Pointer<Lz4Cctx> context, Pointer<Uint8> destBuffer,
          int destSize, Pointer<Lz4CompressOptions> options) =>
      checkError(
          library.lz4FCompressEnd(context, destBuffer, destSize, options));

  Pointer<Lz4Dctx> callLz4FCreateDecompressionContext(
      {int version = Lz4Constants.LZ4F_VERSION}) {
    final newCtxPtr = malloc<Pointer<Lz4Dctx>>();
    checkError(library.lz4FCreateDecompressionContext(newCtxPtr, version));
    final newCtx = newCtxPtr[0];
    malloc.free(newCtxPtr);
    return newCtx;
  }

  int callLz4FFreeDecompressionContext(Pointer<Lz4Dctx> context) =>
      checkError(library.lz4FFreeDecompressionContext(context));

  List callLz4FGetFrameInfo(
      Pointer<Lz4Dctx> context, Pointer<Uint8> srcBuffer, int compressedSize) {
    final frameInfo = library.newFrameInfo();
    final sizePtr = malloc<IntPtr>();
    sizePtr.value = compressedSize;
    final result = checkError(
        library.lz4FGetFrameInfo(context, frameInfo, srcBuffer, sizePtr));
    final read = sizePtr.value;
    malloc.free(sizePtr);
    return <dynamic>[result, frameInfo, read];
  }

  void callLz4FResetDecompressionContext(Pointer<Lz4Dctx> context) =>
      library.lz4FResetDecompressionContext(context);

  List<int> callLz4FDecompress(
      Pointer<Lz4Dctx> context,
      Pointer<Uint8> destBuffer,
      int destSize,
      Pointer<Uint8> srcBuffer,
      int srcSize,
      Pointer<Lz4DecompressOptions> options) {
    _destSizePtr.value = destSize;
    _srcSizePtr.value = srcSize;
    final hint = checkError(library.lz4FDecompress(
        context, destBuffer, _destSizePtr, srcBuffer, _srcSizePtr, options));
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

  /// This function wraps all lz4 calls and throws a [FormatException] if [code]
  /// is an error code.
  int checkError(int code) {
    if (dispatcher.callLz4FIsError(code) != 0) {
      final errorNamePtr = dispatcher.callLz4FGetErrorName(code);
      final errorName = errorNamePtr.toDartString();
      throw FormatException(errorName);
    } else {
      return code;
    }
  }
}
