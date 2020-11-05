// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart' as ffi;

import 'types.dart';

// ignore_for_file: public_member_api_docs

/// File: *decoder.h*
/// BROTLI_DEC_API BrotliDecoderState* BrotliDecoderCreateInstance(
///     brotli_alloc_func alloc_func, brotli_free_func free_func, void* opaque);
typedef BrotliDecoderCreateInstanceNative = Pointer<BrotliDecoderState>
    Function(Pointer<Void>, Pointer<Void>, Pointer<Void>);
typedef BrotliDecoderCreateInstanceDart = Pointer<BrotliDecoderState> Function(
    Pointer<Void>, Pointer<Void>, Pointer<Void>);

/// File: *decoder.h*
/// BROTLI_DEC_API BrotliDecoderResult BrotliDecoderDecompress(
///     size_t encoded_size,
///     const uint8_t encoded_buffer[BROTLI_ARRAY_PARAM(encoded_size)],
///     size_t* decoded_size,
///     uint8_t decoded_buffer[BROTLI_ARRAY_PARAM(*decoded_size)]);
typedef BrotliDecoderDecompressNative = Int32 Function(
    Pointer<Void>, Pointer<Void>, Pointer<Void>, Pointer<Void>);
typedef BrotliDecoderDecompressDart = int Function(
    Pointer<Void>, Pointer<Void>, Pointer<Void>, Pointer<Void>);

/// File: *decoder.h*
/// BROTLI_DEC_API BrotliDecoderResult BrotliDecoderDecompressStream(
///   BrotliDecoderState* state, size_t* available_in, const uint8_t** next_in,
///   size_t* available_out, uint8_t** next_out, size_t* total_out);
typedef BrotliDecoderDecompressStreamNative = Int32 Function(
    Pointer<BrotliDecoderState>,
    Pointer<IntPtr>,
    Pointer<Pointer<Uint8>>,
    Pointer<IntPtr>,
    Pointer<Pointer<Uint8>>,
    Pointer<IntPtr>);
typedef BrotliDecoderDecompressStreamDart = int Function(
    Pointer<BrotliDecoderState>,
    Pointer<IntPtr>,
    Pointer<Pointer<Uint8>>,
    Pointer<IntPtr>,
    Pointer<Pointer<Uint8>>,
    Pointer<IntPtr>);

/// File: *decode.h*
/// BROTLI_DEC_API BrotliDecoderState* BrotliDecoderCreateInstance(
///     brotli_alloc_func alloc_func, brotli_free_func free_func, void* opaque);
typedef BrotliDecoderDestroyInstanceNative = Void Function(
    Pointer<BrotliDecoderState>);
typedef BrotliDecoderDestroyInstanceDart = void Function(
    Pointer<BrotliDecoderState>);

/// File: *decode.h*
/// BROTLI_DEC_API const char*
/// BrotliDecoderErrorString(BrotliDecoderErrorCode c);
typedef BrotliDecoderErrorStringNative = Pointer<ffi.Utf8> Function(Int32);
typedef BrotliDecoderErrorStringDart = Pointer<ffi.Utf8> Function(int);

/// File: *decode.h*
/// BROTLI_DEC_API BrotliDecoderErrorCode BrotliDecoderGetErrorCode(
///     const BrotliDecoderState* state);
typedef BrotliDecoderGetErrorCodeNative = Int32 Function(
    Pointer<BrotliDecoderState>);
typedef BrotliDecoderGetErrorCodeDart = int Function(
    Pointer<BrotliDecoderState>);

/// File: *decode.h*
/// BROTLI_DEC_API BROTLI_BOOL BrotliDecoderHasMoreOutput(
///     const BrotliDecoderState* state);
typedef BrotliDecoderHasMoreOutputNative = Int32 Function(
    Pointer<BrotliDecoderState>);
typedef BrotliDecoderHasMoreOutputDart = int Function(
    Pointer<BrotliDecoderState>);

/// File: *decode.h*
/// BROTLI_DEC_API BROTLI_BOOL BrotliDecoderIsFinished(
///     const BrotliDecoderState* state);
typedef BrotliDecoderIsFinishedNative = Int32 Function(
    Pointer<BrotliDecoderState>);
typedef BrotliDecoderIsFinishedDart = int Function(Pointer<BrotliDecoderState>);

/// File: *decode.h*
/// BROTLI_DEC_API BROTLI_BOOL
/// BrotliDecoderIsUsed(const BrotliDecoderState* state);
typedef BrotliDecoderIsUsedNative = Int32 Function(Pointer<BrotliDecoderState>);
typedef BrotliDecoderIsUsedDart = int Function(Pointer<BrotliDecoderState>);

/// File: *decode.h*
/// BROTLI_DEC_API BROTLI_BOOL BrotliDecoderSetParameter(
///     BrotliDecoderState* state,
///     BrotliDecoderParameter param, uint32_t value);
typedef BrotliDecoderSetParameterNative = Int32 Function(
    Pointer<BrotliDecoderState>, Int32, Uint32);
typedef BrotliDecoderSetParameterDart = int Function(
    Pointer<BrotliDecoderState>, int, int);

/// File: *decode.h*
/// BROTLI_DEC_API const uint8_t* BrotliDecoderTakeOutput(
///     BrotliDecoderState* state, size_t* size);
typedef BrotliDecoderTakeOutputNative = Pointer<Uint8> Function(
    Pointer<BrotliDecoderState>, Pointer<IntPtr>);
typedef BrotliDecoderTakeOutputDart = Pointer<Uint8> Function(
    Pointer<BrotliDecoderState>, Pointer<IntPtr>);

/// File: *decode.h*
/// BROTLI_DEC_API uint32_t BrotliDecoderVersion(void);
typedef BrotliDecoderVersionNative = Uint32 Function();
typedef BrotliDecoderVersionDart = int Function();

/// File: *encode.h*
/// BROTLI_ENC_API BROTLI_BOOL BrotliEncoderCompress(
///     int quality, int lgwin, BrotliEncoderMode mode, size_t input_size,
///     const uint8_t input_buffer[BROTLI_ARRAY_PARAM(input_size)],
///     size_t* encoded_size,
///     uint8_t encoded_buffer[BROTLI_ARRAY_PARAM(*encoded_size)]);
typedef BrotliEncoderCompressNative = Int32 Function(Int32, Int32, Int32,
    IntPtr, Pointer<Uint8>, Pointer<IntPtr>, Pointer<Uint8>);
typedef BrotliEncoderCompressDart = int Function(
    int, int, int, int, Pointer<Uint8>, Pointer<IntPtr>, Pointer<Uint8>);

/// File: *encode.h*
/// BROTLI_ENC_API BROTLI_BOOL BrotliEncoderCompressStream(
///     BrotliEncoderState* state,
///     BrotliEncoderOperation op, size_t* available_in,
///     const uint8_t** next_in, size_t* available_out, uint8_t** next_out,
///     size_t* total_out);
typedef BrotliEncoderCompressStreamNative = Int32 Function(
    Pointer<BrotliEncoderState>,
    Int32,
    Pointer<IntPtr>,
    Pointer<Pointer<Uint8>>,
    Pointer<IntPtr>,
    Pointer<Pointer<Uint8>>,
    Pointer<IntPtr>);
typedef BrotliEncoderCompressStreamDart = int Function(
    Pointer<BrotliEncoderState>,
    int,
    Pointer<IntPtr>,
    Pointer<Pointer<Uint8>>,
    Pointer<IntPtr>,
    Pointer<Pointer<Uint8>>,
    Pointer<IntPtr>);

/// File: *encode.h*
/// BROTLI_ENC_API BrotliEncoderState* BrotliEncoderCreateInstance(
///     brotli_alloc_func alloc_func, brotli_free_func free_func, void* opaque);
typedef BrotliEncoderCreateInstanceNative = Pointer<BrotliEncoderState>
    Function(Pointer<Void>, Pointer<Void>, Pointer<Void>);
typedef BrotliEncoderCreateInstanceDart = Pointer<BrotliEncoderState> Function(
    Pointer<Void>, Pointer<Void>, Pointer<Void>);

/// File: *encode.h*
/// BROTLI_ENC_API void BrotliEncoderDestroyInstance(BrotliEncoderState* state);
typedef BrotliEncoderDestroyInstanceNative = Void Function(
    Pointer<BrotliEncoderState>);
typedef BrotliEncoderDestroyInstanceDart = void Function(
    Pointer<BrotliEncoderState>);

typedef BrotliEncoderHasMoreOutputNative = Int32 Function(Pointer<Void>);
typedef BrotliEncoderHasMoreOutputDart = int Function(Pointer<Void>);

/// File: *encode.h*
/// BROTLI_ENC_API BROTLI_BOOL
/// BrotliEncoderIsFinished(BrotliEncoderState* state);
typedef BrotliEncoderIsFinishedNative = Int32 Function(
    Pointer<BrotliEncoderState>);
typedef BrotliEncoderIsFinishedDart = int Function(Pointer<BrotliEncoderState>);

/// File: *encode.h*
/// BROTLI_ENC_API size_t BrotliEncoderMaxCompressedSize(size_t input_size);
typedef BrotliEncoderMaxCompressedSizeNative = IntPtr Function(IntPtr);
typedef BrotliEncoderMaxCompressedSizeDart = int Function(int);

/// File: *encode.h*
/// BROTLI_ENC_API BROTLI_BOOL BrotliEncoderSetParameter(
///     BrotliEncoderState* state, BrotliEncoderParameter param, uint32_t value)
typedef BrotliEncoderSetParameterNative = Int32 Function(
    Pointer<BrotliEncoderState>, Int32, Uint32);
typedef BrotliEncoderSetParameterDart = int Function(
    Pointer<BrotliEncoderState>, int, int);

/// File: *encode.h*
/// BROTLI_ENC_API const uint8_t* BrotliEncoderTakeOutput(
///     BrotliEncoderState* state, size_t* size);
typedef BrotliEncoderTakeOutputNative = Pointer<Uint8> Function(
    Pointer<BrotliEncoderState>, Pointer<IntPtr>);
typedef BrotliEncoderTakeOutputDart = Pointer<Uint8> Function(
    Pointer<BrotliEncoderState>, Pointer<IntPtr>);

/// File: *encode.h*
/// BROTLI_ENC_API uint32_t BrotliEncoderVersion(void);
typedef BrotliEncoderVersionNative = Uint32 Function();
typedef BrotliEncoderVersionDart = int Function();

/// Contains required functions referenced by the following header files:
/// *decode.h*, *encode.h*
mixin BrotliFunctions {
  BrotliDecoderCreateInstanceDart brotliDecoderCreateInstance;
  BrotliDecoderDecompressDart brotliDecoderDecompress;
  BrotliDecoderDecompressStreamDart brotliDecoderDecompressStream;
  BrotliDecoderDestroyInstanceDart brotliDecoderDestroyInstance;
  BrotliDecoderErrorStringDart brotliDecoderErrorString;
  BrotliDecoderGetErrorCodeDart brotliDecoderGetErrorCode;
  BrotliDecoderHasMoreOutputDart brotliDecoderHasMoreOutput;
  BrotliDecoderIsFinishedDart brotliDecoderIsFinished;
  BrotliDecoderIsUsedDart brotliDecoderIsUsed;
  BrotliDecoderSetParameterDart brotliDecoderSetParameter;
  BrotliDecoderTakeOutputDart brotliDecoderTakeOutput;
  BrotliDecoderVersionDart brotliDecoderVersion;
  BrotliEncoderCompressDart brotliEncoderCompress;
  BrotliEncoderCompressStreamDart brotliEncoderCompressStream;
  BrotliEncoderCreateInstanceDart brotliEncoderCreateInstance;
  BrotliEncoderDestroyInstanceDart brotliEncoderDestroyInstance;
  BrotliEncoderHasMoreOutputDart brotliEncoderHasMoreOutput;
  BrotliEncoderIsFinishedDart brotliEncoderIsFinished;
  BrotliEncoderMaxCompressedSizeDart brotliEncoderMaxCompressedSize;
  BrotliEncoderSetParameterDart brotliEncoderSetParameter;
  BrotliEncoderTakeOutputDart brotliEncoderTakeOutput;
  BrotliEncoderVersionDart brotliEncoderVersion;

  /// Resolve all functions using the [library]
  void resolveFunctions(DynamicLibrary library) {
    brotliDecoderCreateInstance = library.lookupFunction<
        BrotliDecoderCreateInstanceNative,
        BrotliDecoderCreateInstanceDart>('BrotliDecoderCreateInstance');

    brotliDecoderDecompress = library.lookupFunction<
        BrotliDecoderDecompressNative,
        BrotliDecoderDecompressDart>('BrotliDecoderDecompress');

    brotliDecoderDecompressStream = library.lookupFunction<
        BrotliDecoderDecompressStreamNative,
        BrotliDecoderDecompressStreamDart>('BrotliDecoderDecompressStream');

    brotliDecoderDestroyInstance = library.lookupFunction<
        BrotliDecoderDestroyInstanceNative,
        BrotliDecoderDestroyInstanceDart>('BrotliDecoderDestroyInstance');

    brotliDecoderErrorString = library.lookupFunction<
        BrotliDecoderErrorStringNative,
        BrotliDecoderErrorStringDart>('BrotliDecoderErrorString');

    brotliDecoderGetErrorCode = library.lookupFunction<
        BrotliDecoderGetErrorCodeNative,
        BrotliDecoderGetErrorCodeDart>('BrotliDecoderGetErrorCode');

    brotliDecoderHasMoreOutput = library.lookupFunction<
        BrotliDecoderHasMoreOutputNative,
        BrotliDecoderHasMoreOutputDart>('BrotliDecoderHasMoreOutput');

    brotliDecoderIsFinished = library.lookupFunction<
        BrotliDecoderIsFinishedNative,
        BrotliDecoderIsFinishedDart>('BrotliDecoderIsFinished');

    brotliDecoderIsUsed = library.lookupFunction<BrotliDecoderIsUsedNative,
        BrotliDecoderIsUsedDart>('BrotliDecoderIsUsed');

    brotliDecoderSetParameter = library.lookupFunction<
        BrotliDecoderSetParameterNative,
        BrotliDecoderSetParameterDart>('BrotliDecoderSetParameter');

    brotliDecoderTakeOutput = library.lookupFunction<
        BrotliDecoderTakeOutputNative,
        BrotliDecoderTakeOutputDart>('BrotliDecoderTakeOutput');

    brotliDecoderVersion = library.lookupFunction<BrotliDecoderVersionNative,
        BrotliDecoderVersionDart>('BrotliDecoderVersion');

    brotliEncoderCompress = library.lookupFunction<BrotliEncoderCompressNative,
        BrotliEncoderCompressDart>('BrotliEncoderCompress');

    brotliEncoderCompressStream = library.lookupFunction<
        BrotliEncoderCompressStreamNative,
        BrotliEncoderCompressStreamDart>('BrotliEncoderCompressStream');

    brotliEncoderCreateInstance = library.lookupFunction<
        BrotliEncoderCreateInstanceNative,
        BrotliEncoderCreateInstanceDart>('BrotliEncoderCreateInstance');

    brotliEncoderDestroyInstance = library.lookupFunction<
        BrotliEncoderDestroyInstanceNative,
        BrotliEncoderDestroyInstanceDart>('BrotliEncoderDestroyInstance');

    brotliEncoderHasMoreOutput = library.lookupFunction<
        BrotliEncoderHasMoreOutputNative,
        BrotliEncoderHasMoreOutputDart>('BrotliEncoderHasMoreOutput');

    brotliEncoderIsFinished = library.lookupFunction<
        BrotliEncoderIsFinishedNative,
        BrotliEncoderIsFinishedDart>('BrotliEncoderIsFinished');

    brotliEncoderMaxCompressedSize = library.lookupFunction<
        BrotliEncoderMaxCompressedSizeNative,
        BrotliEncoderMaxCompressedSizeDart>('BrotliEncoderMaxCompressedSize');

    brotliEncoderSetParameter = library.lookupFunction<
        BrotliEncoderSetParameterNative,
        BrotliEncoderSetParameterDart>('BrotliEncoderSetParameter');

    brotliEncoderTakeOutput = library.lookupFunction<
        BrotliEncoderTakeOutputNative,
        BrotliEncoderTakeOutputDart>('BrotliEncoderTakeOutput');

    brotliEncoderVersion = library.lookupFunction<BrotliEncoderVersionNative,
        BrotliEncoderVersionDart>('BrotliEncoderVersion');
  }
}
