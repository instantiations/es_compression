// Copyright (c) 2020, Seth Berman (Instantiations, Inc). Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi;

/// A streamable buffer used by codec algorithms.
///
/// # Writing:
/// 0..[_writeOffset] contains the data that has been written to the buffer or
/// [writeCount]. The remaining amount is [unwrittenCount].
/// For decoding buffers, data written will be the decoded bytes
/// to process during encoding, or the decoded bytes during decoding.
/// For encoding buffers, data written will be the encoded bytes that is
/// output from the encoding routine, or the external input during decoding.
///
/// # Reading:
/// 0..[_readOffset] contains the data that has already been read in the buffer
/// or [readCount]. The remaining amount is [unreadCount].
/// For decoding buffers, read data is data that has been processed in the
/// case of encoding, or bytes passed to the external output during decoding.
/// For encoding buffers, data read will be the encoded bytes passed to
/// the external output during encoding, or encoded data that has been
/// processed in the case of decoding.
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
class CodecBuffer {
  /// Internal buffer of native bytes.
  final Pointer<Uint8> _bytes;

  /// Length of the internal buffer in bytes.
  ///
  /// [writeCount] + [unwrittenCount] == [length].
  final int length;

  /// Defines the read cursor position in the buffer.
  ///
  /// This will always be <= the [writeCount] cursor position.
  int _readOffset = 0;

  /// Defines the write cursor position in the buffer.
  ///
  /// This will always be <= the [length] of the buffer.
  int _writeOffset = 0;

  /// Accumulator of read bytes from previous [reset]s.
  ///
  /// [totalReadCount] is this value + the current [readCount].
  int _recordedReadCount = 0;

  /// Accumulator of write bytes from previous [reset]s.
  ///
  /// [totalWriteCount] is this value + the current [writeCount].
  int _recordedWriteCount = 0;

  /// Creates a new codec buffer of [length].
  CodecBuffer(this.length) : _bytes = ffi.allocate<Uint8>(count: length);

  /// Return the number of bytes currently written to the buffer.
  ///
  /// The result will be <= [length].
  int get writeCount => _writeOffset;

  /// Return the number of bytes the buffer still has available for writing.
  ///
  /// The result will be difference between the [writeCount] region of the
  /// buffer and the [length].
  int get unwrittenCount => length - _writeOffset;

  /// Return the total number of [writeCount] since the last hard [reset].
  int get totalWriteCount => _recordedWriteCount + writeCount;

  /// Return total number of [readCount] within the buffer.
  ///
  /// The result will be <= the [writeCount] amount.
  int get readCount => _readOffset;

  /// Return the total number of [readCount] since the last hard [reset].
  int get totalReadCount => _recordedReadCount + readCount;

  /// Return total number of remaining bytes available to be read
  ///
  /// The result will be <= the [writeCount] amount.
  int get unreadCount => _writeOffset - _readOffset;

  /// Return true if there are no [unwrittenCount] remaining, false otherwise.
  bool isFull() => unwrittenCount == 0;

  /// Return true if all [writeCount] have been read, false otherwise.
  bool atEnd() => _readOffset == _writeOffset;

  /// Return true if all [writeCount] have been read and there are
  /// no remaining [unwrittenCount], false otherwise.
  bool atEndAndIsFull() => _readOffset == length;

  /// Read and return the next byte.
  /// The [_readOffset] will be incremented by 1.
  ///
  /// If there are no [unreadCount] left, then evaluate the optional
  /// [onEnd] function and return the result.
  /// If no function is provided, then return -1.
  int next({int Function() onEnd}) => atEnd()
      ? onEnd != null
          ? onEnd()
          : -1
      : _bytes[_readOffset++];

  /// Read and answer a [List] containing up to the next [amount] of consecutive
  /// bytes.
  List<int> nextAll(int amount, {bool upTo = false}) {
    var endOffset = _readOffset + amount;
    if (upTo != true) {
      endOffset =
          RangeError.checkValidRange(_readOffset, endOffset, _writeOffset);
    }
    final readAmount = min(endOffset - _readOffset, unreadCount);
    final result = readPtr.asTypedList(readAmount);
    incrementBytesRead(readAmount);
    return result.toList(growable: false);
  }

  /// Read the next byte without consuming it.
  ///
  /// If there are no [unwrittenCount] left, then evaluate the optional
  /// [onEnd] function and return the result.
  /// If no function is provided, then return -1.
  int peek({int Function() onEnd}) => atEnd()
      ? onEnd != null
          ? onEnd()
          : -1
      : _bytes[_readOffset];

  /// Put the next byte into the buffer.
  ///
  /// If there are no [unwrittenCount] left, then evaluate the optional
  /// [onEnd] function and return false.
  /// Otherwise, return true.
  bool nextPut(int byte, {void Function() onEnd}) {
    if (isFull()) {
      onEnd?.call();
      return false;
    } else {
      _bytes[_writeOffset++] = byte;
      return true;
    }
  }

  /// Put [bytes] into the buffer.
  ///
  /// The range from [start] to [end] must be a valid range of [bytes].
  /// If [start] is omitted, it defaults to zero.
  /// If [end] is omitted, it defaults to [bytes.length].
  ///
  /// The number of bytes put may be additionally constrained by the
  /// remaining [unwrittenCount].
  ///
  /// Return the number of bytes from [bytes] put into the buffer.
  int nextPutAll(List<int> bytes, [int start, int end]) {
    start ??= 0;
    end = RangeError.checkValidRange(start, end, bytes.length);
    final putAmount = min(end - start, unwrittenCount);
    final destination = writePtr.asTypedList(putAmount);
    destination.setRange(0, putAmount, bytes, start);
    incrementBytesWritten(putAmount);
    return putAmount;
  }

  /// Update the read position by [amount] bytes.
  ///
  /// Bumps the internal [_readOffset] pointer by an [amount].
  /// If [amount] is negative, a [RangeError] is thrown.
  /// If the additional offset by an [amount] would be > [writeCount],
  /// a [StateError] is thrown.
  void incrementBytesRead(int amount) {
    RangeError.checkNotNegative(amount);
    final nextRead = _readOffset + amount;
    if (nextRead > _writeOffset) {
      final overRead = nextRead - _writeOffset;
      final bytes = overRead == 1 ? 'byte' : 'bytes';
      throw StateError(
          'illegal attempt to read $overRead $bytes more than was written');
    } else {
      _readOffset = nextRead;
    }
  }

  /// Update the write position by [amount] bytes.
  ///
  /// Bumps the internal [_writeOffset] pointer by an [amount].
  /// If [amount] is negative, a [RangeError] is thrown.
  /// If the additional write by an [amount] overflows
  /// the buffer, a [StateError] is thrown.
  ///
  /// An overflow may suggest that native memory was overwritten since updates
  /// typically occur after a direct operation on the native buffer.
  void incrementBytesWritten(int amount) {
    RangeError.checkNotNegative(amount);
    final nextWrite = _writeOffset + amount;
    if (nextWrite > length) {
      final overWritten = nextWrite - length;
      final bytes = overWritten == 1 ? 'byte' : 'bytes';
      throw StateError(
          'illegal attempt to write $overWritten $bytes past the buffer');
    } else {
      _writeOffset = nextWrite;
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
    _resetRead(hard);
    _resetWrite(hard);
  }

  /// Reset the read offsets in the buffer.
  ///
  /// If [hard] is true, reset the [_recordedReadCount] accumulator.
  /// If [hard] is false (default), add the current [readCount] to the
  /// [_recordedReadCount].
  void _resetRead(bool hard) {
    _recordedReadCount = hard ? 0 : _recordedReadCount + readCount;
    _readOffset = 0;
  }

  /// Reset the write offsets in the buffer.
  ///
  /// If [hard] is true, reset the [_recordedWriteCount] accumulator.
  /// If [hard] is false (default), add the current [writeCount] to the
  /// [_recordedWriteCount].
  void _resetWrite(bool hard) {
    _recordedWriteCount = hard ? 0 : _recordedWriteCount + writeCount;
    _writeOffset = 0;
  }

  /// Return the native byte pointer to the [_buffer] base address.
  Pointer<Uint8> get basePtr => _bytes;

  /// Return the native byte pointer to the memory location at the [writeCount]
  /// offset from the [_buffer] base address.
  Pointer<Uint8> get writePtr => _bytes.elementAt(_writeOffset);

  /// Return the native byte pointer to the memory location at the [readCount]
  /// offset from the [_buffer] base address.
  Pointer<Uint8> get readPtr => _bytes.elementAt(_readOffset);

  /// Return the read contents of the buffer as a [List].
  ///
  /// This will include the data in the buffer from the start up to the
  /// read amount.
  /// If [copy] is true, then a copy of the bytes will be returned, otherwise
  /// a view of the bytes is returned (which may change since this is buffered)
  /// If [reset] is true, the [_readOffset] will be set to 0.
  /// If [hard] is true, the [recordedBytesRead] will also be set to 0.
  List<int> readBytes(
      {bool copy = true, bool reset = false, bool hard = false}) {
    final listView = _bytes.asTypedList(readCount);
    final list = (copy == true) ? Uint8List.fromList(listView) : listView;
    if (reset == true) _resetRead(hard);
    return list;
  }

  /// Return the written contents of the buffer as a [List].
  ///
  /// This will include the data in the buffer from the start up to the
  /// written amount.
  /// If [copy] is true, then a copy of the bytes will be returned, otherwise
  /// a view of the bytes is returned (which may change since this is buffered)
  /// If [reset] is true, the [_writeOffset] will be set to 0.
  /// If [hard] is true, the [_recordedWriteCount] will also be set to 0.
  List<int> writtenBytes(
      {bool copy = true, bool reset = false, bool hard = false}) {
    final listView = _bytes.asTypedList(writeCount);
    final list = (copy == true) ? Uint8List.fromList(listView) : listView;
    if (reset == true) _resetWrite(hard);
    return list;
  }

  /// Free internal resources used by the buffer.
  void release() {
    if (_bytes != null) ffi.free(_bytes);
  }
}

/// Function signature for a function that takes a [length] parameter
/// and answers a [CodecBuffer]
typedef codecBufferBuilderFunc = CodecBuffer Function(int length);

/// Provides a simple buffer holder/builder with a customizable builder function
/// [codecBufferBuilderFunc].
///
/// The motivation is to help subclasses of [CodecFilter] to customize the
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
class CodecBufferHolder {
  /// Return the [CodecBuffer] with defined [length]
  static CodecBuffer _defaultBuildBuffer(int length) => CodecBuffer(length);

  /// Length of the buffer to construct.
  int _length;

  /// Buffer that was constructed.
  CodecBuffer _buffer;

  /// Custom function which takes a length and answers a [CodecBuffer].
  codecBufferBuilderFunc bufferBuilderFunc = _defaultBuildBuffer;

  /// Construct a new buffer holder with the specific length.
  CodecBufferHolder(this._length);

  /// Returns a constructed [CodecBuffer].
  CodecBuffer get buffer => _buffer ??= bufferBuilderFunc(length);

  /// Returns buffer length (bytes) or a default value.
  int get length => _length ?? 16384;

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
  bool isLengthSet() => _length != null;

  /// Return [:true:] if buffer is set, [:false:] otherwise.
  bool isBufferSet() => _buffer != null;

  /// Release the memory for any existing buffer
  void release() {
    _buffer?.release();
    _buffer = null;
  }
}
