// Copyright (c) 2020, Seth Berman (Instantiations, Inc). Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:es_compression/src/brotli/ffi/types.dart';
import 'package:ffi/ffi.dart' as ffi;

import 'constants.dart';
import 'library.dart';

// ignore_for_file: public_member_api_docs
class BrotliDispatcher with BrotliDispatchErrorCheckerMixin {
  static final BrotliDispatcher _instance = BrotliDispatcher._();

  /// Library accessor to the Brotli shared lib.
  BrotliLibrary library;

  int encoderVersionNumber;

  int decoderVersionNumber;

  // These are used in codec routines to cut down on alloc/free
  final Pointer<Pointer<Uint8>> nextInPtr = ffi.allocate<Pointer<Uint8>>();
  final Pointer<Pointer<Uint8>> nextOutPtr = ffi.allocate<Pointer<Uint8>>();
  final Pointer<IntPtr> availableInPtr = ffi.allocate<IntPtr>();
  final Pointer<IntPtr> availableOutPtr = ffi.allocate<IntPtr>();
  final Pointer<IntPtr> bufferLengthPtr = ffi.allocate<IntPtr>();

  /// Return the [BrotliDispatcher] singleton instance
  factory BrotliDispatcher() {
    return _instance;
  }

  BrotliDispatcher._() {
    library = BrotliLibrary();
    encoderVersionNumber = callBrotliEncoderVersion();
    decoderVersionNumber = callBrotliDecoderVersion();
  }

  /// Release any temporary resources.
  ///
  /// The [BrotliDispatcher] is a singleton instance, so care must be taken in
  /// what resources will be released.
  void release() {}

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
          throw StateError(
              'BrotliEncoderCompressStream failure while finishing the stream');
        case BrotliConstants.BROTLI_OPERATION_FLUSH:
          throw StateError(
              'BrotliEncoderCompressStream failure while flushing the stream');
        case BrotliConstants.BROTLI_OPERATION_PROCESS:
          throw StateError(
              'BrotliEncoderCompressStream failure while processing the stream');
        default:
          throw StateError('BrotliEncoderCompressStream failure');
      }
    }
  }

  bool callBrotliEncoderIsFinished(BrotliEncoderState state) {
    return library.brotliEncoderIsFinished(state.addressOf) ==
        BrotliConstants.BROTLI_TRUE;
  }

  List<int> callBrotliDecoderDecompressStream(
      BrotliDecoderState state,
      int availableIn,
      Pointer<Uint8> nextIn,
      int availableOut,
      Pointer<Uint8> nextOut) {
    nextInPtr.value = nextIn;
    availableInPtr.value = availableIn;
    nextOutPtr.value = nextOut;
    availableOutPtr.value = availableOut;

    final result = library.brotliDecoderDecompressStream(state.addressOf,
        availableInPtr, nextInPtr, availableOutPtr, nextOutPtr, nullptr);
    if (result == BrotliConstants.BROTLI_DECODER_RESULT_ERROR) {
      throw StateError('BrotliDecoderDecompressStream');
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
      throw StateError('BrotliDecoderSetParameter failed');
    }
  }

  void callBrotliEncoderSetParameter(
      BrotliEncoderState state, int param, int value) {
    final ret =
        library.brotliEncoderSetParameter(state.addressOf, param, value);
    if (ret == BrotliConstants.BROTLI_FALSE) {
      throw StateError('BrotliEncoderSetParameter failed');
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
  /// Dispatcher to make calls via FFI to zstd shared library
  BrotliDispatcher get dispatcher;

  /// This function wraps brotli calls and throws a [StateError] if [code]
  /// is an error code.
  int checkDecoderError(BrotliDecoderState state, int code) {
    if (code == BrotliConstants.BROTLI_DECODER_RESULT_ERROR) {
      final errorCode = dispatcher.callBrotliDecoderGetErrorCode(state);
      final errorNamePtr = dispatcher.callBrotliDecoderErrorString(errorCode);
      final errorName = ffi.Utf8.fromUtf8(errorNamePtr);
      throw StateError(errorName);
    } else {
      return code;
    }
  }
}
