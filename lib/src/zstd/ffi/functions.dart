// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart' as ffi;

import 'types.dart';

// ignore_for_file: public_member_api_docs

typedef ZstdCompressNative = Pointer<Void> Function(
    Pointer<Void>, Pointer<Void>, Pointer<Void>, Pointer<Void>, Int32);
typedef ZstdCompressDart = Pointer<Void> Function(
    Pointer<Void>, Pointer<Void>, Pointer<Void>, Pointer<Void>, int);

typedef ZstdCompressUsingCDictNative = Pointer<Void> Function(Pointer<Void>,
    Pointer<Void>, Pointer<Void>, Pointer<Void>, Pointer<Void>, Pointer<Void>);
typedef ZstdCompressUsingCDictDart = Pointer<Void> Function(Pointer<Void>,
    Pointer<Void>, Pointer<Void>, Pointer<Void>, Pointer<Void>, Pointer<Void>);

typedef ZstdCompressUsingDictNative = Pointer<Void> Function(
    Pointer<Void>,
    Pointer<Void>,
    Pointer<Void>,
    Pointer<Void>,
    Pointer<Void>,
    Pointer<Void>,
    Pointer<Void>,
    Int32);
typedef ZstdCompressUsingDictDart = Pointer<Void> Function(
    Pointer<Void>,
    Pointer<Void>,
    Pointer<Void>,
    Pointer<Void>,
    Pointer<Void>,
    Pointer<Void>,
    Pointer<Void>,
    int);

/// File: *zstd.h*
/// ZSTDLIB_API size_t ZSTD_compressBound(size_t srcSize);
typedef ZstdCompressBoundNative = IntPtr Function(IntPtr);
typedef ZstdCompressBoundDart = int Function(int);

typedef ZstdCompressCCtxNative = Pointer<Void> Function(Pointer<Void>,
    Pointer<Void>, Pointer<Void>, Pointer<Void>, Pointer<Void>, Int32);
typedef ZstdCompressCCtxDart = Pointer<Void> Function(Pointer<Void>,
    Pointer<Void>, Pointer<Void>, Pointer<Void>, Pointer<Void>, int);

/// File: *zstd.h*
/// ZSTDLIB_API size_t
/// ZSTD_compressStream(ZSTD_CStream* zcs,
///   ZSTD_outBuffer* output,
///   ZSTD_inBuffer* input);
typedef ZstdCompressStreamNative = IntPtr Function(
    Pointer<ZstdCStream>, Pointer<ZstdOutBuffer>, Pointer<ZstdInBuffer>);
typedef ZstdCompressStreamDart = int Function(
    Pointer<ZstdCStream>, Pointer<ZstdOutBuffer>, Pointer<ZstdInBuffer>);

typedef ZstdCreateCCtxNative = Pointer<Void> Function();
typedef ZstdCreateCCtxDart = Pointer<Void> Function();

typedef ZstdCreateCDictNative = Pointer<Void> Function(
    Pointer<Void>, Pointer<Void>, Int32);
typedef ZstdCreateCDictDart = Pointer<Void> Function(
    Pointer<Void>, Pointer<Void>, int);

/// File: *zstd.h*
/// ZSTDLIB_API ZSTD_CStream* ZSTD_createCStream(void);
typedef ZstdCreateCStreamNative = Pointer<ZstdCStream> Function();
typedef ZstdCreateCStreamDart = Pointer<ZstdCStream> Function();

typedef ZstdCreateDCtxNative = Pointer<Void> Function();
typedef ZstdCreateDCtxDart = Pointer<Void> Function();

typedef ZstdCreateDDictNative = Pointer<Void> Function(
    Pointer<Void>, Pointer<Void>);
typedef ZstdCreateDDictDart = Pointer<Void> Function(
    Pointer<Void>, Pointer<Void>);

/// File: *zstd.h*
/// ZSTDLIB_API ZSTD_DStream* ZSTD_createDStream(void);
typedef ZstdCreateDStreamNative = Pointer<ZstdDStream> Function();
typedef ZstdCreateDStreamDart = Pointer<ZstdDStream> Function();

/// File: *zstd.h*
/// ZSTDLIB_API size_t ZSTD_CStreamInSize(void);
typedef ZstdCStreamInSizeNative = IntPtr Function();
typedef ZstdCStreamInSizeDart = int Function();

/// File: *zstd.h*
/// ZSTDLIB_API size_t ZSTD_CStreamOutSize(void);
typedef ZstdCStreamOutSizeNative = IntPtr Function();
typedef ZstdCStreamOutSizeDart = int Function();

typedef ZstdDecompressNative = Pointer<Void> Function(
    Pointer<Void>, Pointer<Void>, Pointer<Void>, Pointer<Void>);
typedef ZstdDecompressDart = Pointer<Void> Function(
    Pointer<Void>, Pointer<Void>, Pointer<Void>, Pointer<Void>);

typedef ZstdDecompressUsingDDictNative = Pointer<Void> Function(Pointer<Void>,
    Pointer<Void>, Pointer<Void>, Pointer<Void>, Pointer<Void>, Pointer<Void>);
typedef ZstdDecompressUsingDDictDart = Pointer<Void> Function(Pointer<Void>,
    Pointer<Void>, Pointer<Void>, Pointer<Void>, Pointer<Void>, Pointer<Void>);

typedef ZstdDecompressUsingDictNative = Pointer<Void> Function(
    Pointer<Void>,
    Pointer<Void>,
    Pointer<Void>,
    Pointer<Void>,
    Pointer<Void>,
    Pointer<Void>,
    Pointer<Void>);
typedef ZstdDecompressUsingDictDart = Pointer<Void> Function(
    Pointer<Void>,
    Pointer<Void>,
    Pointer<Void>,
    Pointer<Void>,
    Pointer<Void>,
    Pointer<Void>,
    Pointer<Void>);

typedef ZstdDecompressDCtxNative = Pointer<Void> Function(
    Pointer<Void>, Pointer<Void>, Pointer<Void>, Pointer<Void>, Pointer<Void>);
typedef ZstdDecompressDCtxDart = Pointer<Void> Function(
    Pointer<Void>, Pointer<Void>, Pointer<Void>, Pointer<Void>, Pointer<Void>);

/// File: *zstd.h*
/// ZSTDLIB_API size_t
/// ZSTD_decompressStream(ZSTD_DStream* zds,
///   ZSTD_outBuffer* output,
///   ZSTD_inBuffer* input);
typedef ZstdDecompressStreamNative = IntPtr Function(
    Pointer<ZstdDStream>, Pointer<ZstdOutBuffer>, Pointer<ZstdInBuffer>);
typedef ZstdDecompressStreamDart = int Function(
    Pointer<ZstdDStream>, Pointer<ZstdOutBuffer>, Pointer<ZstdInBuffer>);

/// File: *zstd.h*
/// ZSTDLIB_API size_t ZSTD_DStreamInSize(void);
typedef ZstdDStreamInSizeNative = IntPtr Function();
typedef ZstdDStreamInSizeDart = int Function();

/// File: *zstd.h*
/// ZSTDLIB_API size_t ZSTD_DStreamOutSize(void);
typedef ZstdDStreamOutSizeNative = IntPtr Function();
typedef ZstdDStreamOutSizeDart = int Function();

/// File: *zstd.h*
/// ZSTDLIB_API size_t
/// ZSTD_endStream(ZSTD_CStream* zcs, ZSTD_outBuffer* output);
typedef ZstdEndStreamNative = IntPtr Function(
    Pointer<ZstdCStream>, Pointer<ZstdOutBuffer>);
typedef ZstdEndStreamDart = int Function(
    Pointer<ZstdCStream>, Pointer<ZstdOutBuffer>);

/// File: *zstd.h*
/// ZSTDLIB_API size_t
/// ZSTD_flushStream(ZSTD_CStream* zcs, ZSTD_outBuffer* output);
typedef ZstdFlushStreamNative = IntPtr Function(
    Pointer<ZstdCStream>, Pointer<ZstdOutBuffer>);
typedef ZstdFlushStreamDart = int Function(
    Pointer<ZstdCStream>, Pointer<ZstdOutBuffer>);

typedef ZstdFreeCCtxNative = Pointer<Void> Function(Pointer<Void>);
typedef ZstdFreeCCtxDart = Pointer<Void> Function(Pointer<Void>);

typedef ZstdFreeCDictNative = Pointer<Void> Function(Pointer<Void>);
typedef ZstdFreeCDictDart = Pointer<Void> Function(Pointer<Void>);

/// File: *zstd.h*
/// ZSTDLIB_API size_t ZSTD_freeCStream(ZSTD_CStream* zcs);
typedef ZstdFreeCStreamNative = IntPtr Function(Pointer<ZstdCStream>);
typedef ZstdFreeCStreamDart = int Function(Pointer<ZstdCStream>);

typedef ZstdFreeDCtxNative = Pointer<Void> Function(Pointer<Void>);
typedef ZstdFreeDCtxDart = Pointer<Void> Function(Pointer<Void>);

typedef ZstdFreeDDictNative = Pointer<Void> Function(Pointer<Void>);
typedef ZstdFreeDDictDart = Pointer<Void> Function(Pointer<Void>);

typedef ZstdFreeDStreamNative = IntPtr Function(Pointer<ZstdDStream>);
typedef ZstdFreeDStreamDart = int Function(Pointer<ZstdDStream>);

typedef ZstdGetDecompressedSizeNative = Uint64 Function(
    Pointer<Void>, Pointer<Void>);
typedef ZstdGetDecompressedSizeDart = int Function(
    Pointer<Void>, Pointer<Void>);

/// File: *zstd.h*
/// ZSTDLIB_API const char* ZSTD_getErrorName(size_t code);
typedef ZstdGetErrorNameNative = Pointer<ffi.Utf8> Function(IntPtr);
typedef ZstdGetErrorNameDart = Pointer<ffi.Utf8> Function(int);

typedef ZstdGetFrameContentSizeNative = Uint64 Function(
    Pointer<Void>, Pointer<Void>);
typedef ZstdGetFrameContentSizeDart = int Function(
    Pointer<Void>, Pointer<Void>);

/// File: *zstd.h*
/// ZSTDLIB_API size_t
/// ZSTD_initCStream(ZSTD_CStream* zcs, int compressionLevel);
typedef ZstdInitCStreamNative = IntPtr Function(Pointer<ZstdCStream>, Int32);
typedef ZstdInitCStreamDart = int Function(Pointer<ZstdCStream>, int);

/// File: *zstd.h*
/// ZSTDLIB_API size_t ZSTD_initDStream(ZSTD_DStream* zds);
typedef ZstdInitDStreamNative = IntPtr Function(Pointer<ZstdDStream>);
typedef ZstdInitDStreamDart = int Function(Pointer<ZstdDStream>);

/// File: *zstd.h*
/// ZSTDLIB_API unsigned ZSTD_isError(size_t code);
typedef ZstdIsErrorNative = Uint32 Function(IntPtr);
typedef ZstdIsErrorDart = int Function(int);

typedef ZstdMaxCLevelNative = Int32 Function();
typedef ZstdMaxCLevelDart = int Function();

/// File: *zstd.h*
/// ZSTDLIB_API unsigned ZSTD_versionNumber(void);
typedef ZstdVersionNumberNative = Uint32 Function();
typedef ZstdVersionNumberDart = int Function();

typedef ZstdVersionStringNative = Pointer<Void> Function();
typedef ZstdVersionStringDart = Pointer<Void> Function();

/// Contains required functions referenced by the following header files:
/// *zstd.h*
mixin ZstdFunctions {
  ZstdCompressDart zstdCompress;
  ZstdCompressUsingCDictDart zstdCompressUsingcdict;
  ZstdCompressUsingDictDart zstdCompressUsingdict;
  ZstdCompressBoundDart zstdCompressBound;
  ZstdCompressCCtxDart zstdCompresscctx;
  ZstdCompressStreamDart zstdCompressStream;
  ZstdCreateCCtxDart zstdCreatecctx;
  ZstdCreateCDictDart zstdCreatecdict;
  ZstdCreateCStreamDart zstdCreateCStream;
  ZstdCreateDCtxDart zstdCreatedctx;
  ZstdCreateDDictDart zstdCreateddict;
  ZstdCreateDStreamDart zstdCreateDStream;
  ZstdCStreamInSizeDart zstdCStreamInSize;
  ZstdCStreamOutSizeDart zstdCStreamOutSize;
  ZstdDecompressDart zstdDecompress;
  ZstdDecompressUsingDDictDart zstdDecompressUsingddict;
  ZstdDecompressUsingDictDart zstdDecompressUsingdict;
  ZstdDecompressDCtxDart zstdDecompressdctx;
  ZstdDecompressStreamDart zstdDecompressStream;
  ZstdDStreamInSizeDart zstdDStreamInSize;
  ZstdDStreamOutSizeDart zstdDStreamOutSize;
  ZstdEndStreamDart zstdEndStream;
  ZstdFlushStreamDart zstdFlushStream;
  ZstdFreeCCtxDart zstdFreecctx;
  ZstdFreeCDictDart zstdFreecdict;
  ZstdFreeCStreamDart zstdFreeCStream;
  ZstdFreeDCtxDart zstdFreedctx;
  ZstdFreeDDictDart zstdFreeddict;
  ZstdFreeDStreamDart zstdFreeDStream;
  ZstdGetDecompressedSizeDart zstdGetdecompressedsize;
  ZstdGetErrorNameDart zstdGetErrorName;
  ZstdGetFrameContentSizeDart zstdGetframecontentsize;
  ZstdInitCStreamDart zstdInitCStream;
  ZstdInitDStreamDart zstdInitDStream;
  ZstdIsErrorDart zstdIsError;
  ZstdMaxCLevelDart zstdMaxclevel;
  ZstdVersionNumberDart zstdVersionNumber;
  ZstdVersionStringDart zstdVersionstring;

  /// Resolve all functions using the [library]
  void resolveFunctions(DynamicLibrary library) {
    zstdCompressBound =
        library.lookupFunction<ZstdCompressBoundNative, ZstdCompressBoundDart>(
            'ZSTD_compressBound');

    zstdCompressStream = library.lookupFunction<ZstdCompressStreamNative,
        ZstdCompressStreamDart>('ZSTD_compressStream');

    zstdCreateCStream =
        library.lookupFunction<ZstdCreateCStreamNative, ZstdCreateCStreamDart>(
            'ZSTD_createCStream');

    zstdCreateDStream =
        library.lookupFunction<ZstdCreateDStreamNative, ZstdCreateDStreamDart>(
            'ZSTD_createDStream');

    zstdCStreamInSize =
        library.lookupFunction<ZstdCStreamInSizeNative, ZstdCStreamInSizeDart>(
            'ZSTD_CStreamInSize');

    zstdCStreamOutSize = library.lookupFunction<ZstdCStreamOutSizeNative,
        ZstdCStreamOutSizeDart>('ZSTD_CStreamOutSize');

    zstdDecompressStream = library.lookupFunction<ZstdDecompressStreamNative,
        ZstdDecompressStreamDart>('ZSTD_decompressStream');

    zstdDStreamInSize =
        library.lookupFunction<ZstdDStreamInSizeNative, ZstdDStreamInSizeDart>(
            'ZSTD_DStreamInSize');

    zstdDStreamOutSize = library.lookupFunction<ZstdDStreamOutSizeNative,
        ZstdDStreamOutSizeDart>('ZSTD_DStreamOutSize');

    zstdEndStream =
        library.lookupFunction<ZstdEndStreamNative, ZstdEndStreamDart>(
            'ZSTD_endStream');

    zstdFlushStream =
        library.lookupFunction<ZstdFlushStreamNative, ZstdFlushStreamDart>(
            'ZSTD_flushStream');

    zstdFreeCStream =
        library.lookupFunction<ZstdFreeCStreamNative, ZstdFreeCStreamDart>(
            'ZSTD_freeCStream');

    zstdFreeDStream =
        library.lookupFunction<ZstdFreeDStreamNative, ZstdFreeDStreamDart>(
            'ZSTD_freeDStream');

    zstdGetErrorName =
        library.lookupFunction<ZstdGetErrorNameNative, ZstdGetErrorNameDart>(
            'ZSTD_getErrorName');

    zstdInitCStream =
        library.lookupFunction<ZstdInitCStreamNative, ZstdInitCStreamDart>(
            'ZSTD_initCStream');

    zstdInitDStream =
        library.lookupFunction<ZstdInitDStreamNative, ZstdInitDStreamDart>(
            'ZSTD_initDStream');

    zstdIsError = library
        .lookupFunction<ZstdIsErrorNative, ZstdIsErrorDart>('ZSTD_isError');

    zstdVersionNumber =
        library.lookupFunction<ZstdVersionNumberNative, ZstdVersionNumberDart>(
            'ZSTD_versionNumber');
  }
}
