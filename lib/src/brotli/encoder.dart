// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:ffi';
import 'dart:math';

import '../framework/buffers.dart';
import '../framework/converters.dart';
import '../framework/filters.dart';
import '../framework/sinks.dart';
import '../framework/native/buffers.dart';

import 'ffi/constants.dart';
import 'ffi/dispatcher.dart';
import 'ffi/types.dart';

import 'options.dart';

/// Default input buffer length
const defaultInputBufferLength = 64 * 1024;

/// Default output buffer length
const defaultOutputBufferLength = 64 * 1024;

/// The [BrotliEncoder] encoder is used by [BrotliCodec] to brotli compress data.
class BrotliEncoder extends CodecConverter {
  /// The compression-[level] or quality can be set in the range of
  /// [BrotliOption.minLevel]..[BrotliOption.maxLevel].
  /// The higher the level, the slower the compression.
  /// Default: [BrotliOption.defaultLevel]
  final int level;

  /// Tune the encoder for a specific input.
  /// The allowable values are:
  /// [BrotliOption.fontMode], [BrotliOption.genericMode],
  /// [BrotliOption.textMode], [BrotliOption.defaultMode].
  /// Default: [BrotliOption.defaultMode].
  final int mode;

  /// Recommended sliding LZ77 windows bit size.
  /// The encoder may reduce this value if the input is much smaller than the
  /// windows size.
  /// Range: [BrotliOption.minWindowBits]..[BrotliOption.maxWindowBits]
  /// Default: [BrotliOption.defaultWindowBits].
  final int windowBits;

  /// Recommended input block size.
  /// Encoder may reduce this value, e.g. if the input is much smalltalk than
  /// the input block size.
  /// Range: [BrotliOption.minBlockBits]..[BrotliOption.maxBlockBits].
  /// Default: nil (dynamically computed).
  final int blockBits;

  /// Recommended number of postfix bits.
  /// Encode may change this value.
  /// Range: [BrotliOption.minPostfixBits]..[BrotliOption.maxPostfixBits]
  final int postfixBits;

  /// Flag that affects usage of "literal context modeling" format feature.
  /// This flag is a "decoding-speed vs compression ratio" trade-off.
  /// Default: [:true:]
  final bool literalContextModeling;

  /// Estimated total input size for all encoding compress stream calls.
  /// Default: 0 (means the total input size if unknown).
  final int sizeHint;

  /// Flag that determines if "Large Window Brotli" is ued.
  /// If set to [:true:], then the LZ-Window can be set up to 30-bits but the
  /// result will not be RFC7932 compliant.
  /// Default: [:false:]
  final bool largeWindow;

  /// Recommended number of direct distance codes.
  /// Encoder may change this value.
  final int directDistanceCodeCount;

  /// Length in bytes of the buffer used for input data.
  final int inputBufferLength;

  /// Length in bytes of the buffer used for processed output data.
  final int outputBufferLength;

  /// Construct an [BrotliEncoder] with the supplied parameters used by the Brotli
  /// encoder.
  ///
  /// Validation will be performed which may result in a [RangeError] or
  /// [ArgumentError]
  BrotliEncoder(
      {this.level = BrotliOption.defaultLevel,
      this.mode = BrotliOption.defaultMode,
      this.windowBits = BrotliOption.defaultWindowBits,
      this.blockBits,
      this.postfixBits,
      this.literalContextModeling = true,
      this.sizeHint = 0,
      this.largeWindow = false,
      this.directDistanceCodeCount,
      this.inputBufferLength = CodecBufferHolder.autoLength,
      this.outputBufferLength = CodecBufferHolder.autoLength}) {
    validateBrotliLevel(level);
  }

  /// Start a chunked conversion using the options given to the [BrotliEncoder]
  /// constructor. While it accepts any [Sink] taking [List]'s,
  /// the optimal sink to be passed as [sink] is a [ByteConversionSink].
  @override
  ByteConversionSink startChunkedConversion(Sink<List<int>> sink) {
    final byteSink = asByteSink(sink);
    return _BrotliEncoderSink._(
        byteSink,
        level,
        mode,
        windowBits,
        blockBits,
        postfixBits,
        literalContextModeling,
        sizeHint,
        largeWindow,
        directDistanceCodeCount,
        inputBufferLength,
        outputBufferLength);
  }
}

class _BrotliEncoderSink extends CodecSink {
  _BrotliEncoderSink._(
      ByteConversionSink sink,
      int level,
      int mode,
      int windowBits,
      int blockBits,
      int postfixBits,
      bool literalContextModeling,
      int sizeHint,
      bool largeWindow,
      int directDistanceCodeCount,
      int inputBufferLength,
      int outputBufferLength)
      : super(
            sink,
            _makeBrotliCompressFilter(
                level,
                mode,
                windowBits,
                blockBits,
                postfixBits,
                literalContextModeling,
                sizeHint,
                largeWindow,
                directDistanceCodeCount,
                inputBufferLength,
                outputBufferLength));
}

/// This filter contains the implementation details for the usage of the native
/// brotli API bindings.
class _BrotliCompressFilter extends CodecFilter<Pointer<Uint8>,
    NativeCodecBuffer, _BrotliEncodingResult> {
  /// Dispatcher to make calls via FFI to brotli shared library
  final BrotliDispatcher _dispatcher = BrotliDispatcher();

  final List<int> parameters = List<int>(10);

  /// Native brotli context object
  BrotliEncoderState _state;

  _BrotliCompressFilter(
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

  @override
  CodecBufferHolder<Pointer<Uint8>, NativeCodecBuffer> newBufferHolder(
      int length) {
    final holder = CodecBufferHolder<Pointer<Uint8>, NativeCodecBuffer>(length);
    return holder..bufferBuilderFunc = (length) => NativeCodecBuffer(length);
  }

  /// Init the filter
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
      inputBufferHolder.length = defaultInputBufferLength;
    }

    // Formula from 'BROTLI_CStreamOutSize'
    final outputLength = defaultOutputBufferLength;
    outputBufferHolder.length = outputBufferHolder.isLengthSet()
        ? max(outputBufferHolder.length, outputLength)
        : outputLength;

    return 0;
  }

  /// Brotli flush implementation.
  ///
  /// Return the number of bytes flushed.
  @override
  int doFlush(NativeCodecBuffer outputBuffer) {
    final result = _dispatcher.callBrotliEncoderCompressStream(
        _state,
        BrotliConstants.BROTLI_OPERATION_FLUSH,
        0,
        nullptr,
        outputBuffer.unwrittenCount,
        outputBuffer.writePtr);
    final written = result[1];
    return written;
  }

  /// Perform an brotli encoding of [inputBuffer.unreadCount] bytes in
  /// and put the resulting encoded bytes into [outputBuffer] of length
  /// [outputBuffer.unwrittenCount].
  ///
  /// Return an [_BrotliEncodingResult] which describes the amount read/write
  @override
  _BrotliEncodingResult doProcessing(
      NativeCodecBuffer inputBuffer, NativeCodecBuffer outputBuffer) {
    final result = _dispatcher.callBrotliEncoderCompressStream(
        _state,
        BrotliConstants.BROTLI_OPERATION_PROCESS,
        inputBuffer.unreadCount,
        inputBuffer.readPtr,
        outputBuffer.unwrittenCount,
        outputBuffer.writePtr);
    final read = result[0];
    final written = result[1];
    return _BrotliEncodingResult(read, written);
  }

  /// Brotli finalize implementation.
  ///
  /// A [StateError] is thrown if writing out the brotli end stream fails.
  @override
  int doFinalize(NativeCodecBuffer outputBuffer) {
    final result = _dispatcher.callBrotliEncoderCompressStream(
        _state,
        BrotliConstants.BROTLI_OPERATION_FINISH,
        0,
        nullptr,
        outputBuffer.unwrittenCount,
        outputBuffer.writePtr);
    state = CodecFilterState.finalized;
    final written = result[1];
    return written;
  }

  /// Release brotli resources
  @override
  void doClose() {
    _destroyState();
    _releaseDispatcher();
  }

  /// Apply the parameter value to the encoder.
  void _applyParameter(int parameter) {
    final value = parameters[parameter];
    if (value != null) {
      _dispatcher.callBrotliEncoderSetParameter(_state, parameter, value);
    }
  }

  /// Allocate and initialize the native brotli compression context
  ///
  /// A [StateError] is thrown if the compression context could not be
  /// allocated.
  void _initState() {
    final result = _dispatcher.callBrotliEncoderCreateInstance();
    if (result == nullptr) {
      throw StateError('Could not allocate brotli encoder state');
    }
    _state = result.ref;
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

  /// Free the native context
  ///
  /// A [StateError] is thrown if the context is invalid and can not be freed
  void _destroyState() {
    if (_state != null) {
      try {
        _dispatcher.callBrotliEncoderDestroyInstance(_state);
      } finally {
        _state = null;
      }
    }
  }

  /// Release the Brotli FFI call dispatcher
  void _releaseDispatcher() {
    _dispatcher.release();
  }
}

/// Construct a new brotli filter which is configured with the options
/// provided
CodecFilter _makeBrotliCompressFilter(
    int level,
    int mode,
    int windowBits,
    int blockBits,
    int postfixBits,
    bool literalContextModeling,
    int sizeHint,
    bool largeWindow,
    int directDistanceCodeCount,
    int inputBufferLength,
    int outputBufferLength) {
  return _BrotliCompressFilter(
      level: level,
      mode: mode,
      windowBits: windowBits,
      blockBits: blockBits,
      postfixBits: postfixBits,
      literalContextModeling: literalContextModeling,
      sizeHint: sizeHint,
      largeWindow: largeWindow,
      directDistanceCodeCount: directDistanceCodeCount,
      inputBufferLength: inputBufferLength,
      outputBufferLength: outputBufferLength);
}

/// Result object for an Brotli Encoding operation
class _BrotliEncodingResult extends CodecResult {
  const _BrotliEncodingResult(int bytesRead, int bytesWritten)
      : super(bytesRead, bytesWritten);
}
