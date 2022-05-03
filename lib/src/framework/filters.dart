// Copyright (c) 2021, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'buffers.dart';

/// Various states that a [CodecFilter] transition through.
///
/// The codec filter is constructed with a default [closed] state.
/// Then a transition to the [init] state is made after object construction
/// Then a transition to the [processing] state is made after the call to
/// [CodecFilter._initFilter].
/// Then a transition to the [finalized] state is made on the last
/// [CodecFilter.processed] call.
/// Finally a transition to the [closed] state is made on [CodecFilter.close]
/// but before [CodecFilter.doClose] is called.
enum CodecFilterState {
  /// State after object construction, but before [processing].
  init,

  /// State during processing input to output.
  processing,

  /// State on the last processing call.
  finalized,

  /// State before [init] and once the codec is closed
  closed,
}

/// Subclasses of [CodecFilter] provide low-level interfaces to their
/// algorithms and direct the processing of data.
///
/// Generics:
/// [P] defines the type to use for the [CodecBuffer]'s memory pointer.
/// [CB] is the implementation type for an abstract [CodecBuffer] of type [P]
///
/// A [CodecFilter] contains two buffers.
/// An buffer [_inputBuffer] to incoming bytes to process.
/// an buffer [_outputBuffer] to for outgoing processed bytes.
///
/// A [CodecFilter] also maintains a [state] which can help
/// implementations know what part of the lifecycle the filter is in
/// (i.e. processing vs closed)
abstract class CodecFilter<P, CB extends CodecBuffer<P>> {
  /// Buffer holder for the input buffer
  late final CodecBufferHolder<P, CB> _inputBufferHolder;

  /// Buffer holder for the output buffer
  late final CodecBufferHolder<P, CB> _outputBufferHolder;

  /// Buffers incoming bytes to be processed
  CB get _inputBuffer => _inputBufferHolder.buffer;

  /// Buffers outgoing bytes that have been processed
  CB get _outputBuffer => _outputBufferHolder.buffer;

  /// Queued data in case the call to [process] could not completely flush
  /// through the incoming data.
  _InputData<P> _toProcess = _InputData<P>.empty();

  /// State tracker for filters.
  CodecFilterState state = CodecFilterState.closed;

  /// Return true if filter is in init state.
  bool get init => state == CodecFilterState.init;

  /// Return true if filter is in opened state.
  bool get processing => state == CodecFilterState.processing;

  /// Return true if filter is in finalized state.
  bool get finalized => state == CodecFilterState.finalized;

  /// Return true if filter is in closed state.
  bool get closed => state == CodecFilterState.closed;

  /// Constructor which allows the user to set the input/output buffer lengths.
  ///
  /// If [inputBufferLength] and/or [outputBufferLength] are not provided, they
  /// will be null and subclasses will have the opportunity to set these up.
  ///
  /// The filter will transition from the [CodecFilterState.closed] to the
  /// [CodecFilterState.init] state after the call.
  CodecFilter(
      {required int inputBufferLength, required int outputBufferLength}) {
    state = CodecFilterState.init;
    _inputBufferHolder = newBufferHolder(inputBufferLength);
    _outputBufferHolder = newBufferHolder(outputBufferLength);
  }

  /// Close this filter if not already [closed].
  ///
  /// Subclasses will have an opportunity to [doClose] before
  /// the buffers are released.
  void close() {
    if (!closed) {
      doClose();
      _releaseBuffers();
      state = CodecFilterState.closed;
    }
  }

  /// Process a chunk of [data] from [start] to [end].
  /// A call to [process] should only be made when [processed] returns [:null:].
  ///
  /// It may be impossible to finish processing the data due a lack of buffer
  /// space and nothing to drain the output buffer to. This is an expected
  /// scenario and the remaining data is queued in the [_toProcess] variable
  /// to be handled during [processed].
  void process(List<int> data, int start, int end) {
    if (init) start += _initFilter(data, start, end);
    start += _inputBuffer.nextPutAll(data, start, end);
    _toProcess = _InputData<P>(data, start, end);
  }

  /// Return a chunk of processed data.
  ///
  /// When there is no more data available, [processed] will return [:null:].
  /// Set [flush] to [:false:] for non-final calls to improve performance of
  /// some filters
  ///
  /// The last call to [processed] should have [end] set to [:true:]. This will
  /// ensure the stream has an opportunity to be finalized with any trailing
  /// data.
  List<int>? processed({bool flush = true, bool end = false}) {
    if (!processing) return null;
    if (!end && !hasMoreToProcess()) return null;
    final builder = BytesBuilder(copy: false);
    if (_outputBuffer.unreadCount > 0) {
      final bufferedBytes = _outputBuffer.writtenBytes(reset: true);
      builder.add(bufferedBytes);
    } else {
      if (_toProcess.isNotEmpty) _toProcess = _toProcess.drainTo(_inputBuffer);
      _codeOrDecode();
      final bufferedBytes = _outputBuffer.writtenBytes(reset: true);
      builder.add(bufferedBytes);
      if (flush == true) _flush(builder);
      if (end == true) _finalize(builder);
    }
    return builder.takeBytes();
  }

  /// Return [:true:] if there is more data to process, [:false:] otherwise.
  ///
  /// There is more to process if data is remaining in either buffer to be read.
  /// There is more to process if a non-empty [_InputData] exists.
  bool hasMoreToProcess() =>
      _toProcess.isNotEmpty ||
      (_inputBuffer.unreadCount > 0) ||
      (_outputBuffer.unreadCount > 0);

  /// Perform a coder/decoder routine where the bytes from the incoming buffer
  /// are processed by the algorithm and the resulting processed bytes are
  /// placed in the output buffer
  CodecResult _codeOrDecode() {
    final result =
        doProcessing(_checkBuffer(_inputBuffer), _checkBuffer(_outputBuffer));
    if (result.adjustBufferCounts) {
      _inputBuffer.incrementBytesRead(result.readCount);
      _outputBuffer.incrementBytesWritten(result.writeCount);
    }
    if (_checkBuffer(_inputBuffer).atEnd()) _inputBuffer.reset();
    return result;
  }

  /// Flush any pending bytes to [bytesBuilder].
  /// Return the number of bytes flushed.
  ///
  /// Any bytes in the input buffer are first processed.
  /// This is followed by a series of flush calls, each of which
  /// will add the flushed bytes to [bytesBuilder] if available.
  int _flush(final BytesBuilder bytesBuilder) =>
      _flushOrFinalizeOperation(bytesBuilder, doFlush);

  /// Finalize the processing which may produce bytes to be added to
  /// [bytesBuilder]. Return the number of bytes finalized.
  ///
  /// Any bytes in the input buffer are first processed.
  /// This is followed by a series of finalize calls, each of which
  /// will add the resulting bytes to [bytesBuilder] if available
  int _finalize(final BytesBuilder bytesBuilder) {
    final numBytes = _flushOrFinalizeOperation(bytesBuilder, doFinalize);
    state = CodecFilterState.finalized;
    return numBytes;
  }

  /// Perform the flush/finalize operation [op] adding bytes to [bytesBuilder].
  /// Return the number of bytes flushed/finalized
  int _flushOrFinalizeOperation(
      final BytesBuilder bytesBuilder, int Function(CB outputBuffer) op) {
    var numAllBytes = 0;
    if (processing) {
      _codeOrDecode();
      var numBytes = 0;
      do {
        numBytes = op(_checkBuffer(_outputBuffer));
        if (numBytes > 0) {
          _outputBuffer.incrementBytesWritten(numBytes);
          final bufferedBytes =
              _checkBuffer(_outputBuffer).writtenBytes(reset: true);
          bytesBuilder.add(bufferedBytes);
          numAllBytes += numBytes;
        }
      } while (processing && numBytes != 0);
    }
    return numAllBytes;
  }

  /// Throw [StateError] if buffer has been freed.
  CB _checkBuffer(CB buffer) {
    if (!buffer.isAvailable()) {
      throw StateError('buffer not available');
    }
    return buffer;
  }

  /// Initialize the filter.
  ///
  /// Subclass responsibility hook [doInit] is called which gives subclasses
  /// a chance to init the buffers. For some algorithms, the size of the buffers
  /// may depend on information from [bytes].
  ///
  /// The filter will transition from the [CodecFilterState.init] to the
  /// [CodecFilterState.processing] state after the call.
  int _initFilter(List<int> bytes, int start, int end) {
    assert(init);
    final numRead =
        doInit(_inputBufferHolder, _outputBufferHolder, bytes, start, end);
    state = CodecFilterState.processing;
    return numRead;
  }

  /// Release (free) the codec buffers.
  void _releaseBuffers() {
    _inputBufferHolder.release();
    _outputBufferHolder.release();
  }

  /// Subclass Responsibility: Return a concrete [CodecBufferHolder].
  ///
  /// Subclasses will typically choose to return a `NativeCodecBufferHolder` or
  /// a `DartCodecBufferHolder` depending on if the buffer is FFI-based or pure
  /// Dart heap-based.
  CodecBufferHolder<P, CB> newBufferHolder(int bufferLength);

  /// Subclass Responsibility: Init the filter
  ///
  /// Some algorithms, such as decoders, will need to read header information
  /// from the initial [bytes] before processing data should begin.
  /// This information may be needed to appropriately size the output buffer.
  /// This is why a [CodecBufferHolder] is provided instead of the
  /// [CodecBuffer] itself. It gives implementers a chance to provide
  /// appropriate constraints on the input/output buffer sizes BEFORE the
  /// buffers are created.
  ///
  /// Other algorithms, such as encoders, can use this hook to write initial
  /// header information to the [outputBufferHolder] buffer.
  ///
  /// The framework needs to be able to detect how much was read from
  /// [bytes] and the caller should return this value.
  /// If [bytes] does not need to be read, then return 0.
  ///
  /// Afterwards, this filter will transition from the [CodecFilterState.init]
  /// to the [CodecFilterState.processing] state.
  ///
  /// Return the number of bytes read from the [bytes].
  int doInit(
      CodecBufferHolder<P, CB> inputBufferHolder,
      CodecBufferHolder<P, CB> outputBufferHolder,
      List<int> bytes,
      int start,
      int end);

  /// Subclass Responsibility: Algorithm-specific coding/decoding handler
  ///
  /// A request is being made to process bytes from the [inputBuffer] and place
  /// the results in the [outputBuffer]
  ///
  /// The `inputBuffer.readPtr` is a [CB] buffer to the read position and
  /// `inputBuffer.unreadCount` is the maximum number of bytes that can be read
  /// from the buffer.
  ///
  /// The resulting bytes can be placed in the [outputBuffer]. Callers will need
  /// to take care to write only the amount that can be written.
  /// The `outputBuffer.writePtr` is a [CB] buffer to the write position and
  /// `outputBuffer.unwrittenCount` is the number of bytes that can be written
  /// to the buffer.
  ///
  /// Callers do not need to adjust read/write positions of the [CodecBuffer].
  /// This is handled by the framework upon receiving the [CodecResult] returned
  /// from this method.
  ///
  /// Return a [CodecResult] describing the number of bytes read/written during
  /// the processing routine.
  CodecResult doProcessing(CB inputBuffer, CB outputBuffer);

  /// Subclass Responsibility: Perform algorithm-specific flush.
  ///
  /// Many algorithms have internal buffering applied within the native
  /// shared library in addition to the [CodecBuffer]s in the framework.
  ///
  /// This call should flush up to `outputBuffer.unwrittenCount` into the output
  /// buffer starting at `outputBuffer.writePtr`.
  ///
  /// The framework will perform multiple rounds of this call until all data is
  /// flushed into the destination that the framework has.
  ///
  /// Callers should answer 0 if there is no additional data to flush.
  ///
  /// Return the number of bytes flushed (<= `outputBuffer.unwrittenCount`)
  int doFlush(CB outputBuffer);

  /// Subclass Responsibility: Perform algorithm-specific finalization.
  ///
  /// Algorithm-specific finalization provides the opportunity to perform write
  /// activities such as inserting trailing data to the output.
  ///
  /// The framework will perform multiple rounds of this call until all data is
  /// finalized into the destination that the framework has.
  ///
  /// Callers should answer 0 if there is no additional data to finalize.
  ///
  /// Return the number of bytes added for finalization
  /// (<= `outputBuffer.unwrittenCount`).
  int doFinalize(CB outputBuffer);

  /// Subclass Responsibility: Tear-down the filter
  ///
  /// At this point, there should not be any processing operations.
  /// This is the place to release internal resources.
  void doClose();
}

/// Represents the result of encode/decode routines.
class CodecResult {
  /// Number of bytes read by codec routine
  final int readCount;

  /// Number of bytes written by codec routine
  final int writeCount;

  /// The read/write buffer counts will be incremented by the
  /// [readCount] and [writeCount]
  final bool adjustBufferCounts;

  /// Construct a [CodecResult] that defines the number of bytes that were
  /// read and written by a Codec routine.
  const CodecResult(this.readCount, this.writeCount,
      {this.adjustBufferCounts = true});
}

/// An [_InputData] is a small wrapper around the ranged incoming data.
///
/// For many cases, the [CodecFilter.process] method will completely process
/// the incoming data. But if, due to buffer sizes, this could not happen then
/// it is stored off as an [_InputData] to be handled at a later point before
/// the filter closes.
class _InputData<T> {
  /// Input data to be processed.
  List<int> data;

  /// Start within the input data.
  int start;

  /// End within the input data.
  int end;

  /// Returns an [_InputData] for the provided range on [data].
  /// If [start] >= [end], then return a cached empty [_InputData]
  /// with no unnecessary reference to [data]
  factory _InputData(List<int> data, int start, int end) {
    if (start >= end) {
      return _InputData<T>.empty();
    } else {
      return _InputData<T>._(data, start, end);
    }
  }

  /// Returns an empty [_InputData].
  factory _InputData.empty() => _InputData<T>._(const <int>[], 0, 0);

  /// Internal Constructor
  _InputData._(this.data, this.start, this.end);

  /// Length of the input data range.
  int get length => start - end;

  /// Answer [:true:] if ranged list is empty, [:false:] otherwise.
  @pragma('vm:prefer-inline')
  bool get isEmpty => length == 0;

  /// Answer [:true:] if ranged list is not empty, [:false:] otherwise.
  bool get isNotEmpty => !isEmpty;

  /// Drain as much [data] as possible to [buffer].
  ///
  /// Return an [_InputData] which describes the range of data to attempt
  /// drainage on next time.
  /// If this [_InputData] is completely drained, [_InputData.empty] is answered
  /// which will lose the reference to [data].
  _InputData<T> drainTo(CodecBuffer<T> buffer) {
    final newStart = start + buffer.nextPutAll(data, start, end);
    if (newStart == end) {
      return _InputData<T>.empty();
    } else {
      start = newStart;
      return this;
    }
  }
}
