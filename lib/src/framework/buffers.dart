// Copyright (c) 2021, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:math';
import 'dart:typed_data';

/// An abstract implementation of a streamable buffer useful for implementing
/// codec algorithms.
///
/// # CodecBuffer<T>
/// Type [T] is the "pointer" to the various memory locations in the buffer,
/// such as the base, read and write ptr locations. [T] is usually a
/// `DartHeapPointer` from this library, or the ffi `Pointer` type.
/// However, this can be user defined.
///
/// # Writing:
/// 0..[writeCount] contains the data that has been written to the buffer.
/// The remaining amount is [unwrittenCount].
///
/// # Reading:
/// 0..[readCount] contains the data that has already been read in the buffer.
/// The remaining amount is [unreadCount].
///
/// The buffer is constantly being filled and flushed during usage by codecs.
/// It internally keeps track of how many total bytes have been read and written
/// as [totalReadCount] and [totalWriteCount].
///
/// # Streaming
/// Codec buffers are read and write streamable.
/// The stream is considered to be [atEnd] when [readCount] == [writeCount]
/// and there are no bytes to read.
/// The stream is considered to be [isFull] when [writeCount] == [length]
/// and there is no more room to place additional bytes.
abstract class CodecBuffer<T> {
  /// Creates a new codec buffer of [length].
  CodecBuffer(this.length);

  /// Length of the internal buffer in bytes.
  ///
  /// [writeCount] + [unwrittenCount] == [length].
  final int length;

  /// Accumulator of read bytes from previous [reset]s.
  ///
  /// [totalReadCount] is this value + the current [readCount].
  int _recordedReadCount = 0;

  /// Accumulator of write bytes from previous [reset]s.
  ///
  /// [totalWriteCount] is this value + the current [writeCount].
  int _recordedWriteCount = 0;

  /// Return the number of bytes currently written to the buffer.
  ///
  /// The result will be <= [length].
  int writeCount = 0;

  /// Return the number of bytes the buffer still has available for writing.
  ///
  /// The result will be difference between the [writeCount] region of the
  /// buffer and the [length].
  int get unwrittenCount => length - writeCount;

  /// Return the total number of [writeCount] since the last hard [reset].
  int get totalWriteCount => _recordedWriteCount + writeCount;

  /// Return total number of [readCount] within the buffer.
  ///
  /// The result will be <= the [writeCount] amount.
  int readCount = 0;

  /// Return the total number of [readCount] since the last hard [reset].
  int get totalReadCount => _recordedReadCount + readCount;

  /// Return total number of remaining bytes available to be read
  ///
  /// The result will be <= the [writeCount] amount.
  int get unreadCount => writeCount - readCount;

  /// Return true if there are no [unwrittenCount] remaining, false otherwise.
  bool isFull() => unwrittenCount == 0;

  /// Return true if all [writeCount] have been read, false otherwise.
  bool atEnd() => readCount == writeCount;

  /// Return true if all [writeCount] have been read and there are
  /// no remaining [unwrittenCount], false otherwise.
  bool atEndAndIsFull() => readCount == length;

  /// Read and return the next byte.
  /// The [readCount] will be incremented by 1.
  ///
  /// If there are no [unreadCount] left, then evaluate the optional
  /// [onEnd] function and return the result.
  /// If no function is provided, then return -1.
  int next({int Function()? onEnd}) {
    if (atEnd() == false) return basicNext();
    return onEnd?.call() ?? -1;
  }

  /// Subclass Responsibility: Consume and return the next byte.
  ///
  /// An [atEnd] check has already been performed at this point.
  /// [readCount] should be incremented by 1 after this call.
  int basicNext();

  /// Consume and answer a [List] containing up to the next [amount] of
  /// consecutive bytes.
  ///
  /// If [upToAmount] is [:true:], then read as many bytes up to [amount], which
  /// can be limited by the number of bytes written.
  List<int> nextAll(int amount, {bool upToAmount = false}) {
    var endOffset = readCount + amount;
    if (upToAmount != true) {
      endOffset = RangeError.checkValidRange(readCount, endOffset, writeCount);
    }
    final readAmount = min(endOffset - readCount, unreadCount);
    final result = readListView(readAmount);
    incrementBytesRead(readAmount);
    return result.toList(growable: false);
  }

  /// Read the next byte without consuming it.
  ///
  /// If there are no [unwrittenCount] left, then evaluate the optional
  /// [onEnd] function and return the result.
  /// If no function is provided, then return -1.
  int peek({int Function()? onEnd}) {
    if (atEnd() == false) return basicPeek();
    return onEnd?.call() ?? -1;
  }

  /// Subclass Responsibility: Return the next byte without consuming it.
  ///
  /// An [atEnd] check has already been performed at this point.
  /// [readCount] should be the same before and after this call.
  int basicPeek();

  /// Put the next byte into the buffer.
  ///
  /// If there are no [unwrittenCount] left, then evaluate the optional
  /// [onEnd] function and return false.
  /// Otherwise, return true.
  bool nextPut(int byte, {void Function()? onEnd}) {
    if (isFull()) {
      onEnd?.call();
      return false;
    } else {
      basicNextPut(byte);
      return true;
    }
  }

  /// Subclass Responsibility: Put the next byte into the buffer.
  ///
  /// A bounds check has been performed and it is safe to add an extra byte
  /// to the buffer.
  /// The [writeCount] should be incremented by 1.
  void basicNextPut(int byte);

  /// Put [bytes] into the buffer.
  ///
  /// The range from [start] to [end] must be a valid range of [bytes].
  /// If [start] is omitted, it defaults to zero.
  /// If [end] is omitted, it defaults to the length of [bytes].
  ///
  /// The number of bytes put may be additionally constrained by the
  /// remaining [unwrittenCount].
  ///
  /// Return the number of bytes from [bytes] put into the buffer.
  int nextPutAll(List<int> bytes, [int? start, int? end]) {
    start ??= 0;
    end = RangeError.checkValidRange(start, end, bytes.length);
    final putAmount = min(end - start, unwrittenCount);
    final destination = writeListView(putAmount);
    destination.setRange(0, putAmount, bytes, start);
    incrementBytesWritten(putAmount);
    return putAmount;
  }

  /// Update the read position by [amount] bytes.
  ///
  /// Bumps the internal [readCount] pointer by an [amount].
  /// If [amount] is negative, a [RangeError] is thrown.
  /// If the additional offset by an [amount] would be > [writeCount],
  /// a [ArgumentError] is thrown.
  void incrementBytesRead(int amount) {
    RangeError.checkNotNegative(amount);
    final nextRead = readCount + amount;
    if (nextRead > writeCount) {
      final overRead = nextRead - writeCount;
      final bytes = overRead == 1 ? 'byte' : 'bytes';
      throw ArgumentError(
          'illegal attempt to read $overRead $bytes more than was written');
    } else {
      readCount = nextRead;
    }
  }

  /// Update the write position by [amount] bytes.
  ///
  /// Bumps the internal [writeCount] pointer by an [amount].
  /// If [amount] is negative, a [RangeError] is thrown.
  /// If the additional write by an [amount] overflows
  /// the buffer, a [ArgumentError] is thrown.
  void incrementBytesWritten(int amount) {
    RangeError.checkNotNegative(amount);
    final nextWrite = writeCount + amount;
    if (nextWrite > length) {
      final overWritten = nextWrite - length;
      final bytes = overWritten == 1 ? 'byte' : 'bytes';
      throw ArgumentError(
          'illegal attempt to write $overWritten $bytes past the buffer');
    } else {
      writeCount = nextWrite;
    }
  }

  /// Reset the read/write offsets in the buffer.
  ///
  /// If [hard] is true, reset the [_recordedReadCount] and
  /// [_recordedWriteCount] accumulators also.
  /// If [hard] is false (default), add the current [readCount] to the
  /// [_recordedReadCount] and [writeCount] to the [_recordedWriteCount].
  ///
  /// The length of the buffer does not change.
  void reset({bool hard = false}) {
    resetRead(hard: hard);
    resetWrite(hard: hard);
  }

  /// Reset the read offsets in the buffer.
  ///
  /// If [hard] is true, reset the [_recordedReadCount] accumulator.
  /// If [hard] is false (default), add the current [readCount] to the
  /// [_recordedReadCount].
  void resetRead({bool hard = false}) {
    _recordedReadCount = hard ? 0 : _recordedReadCount + readCount;
    readCount = 0;
  }

  /// Reset the write offsets in the buffer.
  ///
  /// If [hard] is true, reset the [_recordedWriteCount] accumulator.
  /// If [hard] is false (default), add the current [writeCount] to the
  /// [_recordedWriteCount].
  void resetWrite({bool hard = false}) {
    _recordedWriteCount = hard ? 0 : _recordedWriteCount + writeCount;
    writeCount = 0;
  }

  /// Subclass Responsibility: Return the byte pointer to the memory at the
  /// start of the buffer.
  T get basePtr;

  /// Subclass Responsibility: Return the byte pointer to the memory at the
  /// [readCount] offset from the start of the buffer.
  T get readPtr;

  /// Subclass Responsibility: Return the byte pointer to the memory at the
  /// [writeCount] offset from the start of the buffer.
  T get writePtr;

  /// Subclass Responsibility: Return a [Uint8List] view on the buffer over the
  /// range base..[length].
  Uint8List baseListView(int length);

  /// Subclass Responsibility: Return a [Uint8List] view on the buffer over the
  /// range [readCount]..[length].
  Uint8List readListView(int length);

  /// Subclass Responsibility: Return a [Uint8List] view on the buffer over the
  /// range [writeCount]..[length].
  Uint8List writeListView(int length);

  /// Return the read contents of the buffer as a [List].
  ///
  /// This will include the data in the buffer from the start up to the
  /// read amount.
  /// If [copy] is true, then a copy of the bytes will be returned, otherwise
  /// a view of the bytes is returned (which may change since this is buffered)
  /// If [reset] is true, the [readCount] will be set to 0.
  /// If [hard] is true, the [_recordedReadCount] will also be set to 0.
  List<int> readBytes(
      {bool copy = true, bool reset = false, bool hard = false}) {
    final listView = baseListView(readCount);
    final list = (copy == true) ? Uint8List.fromList(listView) : listView;
    if (reset == true) resetRead(hard: hard);
    return list;
  }

  /// Return the written contents of the buffer as a [List].
  ///
  /// This will include the data in the buffer from the start up to the
  /// written amount.
  /// If [copy] is true, then a copy of the bytes will be returned, otherwise
  /// a view of the bytes is returned (which may change since this is buffered)
  /// If [reset] is true, the [writeCount] will be set to 0.
  /// If [hard] is true, the [_recordedWriteCount] will also be set to 0.
  List<int> writtenBytes(
      {bool copy = true, bool reset = false, bool hard = false}) {
    final listView = baseListView(writeCount);
    final list = (copy == true) ? Uint8List.fromList(listView) : listView;
    if (reset == true) resetWrite(hard: hard);
    return list;
  }

  /// Subclass Responsibility: Return [:true:] if buffer is available for use,
  /// [:false:] otherwise
  bool isAvailable();

  /// Subclass Responsibility: Free internal resources used by the buffer.
  void release();
}

/// Provides a simple buffer holder/builder with a customizable builder function
/// [bufferBuilderFunc].
///
/// The motivation is to help subclasses of `CodecFilter` to customize the
/// building of [CodecBuffer] by adjusting either the length or the buffer
/// construction call itself.
///
/// Some algorithms (i.e. Lz4 Decoding) need to compute the size of one buffer
/// by reading some header information from another buffer. Having a more
/// customizable buffer builder helps makes this easier.
///
/// A [CodecBufferHolder] may only construct one [CodecBuffer] so when
/// [CodecBufferHolder.buffer] is sent multiple times, the same instance
/// will be returned.
class CodecBufferHolder<T, CB extends CodecBuffer<T>> {
  /// Signals the [length] of the [CodecBuffer] should be left to the algorithm
  /// to determine.
  static const autoLength = -1;

  /// Buffer that was constructed.
  CB? _buffer;

  /// Length of the buffer to construct.
  int _length;

  /// Custom function which takes a length and answers a [CodecBuffer].
  CB Function(int length) bufferBuilderFunc;

  /// Construct a new buffer holder with the specific length.
  CodecBufferHolder(this._length, this.bufferBuilderFunc);

  /// Returns a constructed [CodecBuffer].
  CB get buffer => _buffer ??= bufferBuilderFunc(length);

  /// Returns buffer length (bytes) or a default value.
  int get length => _length;

  /// Set the buffer length (bytes).
  ///
  /// A [StateError] is raised if the buffer has already been created
  set length(int length) {
    if (isBufferSet()) {
      throw StateError('illegal attempt to change length of existing buffer');
    }
    _length = length;
  }

  /// Return [:true:] if length is set, [:false:] otherwise.
  bool isLengthSet() => _length != -1;

  /// Return [:true:] if buffer is set, [:false:] otherwise.
  bool isBufferSet() => _buffer != null;

  /// Release the memory for any existing buffer if necessary.
  void release() {
    _buffer?.release();
    _buffer = null;
  }
}
