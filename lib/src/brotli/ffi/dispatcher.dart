// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart' as ffi;

import 'constants.dart';
import 'library.dart';
import 'types.dart';

// ignore_for_file: public_member_api_docs

/// The [BrotliDispatcher] prepares arguments intended for FFI calls and
/// instructs the [BrotliLibrary] which native call to make.
///
/// Impl: To cut down on FFI malloc/free and native heap fragmentation, the
/// native pointers for brotli compress/decompress functions are pre-allocated.
class BrotliDispatcher with BrotliDispatchErrorCheckerMixin {
  /// Answer the encoder version number of the library.
  static int get encoderVersionNumber {
    try {
      final dispatcher = BrotliDispatcher();
      final versionNumber = dispatcher._encoderVersionNumber;
      dispatcher.release();
      return versionNumber;
    } on Exception {
      return 0;
    }
  }

  /// Answer the decoder version number of the library.
  static int get decoderVersionNumber {
    try {
      final dispatcher = BrotliDispatcher();
      final versionNumber = dispatcher._decoderVersionNumber;
      dispatcher.release();
      return versionNumber;
    } on Exception {
      return 0;
    }
  }

  /// Library accessor to the Brotli shared lib.
  BrotliLibrary library;

  /// Version number of the encoder (part) of the shared library.
  int _encoderVersionNumber;

  /// Version number of the decoder (part) of the shared library.
  int _decoderVersionNumber;

  /// For safety to prevent double free.
  bool released;

  // These are used in codec routines to cut down on alloc/free
  final Pointer<Pointer<Uint8>> nextInPtr = ffi.allocate<Pointer<Uint8>>();
  final Pointer<Pointer<Uint8>> nextOutPtr = ffi.allocate<Pointer<Uint8>>();
  final Pointer<IntPtr> availableInPtr = ffi.allocate<IntPtr>();
  final Pointer<IntPtr> availableOutPtr = ffi.allocate<IntPtr>();
  final Pointer<IntPtr> bufferLengthPtr = ffi.allocate<IntPtr>();

  /// Return the [BrotliDispatcher] singleton instance
  BrotliDispatcher() {
    library = BrotliLibrary();
    _encoderVersionNumber = callBrotliEncoderVersion();
    _decoderVersionNumber = callBrotliDecoderVersion();
  }

  /// Release native resources.
  void release() {
    if (released == false) {
      ffi.free(nextInPtr);
      ffi.free(nextOutPtr);
      ffi.free(availableInPtr);
      ffi.free(availableOutPtr);
      ffi.free(bufferLengthPtr);
    }
  }

  int callBrotliEncoderVersion() => library.brotliEncoderVersion();

  int callBrotliDecoderVersion() => library.brotliDecoderVersion();

  int callBrotliDecoderGetErrorCode(BrotliDecoderState state) =>
      library.brotliDecoderGetErrorCode(state.addressOf);

  Pointer<ffi.Utf8> callBrotliDecoderErrorString(int code) =>
      library.brotliDecoderErrorString(code);

  Pointer<BrotliDecoderState> callBrotliDecoderCreateInstance() =>
      library.brotliDecoderCreateInstance(nullptr, nullptr, nullptr);

  void callBrotliDecoderDestroyInstance(BrotliDecoderState state) =>
      library.brotliDecoderDestroyInstance(state.addressOf);

  Pointer<BrotliEncoderState> callBrotliEncoderCreateInstance() =>
      library.brotliEncoderCreateInstance(nullptr, nullptr, nullptr);

  void callBrotliEncoderDestroyInstance(BrotliEncoderState state) =>
      library.brotliEncoderDestroyInstance(state.addressOf);

  int callBrotliEncoderMaxCompressedSize(int uncompressedSize) {
    return library.brotliEncoderMaxCompressedSize(uncompressedSize);
  }

  List<int> callBrotliEncoderCompressStream(
      BrotliEncoderState state,
      int op,
      int availableIn,
      Pointer<Uint8> nextIn,
      int availableOut,
      Pointer<Uint8> nextOut) {
    nextInPtr.value = nextIn;
    availableInPtr.value = availableIn;
    nextOutPtr.value = nextOut;
    availableOutPtr.value = availableOut;

    final ret = library.brotliEncoderCompressStream(state.addressOf, op,
        availableInPtr, nextInPtr, availableOutPtr, nextOutPtr, nullptr);
    _testEncoderCompressionResult(op, ret);

    return <int>[
      availableIn - availableInPtr.value,
      availableOut - availableOutPtr.value
    ];
  }

  void _testEncoderCompressionResult(int op, int ret) {
    if (ret == BrotliConstants.BROTLI_FALSE) {
      switch (op) {
        case BrotliConstants.BROTLI_OPERATION_FINISH:
          throw FormatException('BrotliEncoderCompressStream'
              'failure while finishing the stream');
        case BrotliConstants.BROTLI_OPERATION_FLUSH:
          throw FormatException('BrotliEncoderCompressStream'
              'failure while flushing the stream');
        case BrotliConstants.BROTLI_OPERATION_PROCESS:
          throw FormatException('BrotliEncoderCompressStream'
              'failure while processing the stream');
        default:
          throw FormatException('BrotliEncoderCompressStream'
              'failure');
      }
    }
  }

  bool callBrotliEncoderIsFinished(BrotliEncoderState state) {
    return library.brotliEncoderIsFinished(state.addressOf) ==
        BrotliConstants.BROTLI_TRUE;
  }

  bool callBrotliDecoderIsFinished(BrotliDecoderState state) {
    return library.brotliDecoderIsFinished(state.addressOf) ==
        BrotliConstants.BROTLI_TRUE;
  }

  bool callBrotliDecoderHasMoreOutput(BrotliDecoderState state) {
    return library.brotliDecoderHasMoreOutput(state.addressOf) ==
        BrotliConstants.BROTLI_TRUE;
  }

  List<int> callBrotliDecoderDecompressStream(
      BrotliDecoderState state,
      int availableIn,
      Pointer<Uint8> nextIn,
      int availableOut,
      Pointer<Uint8> nextOut) {
    const cFunctionName = 'BrotliDecoderDecompressStream';
    nextInPtr.value = nextIn;
    availableInPtr.value = availableIn;
    nextOutPtr.value = nextOut;
    availableOutPtr.value = availableOut;

    final result = library.brotliDecoderDecompressStream(state.addressOf,
        availableInPtr, nextInPtr, availableOutPtr, nextOutPtr, nullptr);

    final remainingIn = availableInPtr.value;
    switch (result) {
      case BrotliConstants.BROTLI_DECODER_RESULT_SUCCESS:
        if (remainingIn > 0) {
          throw FormatException('$cFunctionName failed. Excessive input');
        }
        break;
      case BrotliConstants.BROTLI_DECODER_RESULT_ERROR:
        throw FormatException('$cFunctionName failed. error code: '
            '${callBrotliDecoderGetErrorCode(state)}');
        break;
      case BrotliConstants.BROTLI_DECODER_RESULT_NEEDS_MORE_OUTPUT:
        break;
      case BrotliConstants.BROTLI_DECODER_NEEDS_MORE_INPUT:
        break;
    }

    return <int>[
      availableIn - availableInPtr.value,
      availableOut - availableOutPtr.value,
      result
    ];
  }

  void callBrotliDecoderSetParameter(
      BrotliDecoderState state, int param, int value) {
    final ret =
        library.brotliDecoderSetParameter(state.addressOf, param, value);
    if (ret == BrotliConstants.BROTLI_FALSE) {
      throw ArgumentError('BrotliDecoderSetParameter failed');
    }
  }

  void callBrotliEncoderSetParameter(
      BrotliEncoderState state, int param, int value) {
    final ret =
        library.brotliEncoderSetParameter(state.addressOf, param, value);
    if (ret == BrotliConstants.BROTLI_FALSE) {
      throw ArgumentError('BrotliEncoderSetParameter failed');
    }
  }

  Pointer<Uint8> callBrotliDecoderTakeOutput(
      BrotliDecoderState state, Pointer<IntPtr> size) {
    return library.brotliDecoderTakeOutput(state.addressOf, size);
  }

  Pointer<Uint8> callBrotliEncoderTakeOutput(
      BrotliEncoderState state, Pointer<IntPtr> size) {
    return library.brotliEncoderTakeOutput(state.addressOf, size);
  }

  @override
  BrotliDispatcher get dispatcher => this;
}

/// A [BrotliDispatchErrorCheckerMixin] provides error handling capability for
/// APIs in the native Brotli library.
mixin BrotliDispatchErrorCheckerMixin {
  /// Dispatcher to make calls via FFI to brotli shared library
  BrotliDispatcher get dispatcher;

  /// This function wraps brotli calls and throws a [FormatException] if [code]
  /// is an error code.
  int checkDecoderError(BrotliDecoderState state, int code) {
    if (code == BrotliConstants.BROTLI_DECODER_RESULT_ERROR) {
      final errorCode = dispatcher.callBrotliDecoderGetErrorCode(state);
      final errorNamePtr = dispatcher.callBrotliDecoderErrorString(errorCode);
      final errorName = ffi.Utf8.fromUtf8(errorNamePtr);
      throw FormatException(errorName);
    } else {
      return code;
    }
  }
}
