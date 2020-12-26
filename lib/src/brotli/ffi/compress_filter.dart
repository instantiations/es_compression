// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:math';

import '../../../brotli.dart';
import '../../../framework.dart';
import '../../framework/native/buffers.dart';
import '../../framework/native/filters.dart';
import 'constants.dart';
import 'dispatcher.dart';
import 'types.dart';

/// A [BrotliCompressFilter] is an FFI-based [CodecFilter] that implements the
/// brotli compression algorithm.
class BrotliCompressFilter extends NativeCodecFilterBase {
  /// Dispatcher to make calls via FFI to brotli shared library.
  final BrotliDispatcher _dispatcher = BrotliDispatcher();

  /// Option holder.
  final List<int> parameters = List.filled(10, 0);

  /// Native brotli context object.
  BrotliEncoderState _brotliState;

  /// Construct an [BrotliCompressFilter] with the provided options.
  BrotliCompressFilter(
      {int level,
      int mode,
      int windowBits,
      int blockBits,
      int postfixBits,
      bool literalContextModeling,
      int sizeHint,
      bool largeWindow,
      int directDistanceCodeCount,
      int inputBufferLength,
      int outputBufferLength})
      : super(
            inputBufferLength: inputBufferLength,
            outputBufferLength: outputBufferLength) {
    parameters[BrotliConstants.BROTLI_PARAM_MODE] = mode;
    parameters[BrotliConstants.BROTLI_PARAM_QUALITY] = level;
    parameters[BrotliConstants.BROTLI_PARAM_LGWIN] = windowBits;
    parameters[BrotliConstants.BROTLI_PARAM_LGBLOCK] = blockBits;
    parameters[BrotliConstants.BROTLI_PARAM_DISABLE_LITERAL_CONTEXT_MODELING] =
        literalContextModeling == false
            ? BrotliConstants.BROTLI_TRUE
            : BrotliConstants.BROTLI_FALSE;
    parameters[BrotliConstants.BROTLI_PARAM_SIZE_HINT] = sizeHint;
    parameters[BrotliConstants.BROTLI_PARAM_LARGE_WINDOW] = largeWindow == true
        ? BrotliConstants.BROTLI_TRUE
        : BrotliConstants.BROTLI_FALSE;
    parameters[BrotliConstants.BROTLI_PARAM_NPOSTFIX] = postfixBits;
    parameters[BrotliConstants.BROTLI_PARAM_NDIRECT] = directDistanceCodeCount;
  }

  /// Init the filter.
  ///
  /// Provide appropriate buffer lengths to codec builders
  /// [inputBufferHolder.length] decoding buffer length and
  /// [outputBufferHolder.length] encoding buffer length.
  @override
  int doInit(
      CodecBufferHolder<Pointer<Uint8>, NativeCodecBuffer> inputBufferHolder,
      CodecBufferHolder<Pointer<Uint8>, NativeCodecBuffer> outputBufferHolder,
      List<int> bytes,
      int start,
      int end) {
    _initState();

    if (!inputBufferHolder.isLengthSet()) {
      inputBufferHolder.length = brotliEncoderInputBufferLength;
    }

    // Formula from 'BROTLI_CStreamOutSize'
    final outputLength = brotliEncoderOutputBufferLength;
    outputBufferHolder.length = outputBufferHolder.isLengthSet()
        ? max(outputBufferHolder.length, outputLength)
        : outputLength;

    return 0;
  }

  /// Perform an brotli encoding of [inputBuffer.unreadCount] bytes in
  /// and put the resulting encoded bytes into [outputBuffer] of length
  /// [outputBuffer.unwrittenCount].
  ///
  /// Return an [CodecResult] which describes the amount read/write.
  @override
  CodecResult doProcessing(
      NativeCodecBuffer inputBuffer, NativeCodecBuffer outputBuffer) {
    final result = _dispatcher.callBrotliEncoderCompressStream(
        _brotliState,
        BrotliConstants.BROTLI_OPERATION_PROCESS,
        inputBuffer.unreadCount,
        inputBuffer.readPtr,
        outputBuffer.unwrittenCount,
        outputBuffer.writePtr);
    final read = result[0];
    final written = result[1];
    return CodecResult(read, written);
  }

  /// Brotli flush implementation.
  ///
  /// Return the number of bytes flushed.
  @override
  int doFlush(NativeCodecBuffer outputBuffer) {
    if (_dispatcher.callBrotliEncoderIsFinished(_brotliState)) return 0;
    final result = _dispatcher.callBrotliEncoderCompressStream(
        _brotliState,
        BrotliConstants.BROTLI_OPERATION_FLUSH,
        0,
        nullptr,
        outputBuffer.unwrittenCount,
        outputBuffer.writePtr);
    final written = result[1];
    return written;
  }

  /// Brotli finalize implementation.
  ///
  /// A [FormatException] is thrown if writing out the brotli end stream fails.
  @override
  int doFinalize(NativeCodecBuffer outputBuffer) {
    if (_dispatcher.callBrotliEncoderIsFinished(_brotliState)) return 0;
    final result = _dispatcher.callBrotliEncoderCompressStream(
        _brotliState,
        BrotliConstants.BROTLI_OPERATION_FINISH,
        0,
        nullptr,
        outputBuffer.unwrittenCount,
        outputBuffer.writePtr);
    if (!_dispatcher.callBrotliEncoderIsFinished(_brotliState)) {
      throw FormatException('Failure to finish the stream');
    }
    state = CodecFilterState.finalized;
    final written = result[1];
    return written;
  }

  /// Release brotli resources.
  @override
  void doClose() {
    _destroyState();
    _releaseDispatcher();
  }

  /// Apply the parameter value to the encoder.
  void _applyParameter(int parameter) {
    final value = parameters[parameter];
    if (value != null) {
      _dispatcher.callBrotliEncoderSetParameter(_brotliState, parameter, value);
    }
  }

  /// Allocate and initialize the native brotli encoder state
  ///
  /// A [StateError] is thrown if the encoder state could not be allocated.
  void _initState() {
    final result = _dispatcher.callBrotliEncoderCreateInstance();
    if (result == nullptr) {
      throw StateError('Could not allocate brotli encoder state');
    }
    _brotliState = result.ref;
    _applyParameter(BrotliConstants.BROTLI_PARAM_QUALITY);
    _applyParameter(BrotliConstants.BROTLI_PARAM_MODE);
    _applyParameter(BrotliConstants.BROTLI_PARAM_LGWIN);
    _applyParameter(BrotliConstants.BROTLI_PARAM_LARGE_WINDOW);
    _applyParameter(BrotliConstants.BROTLI_PARAM_LGBLOCK);
    _applyParameter(
        BrotliConstants.BROTLI_PARAM_DISABLE_LITERAL_CONTEXT_MODELING);
    _applyParameter(BrotliConstants.BROTLI_PARAM_NDIRECT);
    _applyParameter(BrotliConstants.BROTLI_PARAM_NPOSTFIX);
    _applyParameter(BrotliConstants.BROTLI_PARAM_SIZE_HINT);
  }

  /// Free the native context.
  void _destroyState() {
    if (_brotliState != null) {
      try {
        _dispatcher.callBrotliEncoderDestroyInstance(_brotliState);
      } finally {
        _brotliState = null;
      }
    }
  }

  /// Release the Brotli FFI call dispatcher.
  void _releaseDispatcher() {
    _dispatcher.release();
  }
}
