// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart' as ffi;

import '../../framework/native/allocation.dart';
import 'library.dart';
import 'types.dart';

// ignore_for_file: public_member_api_docs

/// The [ZstdDispatcher] prepares arguments intended for FFI calls and instructs
/// the [ZstdLibrary] which native call to make.
///
/// Impl: To cut down on FFI malloc/free and native heap fragmentation, the
/// native in/out buffer pointers are pre-allocated.
class ZstdDispatcher with ZstdDispatchErrorCheckerMixin {
  /// Answer the version number of the library.
  static int get versionNumber {
    try {
      final dispatcher = ZstdDispatcher();
      final versionNumber = dispatcher._versionNumber;
      dispatcher.release();
      return versionNumber;
    } on Exception {
      return 0;
    }
  }

  /// Library accessor to the Zstd shared lib.
  final ZstdLibrary library;

  /// Version number of the shared library.
  late final int _versionNumber;

  /// For safety to prevent double free.
  bool released = false;

  // These 2 Used in decompression routine to cut down on alloc/free
  final Pointer<ZstdInBuffer> _inBuffer = malloc<ZstdInBuffer>();
  final Pointer<ZstdOutBuffer> _outBuffer = malloc<ZstdOutBuffer>();

  /// Construct the [ZstdDispatcher].
  ZstdDispatcher() : library = ZstdLibrary() {
    _versionNumber = callZstdVersionNumber();
  }

  /// Release native resources.
  void release() {
    if (released == false) {
      malloc.free(_inBuffer);
      released = true;
    }
  }

  int callZstdCompressBound(int srcSize) =>
      checkError(library.zstdCompressBound(srcSize));

  List<int> callZstdCompressStream(
      Pointer<ZstdCStream> zcs,
      Pointer<Uint8> destBuffer,
      int destSize,
      Pointer<Uint8> srcBuffer,
      int srcSize) {
    _inBuffer.ref
      ..src = srcBuffer.cast()
      ..size = srcSize
      ..pos = 0;
    _outBuffer.ref
      ..dst = destBuffer.cast()
      ..size = destSize
      ..pos = 0;
    final hint =
        checkError(library.zstdCompressStream(zcs, _outBuffer, _inBuffer));
    final read = _inBuffer.ref.pos;
    final written = _outBuffer.ref.pos;
    return <int>[read, written, hint];
  }

  Pointer<ZstdCStream> callZstdCreateCStream() => library.zstdCreateCStream();

  Pointer<ZstdDStream> callZstdCreateDStream() => library.zstdCreateDStream();

  int callZstdCStreamInSize() => library.zstdCStreamInSize();

  int callZstdCStreamOutSize() => library.zstdCStreamOutSize();

  List<int> callZstdDecompressStream(
      Pointer<ZstdDStream> zds,
      Pointer<Uint8> destBuffer,
      int destSize,
      Pointer<Uint8> srcBuffer,
      int srcSize) {
    _inBuffer.ref
      ..src = srcBuffer.cast()
      ..size = srcSize
      ..pos = 0;
    _outBuffer.ref
      ..dst = destBuffer.cast()
      ..size = destSize
      ..pos = 0;
    final hint =
        checkError(library.zstdDecompressStream(zds, _outBuffer, _inBuffer));
    final read = _inBuffer.ref.pos;
    final written = _outBuffer.ref.pos;
    return <int>[read, written, hint];
  }

  int callZstdDStreamInSize() => library.zstdDStreamInSize();

  int callZstdDStreamOutSize() => library.zstdDStreamOutSize();

  int callZstdEndStream(
      Pointer<ZstdCStream> zcs, Pointer<Uint8> destBuffer, int destSize) {
    _outBuffer.ref
      ..dst = destBuffer.cast()
      ..size = destSize
      ..pos = 0;
    checkError(library.zstdEndStream(zcs, _outBuffer));
    return _outBuffer.ref.pos;
  }

  int callZstdFlushStream(
      Pointer<ZstdCStream> zcs, Pointer<Uint8> destBuffer, int destSize) {
    _outBuffer.ref
      ..dst = destBuffer.cast()
      ..size = destSize
      ..pos = 0;
    checkError(library.zstdFlushStream(zcs, _outBuffer));
    return _outBuffer.ref.pos;
  }

  int callZstdFreeCStream(Pointer<ZstdCStream> zcs) =>
      checkError(library.zstdFreeCStream(zcs));

  int callZstdFreeDStream(Pointer<ZstdDStream> zds) =>
      checkError(library.zstdFreeDStream(zds));

  Pointer<ffi.Utf8> callZstdGetErrorName(int code) =>
      library.zstdGetErrorName(code);

  int callZstdIsError(int code) => library.zstdIsError(code);

  int callZstdInitCStream(Pointer<ZstdCStream> zcs, int compressionLevel) =>
      checkError(library.zstdInitCStream(zcs, compressionLevel));

  int callZstdInitDStream(Pointer<ZstdDStream> zds) =>
      checkError(library.zstdInitDStream(zds));

  int callZstdVersionNumber() => library.zstdVersionNumber();

  @override
  ZstdDispatcher get dispatcher => this;
}

/// A [ZstdDispatchErrorCheckerMixin] provides error handling capability for
/// APIs in the native Zstd library.
mixin ZstdDispatchErrorCheckerMixin {
  /// Dispatcher to make calls via FFI to zstd shared library
  ZstdDispatcher get dispatcher;

  /// This function wraps all zstd calls and throws a [FormatException] if
  /// [code] is an error code.
  int checkError(int code) {
    if (dispatcher.callZstdIsError(code) != 0) {
      final errorNamePtr = dispatcher.callZstdGetErrorName(code);
      final errorName = ffi.Utf8.fromUtf8(errorNamePtr);
      throw FormatException(errorName);
    } else {
      return code;
    }
  }
}
