// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:ffi';
import 'dart:math';

import '../framework/buffers.dart';
import '../framework/converters.dart';
import '../framework/filters.dart';
import '../framework/native/buffers.dart';
import '../framework/native/filters.dart';
import '../framework/sinks.dart';
import 'ffi/constants.dart';
import 'ffi/dispatcher.dart';
import 'ffi/types.dart';
import 'options.dart';

/// Default input buffer length
const _defaultInputBufferLength = ZstdConstants.ZSTD_BLOCKSIZE_MAX;

/// Default output buffer length
const _defaultOutputBufferLength = CodecBufferHolder.autoLength;

/// The [ZstdEncoder] encoder is used by [ZstdCodec] to zstd compress data.
class ZstdEncoder extends CodecConverter {
  /// The compression-[level] can be set in the range of
  /// `-[ZstdConstants.ZSTD_TARGETLENGTH_MAX]..22`,
  /// with [ZstdOption.defaultLevel] being the default compression level.
  final int level;

  /// Length in bytes of the buffer used for input data.
  final int inputBufferLength;

  /// Length in bytes of the buffer used for processed output data.
  final int outputBufferLength;

  /// Construct an [ZstdEncoder] with the supplied parameters used by the Zstd
  /// encoder.
  ///
  /// Validation will be performed which may result in a [RangeError] or
  /// [ArgumentError]
  ZstdEncoder(
      {this.level = ZstdOption.defaultLevel,
      this.inputBufferLength = _defaultInputBufferLength,
      this.outputBufferLength = _defaultOutputBufferLength}) {
    validateZstdLevel(level);
  }

  /// Start a chunked conversion using the options given to the [ZstdEncoder]
  /// constructor. While it accepts any [Sink] taking [List]'s,
  /// the optimal sink to be passed as [sink] is a [ByteConversionSink].
  @override
  ByteConversionSink startChunkedConversion(Sink<List<int>> sink) {
    final byteSink = asByteSink(sink);
    return _ZstdEncoderSink._(
        byteSink, level, inputBufferLength, outputBufferLength);
  }
}

/// Zstd encoding sink internal implementation.
class _ZstdEncoderSink extends CodecSink {
  _ZstdEncoderSink._(ByteConversionSink sink, int level, int inputBufferLength,
      int outputBufferLength)
      : super(
            sink,
            _makeZstdCompressFilter(
                level, inputBufferLength, outputBufferLength));
}

/// This filter contains the implementation details for the usage of the native
/// zstd API bindings.
class _ZstdCompressFilter extends NativeCodecFilterBase {
  /// Dispatcher to make calls via FFI to zstd shared library
  final ZstdDispatcher _dispatcher = ZstdDispatcher();

  /// Compression level
  final int level;

  /// Native zstd context object
  ZstdCStream _cStream;

  /// Construct the [_ZstdCompressFilter] with the optional parameters.
  _ZstdCompressFilter(
      {this.level, int inputBufferLength, int outputBufferLength})
      : super(
            inputBufferLength: inputBufferLength,
            outputBufferLength: outputBufferLength);

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
    _initCStream();

    if (!inputBufferHolder.isLengthSet()) {
      inputBufferHolder.length = _dispatcher.callZstdCStreamInSize();
    }

    // Formula from 'ZSTD_CStreamOutSize'
    final outputLength = _zstdCompressBound(inputBufferHolder.length);
    outputBufferHolder.length = outputBufferHolder.isLengthSet()
        ? max(outputBufferHolder.length, outputLength)
        : outputLength;

    return 0;
  }

  /// Zstd flush implementation.
  ///
  /// Return the number of bytes flushed.
  @override
  int doFlush(NativeCodecBuffer outputBuffer) {
    return _dispatcher.callZstdFlushStream(
        _cStream, outputBuffer.writePtr, outputBuffer.unwrittenCount);
  }

  /// Perform an zstd encoding of [inputBuffer.unreadCount] bytes in
  /// and put the resulting encoded bytes into [outputBuffer] of length
  /// [outputBuffer.unwrittenCount].
  ///
  /// Return an [_ZstdEncodingResult] which describes the amount read/write
  @override
  CodecResult doProcessing(
      NativeCodecBuffer inputBuffer, NativeCodecBuffer outputBuffer) {
    final result = _dispatcher.callZstdCompressStream(
        _cStream,
        outputBuffer.writePtr,
        outputBuffer.unwrittenCount,
        inputBuffer.readPtr,
        inputBuffer.unreadCount);
    final read = result[0];
    final written = result[1];
    final hint = result[2];
    return _ZstdEncodingResult(read, written, hint);
  }

  /// Zstd finalize implementation.
  ///
  /// A [FormatException] is thrown if writing out the zstd end stream fails.
  @override
  int doFinalize(NativeCodecBuffer outputBuffer) {
    final numBytes = _dispatcher.callZstdEndStream(
        _cStream, outputBuffer.writePtr, outputBuffer.unwrittenCount);
    state = CodecFilterState.finalized;
    return numBytes;
  }

  /// Release zstd resources
  @override
  void doClose() {
    _destroyCStream();
    _releaseDispatcher();
  }

  /// Allocate and initialize the native zstd compression context
  ///
  /// A [StateError] is thrown if the compression context could not be
  /// allocated.
  void _initCStream() {
    final result = _dispatcher.callZstdCreateCStream();
    if (result == nullptr) throw StateError('Could not allocate zstd context');
    _cStream = result.ref;
    _dispatcher.callZstdInitCStream(_cStream, level);
  }

  /// Return the maximum compressed size in worst case single-pass scenario.
  int _zstdCompressBound(int uncompressedLength) =>
      _dispatcher.callZstdCompressBound(uncompressedLength);

  /// Free the native context
  ///
  /// A [FormatException] is thrown if the context is invalid and can not be
  /// freed
  void _destroyCStream() {
    if (_cStream != null) {
      try {
        _dispatcher.callZstdFreeCStream(_cStream);
      } finally {
        _cStream = null;
      }
    }
  }

  /// Release the Zstd FFI call dispatcher
  void _releaseDispatcher() {
    _dispatcher.release();
  }
}

/// Construct a new zstd filter which is configured with the options
/// provided
CodecFilter _makeZstdCompressFilter(
    int level, int inputBufferLength, int outputBufferLength) {
  return _ZstdCompressFilter(
      level: level,
      inputBufferLength: inputBufferLength,
      outputBufferLength: outputBufferLength);
}

/// Result object for an Zstd Encoding operation
class _ZstdEncodingResult extends CodecResult {
  /// The hint for the next read size.
  final int hint;

  const _ZstdEncodingResult(int bytesRead, int bytesWritten, this.hint)
      : super(bytesRead, bytesWritten);
}
