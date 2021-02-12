// Copyright (c) 2021, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart' as ffi;

import 'types.dart';

// ignore_for_file: public_member_api_docs

/// File: *lz4.h*
/// LZ4LIB_API int LZ4_versionNumber(void);
typedef Lz4VersionNumberNative = Int32 Function();
typedef Lz4VersionNumberDart = int Function();

/// File: *lz4frame.h*
/// LZ4FLIB_API size_t LZ4F_compressBegin(
///    LZ4F_cctx* cctx,
///    void* dstBuffer,
///    size_t dstCapacity,
///    const LZ4F_preferences_t* prefsPtr
/// );
typedef Lz4FCompressBeginNative = IntPtr Function(
    Pointer<Lz4Cctx>, Pointer<Uint8>, IntPtr, Pointer<Lz4Preferences>);
typedef Lz4FCompressBeginDart = int Function(
    Pointer<Lz4Cctx>, Pointer<Uint8>, int, Pointer<Lz4Preferences>);

/// File: *lz4frame.h*
/// LZ4FLIB_API size_t LZ4F_compressBound(
///    size_t srcSize, const LZ4F_preferences_t* prefsPtr);
typedef Lz4FCompressBoundNative = IntPtr Function(
    IntPtr, Pointer<Lz4Preferences>);
typedef Lz4FCompressBoundDart = int Function(int, Pointer<Lz4Preferences>);

/// File: *lz4frame.h*
/// LZ4FLIB_API size_t LZ4F_compressEnd(LZ4F_cctx* cctx,
///    void* dstBuffer, size_t dstCapacity,
///    const LZ4F_compressOptions_t* cOptPtr);
typedef Lz4FCompressEndNative = IntPtr Function(
    Pointer<Lz4Cctx>, Pointer<Uint8>, IntPtr, Pointer<Lz4CompressOptions>);
typedef Lz4FCompressEndDart = int Function(
    Pointer<Lz4Cctx>,
    Pointer<Uint8> dstBuffer,
    int dstCapacity,
    Pointer<Lz4CompressOptions> cOptPtr);

/// File: *lz4frame.h*
/// LZ4FLIB_API size_t LZ4F_compressFrame(void* dstBuffer, size_t dstCapacity,
///    const void* srcBuffer, size_t srcSize,
///    const LZ4F_preferences_t* preferencesPtr);
typedef Lz4FCompressFrameNative = IntPtr Function(
    Pointer<Uint8>, IntPtr, Pointer<Uint8>, IntPtr, Pointer<Lz4Preferences>);
typedef Lz4FCompressFrameDart = int Function(
    Pointer<Uint8>, int, Pointer<Uint8>, int, Pointer<Lz4Preferences>);

/// File: *lz4frame.h*
/// LZ4FLIB_API size_t LZ4F_compressFrameBound(
///    size_t srcSize, const LZ4F_preferences_t* preferencesPtr);
typedef Lz4FCompressFrameBoundNative = IntPtr Function(
    IntPtr, Pointer<Lz4Preferences>);
typedef Lz4FCompressFrameBoundDart = int Function(int, Pointer<Lz4Preferences>);

/// File: *lz4frame.h*
/// LZ4FLIB_API size_t LZ4F_compressUpdate(LZ4F_cctx* cctx,
///    void* dstBuffer, size_t dstCapacity,
///    const void* srcBuffer, size_t srcSize,
///    const LZ4F_compressOptions_t* cOptPtr);
typedef Lz4FCompressUpdateNative = IntPtr Function(
    Pointer<Lz4Cctx>,
    Pointer<Uint8>,
    IntPtr,
    Pointer<Uint8>,
    IntPtr,
    Pointer<Lz4CompressOptions>);
typedef Lz4FCompressUpdateDart = int Function(Pointer<Lz4Cctx>, Pointer<Uint8>,
    int, Pointer<Uint8>, int, Pointer<Lz4CompressOptions>);

/// File: *lz4frame.h*
/// LZ4FLIB_API LZ4F_errorCode_t LZ4F_createCompressionContext(
///    LZ4F_cctx** cctxPtr, unsigned version);
typedef Lz4FCreateCompressionContextNative = IntPtr Function(
    Pointer<Pointer<Lz4Cctx>>, Uint32);
typedef Lz4FCreateCompressionContextDart = int Function(
    Pointer<Pointer<Lz4Cctx>>, int);

/// File: *lz4frame.h*
/// LZ4FLIB_API LZ4F_errorCode_t LZ4F_createDecompressionContext(
///     LZ4F_dctx** dctxPtr, unsigned version);
typedef Lz4FCreateDecompressionContextNative = IntPtr Function(
    Pointer<Pointer<Lz4Dctx>>, Uint32);
typedef Lz4FCreateDecompressionContextDart = int Function(
    Pointer<Pointer<Lz4Dctx>>, int);

/// File: *lz4frame.h*
/// LZ4FLIB_API size_t LZ4F_decompress(LZ4F_dctx* dctx,
///     void* dstBuffer, size_t* dstSizePtr,
///     const void* srcBuffer, size_t* srcSizePtr,
///     const LZ4F_decompressOptions_t* dOptPtr);
typedef Lz4FDecompressNative = IntPtr Function(
    Pointer<Lz4Dctx>,
    Pointer<Uint8>,
    Pointer<IntPtr>,
    Pointer<Uint8>,
    Pointer<IntPtr>,
    Pointer<Lz4DecompressOptions>);
typedef Lz4FDecompressDart = int Function(
    Pointer<Lz4Dctx>,
    Pointer<Uint8>,
    Pointer<IntPtr>,
    Pointer<Uint8>,
    Pointer<IntPtr>,
    Pointer<Lz4DecompressOptions>);

/// File: *lz4frame.h*
/// LZ4FLIB_API size_t LZ4F_flush(LZ4F_cctx* cctx,
///     void* dstBuffer, size_t dstCapacity,
///     const LZ4F_compressOptions_t* cOptPtr);
typedef Lz4FFlushNative = IntPtr Function(
    Pointer<Lz4Cctx>, Pointer<Uint8>, IntPtr, Pointer<Lz4CompressOptions>);
typedef Lz4FFlushDart = int Function(
    Pointer<Lz4Cctx>, Pointer<Uint8>, int, Pointer<Lz4CompressOptions>);

/// File: *lz4frame.h*
/// LZ4FLIB_API LZ4F_errorCode_t LZ4F_freeCompressionContext(LZ4F_cctx* cctx);
typedef Lz4FFreeCompressionContextNative = IntPtr Function(Pointer<Lz4Cctx>);
typedef Lz4FFreeCompressionContextDart = int Function(Pointer<Lz4Cctx>);

/// File: *lz4frame.h*
/// LZ4FLIB_API LZ4F_errorCode_t LZ4F_freeDecompressionContext(LZ4F_dctx* dctx);
typedef Lz4FFreeDecompressionContextNative = IntPtr Function(Pointer<Lz4Dctx>);
typedef Lz4FFreeDecompressionContextDart = int Function(Pointer<Lz4Dctx>);

/// File: *lz4frame.h*
/// LZ4FLIB_API const char* LZ4F_getErrorName(LZ4F_errorCode_t code);
typedef Lz4FGetErrorNameNative = Pointer<ffi.Utf8> Function(IntPtr);
typedef Lz4FGetErrorNameDart = Pointer<ffi.Utf8> Function(int);

/// File: *lz4frame.h*
/// LZ4FLIB_API size_t LZ4F_getFrameInfo(LZ4F_dctx* dctx,
///     LZ4F_frameInfo_t* frameInfoPtr,
///     const void* srcBuffer, size_t* srcSizePtr);
typedef Lz4FGetFrameInfoNative = IntPtr Function(
    Pointer<Lz4Dctx>, Pointer<Lz4FrameInfo>, Pointer<Uint8>, Pointer<IntPtr>);
typedef Lz4FGetFrameInfoDart = int Function(
    Pointer<Lz4Dctx>, Pointer<Lz4FrameInfo>, Pointer<Uint8>, Pointer<IntPtr>);

/// File: *lz4frame.h*
/// LZ4FLIB_API unsigned LZ4F_isError(LZ4F_errorCode_t code);
typedef Lz4FIsErrorNative = Uint32 Function(IntPtr);
typedef Lz4FIsErrorDart = int Function(int);

/// File: *lz4frame.h*
/// LZ4FLIB_API void LZ4F_resetDecompressionContext(LZ4F_dctx* dctx);
typedef Lz4FResetDecompressionContextNative = Void Function(Pointer<Lz4Dctx>);
typedef Lz4FResetDecompressionContextDart = void Function(Pointer<Lz4Dctx>);

/// Contains required functions referenced by the following header files:
/// *lz4.h*
/// *lz4frame.h*
mixin Lz4Functions {
  late final Lz4VersionNumberDart lz4VersionNumber;
  late final Lz4FIsErrorDart lz4FIsError;
  late final Lz4FGetErrorNameDart lz4FGetErrorName;
  late final Lz4FCreateCompressionContextDart lz4FCreateCompressionContext;
  late final Lz4FFreeCompressionContextDart lz4FFreeCompressionContext;
  late final Lz4FCompressBeginDart lz4FCompressBegin;
  late final Lz4FCompressBoundDart lz4FCompressBound;
  late final Lz4FCompressFrameDart lz4FCompressFrame;
  late final Lz4FCompressFrameBoundDart lz4FCompressFrameBound;
  late final Lz4FCompressUpdateDart lz4FCompressUpdate;
  late final Lz4FCompressEndDart lz4FCompressEnd;
  late final Lz4FFlushDart lz4FFlush;
  late final Lz4FCreateDecompressionContextDart lz4FCreateDecompressionContext;
  late final Lz4FFreeDecompressionContextDart lz4FFreeDecompressionContext;
  late final Lz4FGetFrameInfoDart lz4FGetFrameInfo;
  late final Lz4FResetDecompressionContextDart lz4FResetDecompressionContext;
  late final Lz4FDecompressDart lz4FDecompress;

  /// Resolve all functions using the [library]
  void resolveFunctions(DynamicLibrary library) {
    lz4VersionNumber =
        library.lookupFunction<Lz4VersionNumberNative, Lz4VersionNumberDart>(
            'LZ4_versionNumber');
    lz4FIsError = library
        .lookupFunction<Lz4FIsErrorNative, Lz4FIsErrorDart>('LZ4F_isError');
    lz4FGetErrorName =
        library.lookupFunction<Lz4FGetErrorNameNative, Lz4FGetErrorNameDart>(
            'LZ4F_getErrorName');
    lz4FCreateCompressionContext = library.lookupFunction<
        Lz4FCreateCompressionContextNative,
        Lz4FCreateCompressionContextDart>('LZ4F_createCompressionContext');
    lz4FFreeCompressionContext = library.lookupFunction<
        Lz4FFreeCompressionContextNative,
        Lz4FFreeCompressionContextDart>('LZ4F_freeCompressionContext');
    lz4FCompressBegin =
        library.lookupFunction<Lz4FCompressBeginNative, Lz4FCompressBeginDart>(
            'LZ4F_compressBegin');
    lz4FCompressBound =
        library.lookupFunction<Lz4FCompressBoundNative, Lz4FCompressBoundDart>(
            'LZ4F_compressBound');
    lz4FCompressFrame =
        library.lookupFunction<Lz4FCompressFrameNative, Lz4FCompressFrameDart>(
            'LZ4F_compressFrame');
    lz4FCompressFrameBound = library.lookupFunction<
        Lz4FCompressFrameBoundNative,
        Lz4FCompressFrameBoundDart>('LZ4F_compressFrameBound');
    lz4FCompressUpdate = library.lookupFunction<Lz4FCompressUpdateNative,
        Lz4FCompressUpdateDart>('LZ4F_compressUpdate');
    lz4FCompressEnd =
        library.lookupFunction<Lz4FCompressEndNative, Lz4FCompressEndDart>(
            'LZ4F_compressEnd');
    lz4FFlush =
        library.lookupFunction<Lz4FFlushNative, Lz4FFlushDart>('LZ4F_flush');
    lz4FCreateDecompressionContext = library.lookupFunction<
        Lz4FCreateDecompressionContextNative,
        Lz4FCreateDecompressionContextDart>('LZ4F_createDecompressionContext');
    lz4FFreeDecompressionContext = library.lookupFunction<
        Lz4FFreeDecompressionContextNative,
        Lz4FFreeDecompressionContextDart>('LZ4F_freeDecompressionContext');
    lz4FGetFrameInfo =
        library.lookupFunction<Lz4FGetFrameInfoNative, Lz4FGetFrameInfoDart>(
            'LZ4F_getFrameInfo');
    lz4FResetDecompressionContext = library.lookupFunction<
        Lz4FResetDecompressionContextNative,
        Lz4FResetDecompressionContextDart>('LZ4F_resetDecompressionContext');
    lz4FDecompress =
        library.lookupFunction<Lz4FDecompressNative, Lz4FDecompressDart>(
            'LZ4F_decompress');
  }
}
