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

import 'codec.dart';
import 'options.dart';

/// Default input buffer length
const defaultInputBufferLength = 64 * 1024;

/// Default output buffer length
const defaultOutputBufferLength = CodecBufferHolder.autoLength;

/// The [Lz4Encoder] encoder is used by [Lz4Codec] to lz4 compress data.
class Lz4Encoder extends CodecConverter {
  /// The compression-[level] can be set in the range of `0..16`, with
  /// 0 (fast mode) being the default compression level.
  final int level;

  /// When true, use ultra-fast compression speed mode, at the cost of some
  /// compression ratio. The default value is false.
  final bool fastAcceleration;

  /// When true, a checksum is added to the end of a frame during compression,
  /// and checked during decompression. An enabled, all blocks are present and
  /// in the correct order. The default value is false.
  final bool contentChecksum;

  /// When true, a checksum is added to the end of each block during
  /// compression, and validates the block data during decompression.
  /// The default value is false.
  final bool blockChecksum;

  /// When true, blocks are compressed in linked mode which dramatically
  /// improves compression, specifically for small blocks.
  /// The default value is true.
  final bool blockLinked;

  /// The maximum size to use for blocks. The larger the block, the (slightly)
  /// better compression ratio. However, more memory is consumed for both
  /// compression and decompression. The default value is blockSize64KB
  final int blockSize;

  /// When true, generate compress data optimized for decompression speed.
  /// The size of the compressed data may be slightly larger, however the
  /// decompression speed should be improved.
  /// **Note: This option will be ignored if [level] < 9**
  final bool optimizeForDecompression;

  /// Length in bytes of the buffer used for input data.
  final int inputBufferLength;

  /// Length in bytes of the buffer used for processed output data.
  final int outputBufferLength;

  /// Construct an [Lz4Encoder] with the supplied parameters used by the Lz4
  /// encoder.
  ///
  /// Validation will be performed which may result in a [RangeError] or
  /// [ArgumentError]
  Lz4Encoder(
      {this.level = Lz4Option.defaultLevel,
      this.fastAcceleration = false,
      this.contentChecksum = false,
      this.blockChecksum = false,
      this.blockLinked = true,
      this.blockSize = Lz4Option.defaultBlockSize,
      this.optimizeForDecompression = false,
      this.inputBufferLength = defaultInputBufferLength,
      this.outputBufferLength = defaultOutputBufferLength}) {
    validateLz4Level(level);
    validateLz4BlockSize(blockSize);
  }

  /// Start a chunked conversion using the options given to the [Lz4Encoder]
  /// constructor. While it accepts any [Sink] taking [List<int>]'s,
  /// the optimal sink to be passed as [sink] is a [ByteConversionSink].
  @override
  ByteConversionSink startChunkedConversion(Sink<List<int>> sink) {
    final byteSink = asByteSink(sink);
    return _Lz4EncoderSink._(
        byteSink,
        level,
        fastAcceleration,
        contentChecksum,
        blockChecksum,
        blockLinked,
        blockSize,
        optimizeForDecompression,
        inputBufferLength,
        outputBufferLength);
  }
}

/// LZ4 codec sink impl
class _Lz4EncoderSink extends CodecSink {
  _Lz4EncoderSink._(
      ByteConversionSink sink,
      int level,
      bool fastAcceleration,
      bool contentChecksum,
      bool blockChecksum,
      bool blockLinked,
      int blockSize,
      bool optimizeForDecompression,
      int inputBufferLength,
      int outputBufferLength)
      : super(
            sink,
            _makeLz4CompressFilter(
                level,
                fastAcceleration,
                contentChecksum,
                blockChecksum,
                blockLinked,
                blockSize,
                optimizeForDecompression,
                inputBufferLength,
                outputBufferLength));
}

/// This filter contains the implementation details for the usage of the native
/// lz4 API bindings.
class _Lz4CompressFilter
    extends CodecFilter<Pointer<Uint8>, NativeCodecBuffer, _Lz4EncodingResult> {
  /// Dispatcher to make calls via FFI to lz4 shared library
  final Lz4Dispatcher _dispatcher = Lz4Dispatcher();

  /// FFI Struct exposed by lz4 shared lib for configuration
  Lz4Preferences _preferences;

  /// Native lz4 context
  Lz4Cctx _ctx;

  /// Native lz4 compress options
  Lz4CompressOptions _options;

  _Lz4CompressFilter(
      {int level,
      bool fastAcceleration,
      bool contentChecksum,
      bool blockChecksum,
      bool blockLinked,
      int blockSize,
      bool optimizeForCompression,
      int inputBufferLength,
      int outputBufferLength})
      : super(
            inputBufferLength: inputBufferLength,
            outputBufferLength: outputBufferLength) {
    _options = _dispatcher.library.newCompressOptions();
    _preferences = _dispatcher.library.newPreferences(
        level: level,
        fastAcceleration: fastAcceleration,
        contentChecksum: contentChecksum,
        blockChecksum: blockChecksum,
        blockLinked: blockLinked,
        blockSize: blockSize,
        optimizeForCompression: optimizeForCompression);
  }

  @override
  CodecBufferHolder<Pointer<Uint8>, NativeCodecBuffer> newBufferHolder(
      int length) {
    return NativeCodecBufferHolder(length);
  }

  /// Init the filter
  ///
  /// 1. Provide appropriate buffer lengths to codec builders
  /// [inputBufferHolder.length] decoding buffer length and
  /// [outputBufferHolder.length] encoding buffer length
  /// Ensure that the [outputBufferHolder.length] is at least as large as the
  /// maximum size of an lz4 block given the [inputBufferHolder.length]
  ///
  /// 2. Allocate and setup the native lz4 context
  ///
  /// 3. Write the lz4 header out to the compressed buffer
  @override
  int doInit(
      CodecBufferHolder<Pointer<Uint8>, NativeCodecBuffer> inputBufferHolder,
      CodecBufferHolder<Pointer<Uint8>, NativeCodecBuffer> outputBufferHolder,
      List<int> bytes,
      int start,
      int end) {
    if (!inputBufferHolder.isLengthSet()) {
      inputBufferHolder.length = defaultInputBufferLength;
    }
    outputBufferHolder.length = outputBufferHolder.isLengthSet()
        ? max(outputBufferHolder.length,
            _lz4CompressBound(inputBufferHolder.length))
        : _lz4CompressBound(inputBufferHolder.length);
    _initContext();
    _writeHeader(outputBufferHolder.buffer);
    return 0;
  }

  /// Lz4 flush implementation.
  ///
  /// Return the number of bytes flushed.
  @override
  int doFlush(NativeCodecBuffer outputBuffer) {
    return _dispatcher.callLz4FFlush(
        _ctx, outputBuffer.writePtr, outputBuffer.unwrittenCount, _options);
  }

  /// Perform an lz4 encoding of [inputBuffer.unreadCount] bytes in
  /// and put the resulting encoded bytes into [outputBuffer] of length
  /// [outputBuffer.unwrittenCount].
  ///
  /// Return an [_Lz4EncodingResult] which describes the amount read/write
  @override
  _Lz4EncodingResult doProcessing(
      NativeCodecBuffer inputBuffer, NativeCodecBuffer outputBuffer) {
    final writtenCount = _dispatcher.callLz4FCompressUpdate(
        _ctx,
        outputBuffer.writePtr,
        outputBuffer.unwrittenCount,
        inputBuffer.readPtr,
        inputBuffer.unreadCount,
        _options);
    return _Lz4EncodingResult(inputBuffer.unreadCount, writtenCount);
  }

  /// Lz4 finalize implementation.
  ///
  /// Only 1 round of finalization is required, put filter state into
  /// the finalized state.
  ///
  /// A [StateError] is thrown if [outputBufferLength] is not of sufficient
  /// length.
  /// A [StateError] is thrown if writing out the lz4 trailer fails.
  @override
  int doFinalize(NativeCodecBuffer outputBuffer) {
    final writeLength = outputBuffer.unwrittenCount;
    if (writeLength < 4 ||
        (_preferences.frameInfoContentChecksumFlag != 0 && writeLength < 8)) {
      StateError(
          'buffer capacity is too small to properly finish the lz4 frame');
    }
    final numBytes = _dispatcher.callLz4FCompressEnd(
        _ctx, outputBuffer.writePtr, writeLength, _options);
    state = CodecFilterState.finalized;
    return numBytes;
  }

  /// Release lz4 resources
  @override
  void doClose() {
    _destroyContext();
    _destroyPreferences();
    _destroyCompressOptions();
    _releaseDispatcher();
  }

  /// Allocate the native lz4 compression context
  ///
  /// A [StateError] is thrown if the compression context could not be
  /// allocated.
  void _initContext() {
    _ctx = _dispatcher.callLz4FCreateCompressionContext();
  }

  /// Write the lz4 frame header to the compressed buffer
  ///
  /// A [StateError] is thrown if the encoding buffer is not big enough to
  /// hold at least the max size of an lz4 frame header
  /// A [StateError] is thrown if the lz4 frame header could not be written
  void _writeHeader(NativeCodecBuffer outputBuffer) {
    if (outputBuffer.unwrittenCount < Lz4Constants.LZ4F_HEADER_SIZE_MAX) {
      StateError('buffer capacity < LZ4F_HEADER_SIZE_MAX '
          '($Lz4Constants.LZ4F_HEADER_SIZE_MAX bytes)');
    }
    final numBytes = _dispatcher.callLz4FCompressBegin(
        _ctx, outputBuffer.writePtr, outputBuffer.unwrittenCount, _preferences);
    outputBuffer.incrementBytesWritten(numBytes);
  }

  /// Return the maximum length of an lz4 block, given its uncompressed
  /// [uncompressedLength].
  int _lz4CompressBound(int uncompressedLength) {
    return _dispatcher.callLz4FCompressBound(uncompressedLength, _preferences);
  }

  /// Free the native context
  ///
  /// A [StateError] is thrown if the context is invalid and can not be freed
  void _destroyContext() {
    if (_ctx != null) {
      try {
        _dispatcher.callLz4FFreeCompressionContext(_ctx);
      } finally {
        _ctx = null;
      }
    }
  }

  /// Free the native memory from the allocated [_preferences].
  void _destroyPreferences() {
    _preferences?.free();
    _preferences = null;
  }

  /// Free the native memory from the allocated [_preferences].
  void _destroyCompressOptions() {
    _options?.free();
    _options = null;
  }

  /// Release the Lz4 FFI call dispatcher
  void _releaseDispatcher() {
    _dispatcher.release();
  }
}

/// Construct a new lz4 filter which is configured with the options
/// provided
CodecFilter _makeLz4CompressFilter(
    int level,
    bool fastAcceleration,
    bool contentChecksum,
    bool blockChecksum,
    bool blockLinked,
    int blockSize,
    bool optimizeForCompression,
    int inputBufferLength,
    int outputBufferLength) {
  return _Lz4CompressFilter(
      level: level,
      fastAcceleration: fastAcceleration,
      contentChecksum: contentChecksum,
      blockChecksum: blockChecksum,
      blockLinked: blockLinked,
      blockSize: blockSize,
      optimizeForCompression: optimizeForCompression,
      inputBufferLength: inputBufferLength,
      outputBufferLength: outputBufferLength);
}

/// Result object for an Lz4 Encoding operation
class _Lz4EncodingResult extends CodecResult {
  const _Lz4EncodingResult(int bytesRead, int bytesWritten)
      : super(bytesRead, bytesWritten);
}
