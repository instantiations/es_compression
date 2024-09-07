// Copyright (c) 2021, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import '../../../brotli.dart';
import '../../../framework.dart';
import '../../framework/native/buffers.dart';
import '../../framework/native/filters.dart';
import 'constants.dart';
import 'dispatcher.dart';
import 'types.dart';

/// A [BrotliDecompressFilter] is an FFI-based [CodecFilter] that implements the
/// brotli decompression algorithm.
class BrotliDecompressFilter extends NativeCodecFilterBase {
  /// Dispatcher to make calls via FFI to brotli shared library.
  final BrotliDispatcher _dispatcher = BrotliDispatcher();

  /// Option holder.
  final List<int> parameters = List.filled(5, 0);

  /// Native brotli state object.
  late final Pointer<BrotliDecoderState> _brotliState;

  /// Special Case: Empty input
  late bool _emptyInput = false;

  /// Construct an [BrotliDecompressFilter] with the supplied options.
  BrotliDecompressFilter(
      {bool ringBufferReallocation = true,
      bool largeWindow = false,
      super.inputBufferLength,
      super.outputBufferLength}) {
    parameters[BrotliConstants
            .BROTLI_DECODER_PARAM_DISABLE_RING_BUFFER_REALLOCATION] =
        ringBufferReallocation == false
            ? BrotliConstants.BROTLI_TRUE
            : BrotliConstants.BROTLI_FALSE;
    parameters[BrotliConstants.BROTLI_DECODER_PARAM_LARGE_WINDOW] =
        largeWindow == true
            ? BrotliConstants.BROTLI_TRUE
            : BrotliConstants.BROTLI_FALSE;
  }

  /// Return [:true:] if there is more data to process, [:false:] otherwise.
  @override
  bool hasMoreToProcess() =>
      super.hasMoreToProcess() ||
      _dispatcher.callBrotliDecoderHasMoreOutput(_brotliState);

  /// Init the filter.
  ///
  /// Provide appropriate buffer lengths to codec builders
  /// [inputBufferHolder] decoding buffer length and
  /// [outputBufferHolder] encoding buffer length.
  @override
  int doInit(
      CodecBufferHolder<Pointer<Uint8>, NativeCodecBuffer> inputBufferHolder,
      CodecBufferHolder<Pointer<Uint8>, NativeCodecBuffer> outputBufferHolder,
      List<int> bytes,
      int start,
      int end) {
    _initState();
    if (!inputBufferHolder.isLengthSet()) {
      inputBufferHolder.length = brotliDecoderInputBufferLength;
    }
    if (!outputBufferHolder.isLengthSet()) {
      outputBufferHolder.length = brotliDecoderOutputBufferLength;
    }
    _emptyInput = end - start <= 0;
    return 0;
  }

  /// Perform decompression.
  ///
  /// Answer an [CodecResult] that store how much was read, written and the next
  /// read state.
  @override
  CodecResult doProcessing(
      NativeCodecBuffer inputBuffer, NativeCodecBuffer outputBuffer) {
    final result = _dispatcher.callBrotliDecoderDecompressStream(
        _brotliState,
        inputBuffer.unreadCount,
        inputBuffer.readPtr,
        outputBuffer.unwrittenCount,
        outputBuffer.writePtr);
    final read = result[0];
    final written = result[1];
    final nextReadState = result[2];
    return _BrotliDecodingResult(read, written, nextReadState);
  }

  /// Brotli finalize implementation.
  ///
  /// A [FormatException] is thrown if the filter is not in the *finished*
  /// state.
  @override
  int doFinalize(CodecBuffer<dynamic> outputBuffer) {
    if (!_dispatcher.callBrotliDecoderIsFinished(_brotliState) &&
        !_emptyInput) {
      throw const FormatException('Failure to finish decoding');
    }
    return 0;
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
    _dispatcher.callBrotliDecoderSetParameter(_brotliState, parameter, value);
  }

  /// Allocate and initialize the native brotli decoder state.
  ///
  /// A [StateError] is thrown if the decoder state could not be allocated.
  void _initState() {
    final result = _dispatcher.callBrotliDecoderCreateInstance();
    if (result == nullptr) {
      throw StateError('Could not allocate brotli decoder state');
    }
    _brotliState = result;
    _applyParameter(
        BrotliConstants.BROTLI_DECODER_PARAM_DISABLE_RING_BUFFER_REALLOCATION);
    _applyParameter(BrotliConstants.BROTLI_DECODER_PARAM_LARGE_WINDOW);
  }

  /// Free the native context.
  void _destroyState() {
    _dispatcher.callBrotliDecoderDestroyInstance(_brotliState);
  }

  /// Release the Brotli FFI call dispatcher.
  void _releaseDispatcher() {
    _dispatcher.release();
  }
}

/// Result object for an Brotli Decompression operation.
class _BrotliDecodingResult extends CodecResult {
  /// Next state of the decoder.
  final int nextReadState;

  /// Return a new instance of [_BrotliDecodingResult].
  const _BrotliDecodingResult(
      super.bytesRead, super.bytesWritten, this.nextReadState);
}
