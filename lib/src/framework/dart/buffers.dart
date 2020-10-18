// Copyright (c) 2020, Seth Berman (Instantiations, Inc). Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import '../buffers.dart';

/// Implementation of an in-memory Dart heap [CodecBuffer]
///
/// The backing buffer is a [Uint8List] which store the bytes.
/// There are base, read and write [DartHeapPointer]s required by the
/// superclass.
///
/// This buffer is designed to be used by codec algorithms that are implemented
/// in pure Dart code, and do not need ffi dependencies.
class DartCodecBuffer extends CodecBuffer<DartHeapPointer> {
  /// Internal buffer impl
  final Uint8List _list;

  /// Wrapped pointer to the first element in the list
  @override
  DartHeapPointer basePtr;

  /// Wrapped pointer to the memory at the [readCount] offset from the
  /// first element in the list.
  DartHeapPointer _readPtr;

  /// Wrapped pointer to the memory at the [writeCount] offset from the
  /// first element in the list.
  DartHeapPointer _writePtr;

  /// Constructs a [DartCodecBuffer] that is backed by a [Uint8List] of
  /// the provided [length].
  DartCodecBuffer(int length)
      : _list = Uint8List(length),
        super(length) {
    basePtr = DartHeapPointer(_list);
    _readPtr = DartHeapPointer(_list);
    _writePtr = DartHeapPointer(_list);
  }

  /// Updates the read offset of the wrapped pointer and returns it.
  @override
  DartHeapPointer get readPtr => _readPtr..offset = readCount;

  /// Updates the write offset of the wrapped pointer and returns it.
  @override
  DartHeapPointer get writePtr => _writePtr..offset = writeCount;

  /// Return a subview from 0..[length]
  @override
  Uint8List baseListView(int length) => basePtr.asTypedList(length);

  /// Return a subview from [readCount]..[length]
  @override
  Uint8List readListView(int length) => readPtr.asTypedList(length);

  /// Return a subview from [writeCount]..[length]
  @override
  Uint8List writeListView(int length) => writePtr.asTypedList(length);

  /// Read the next byte, increment the [readCount], return the byte read.
  @override
  int doNext() => _list[readCount++];

  /// Put the next [byte] into the buffer.
  @override
  int doNextPut(int byte) => basePtr[writeCount++] = byte;

  /// Peek the next byte from the list.
  @override
  int doPeek() => basePtr[readCount];

  /// No action required.
  @override
  void release() {}
}

/// Provides a Dart heap counterpart to Pointer from FFI.
///
/// This is used as the pointer implementation for [DartCodecBuffer]s and is
/// useful when implementing codec algorithms in pure Dart with no FFI deps.
class DartHeapPointer {
  /// byte data.
  final Uint8List _bytes;

  /// Offset of this pointer within the data.
  int offset;

  /// Construct a pointer on the [Uint8List] bytes provided with a default
  /// offset of 0.
  DartHeapPointer(this._bytes, {int offset = 0}) : offset = offset;

  /// Return a typed list view on the byte data in the range 0..[amount].
  Uint8List asTypedList(int amount) =>
      Uint8List.sublistView(_bytes, offset, amount);

  /// Get a byte in the buffer relative to the current read position.
  int operator [](int index) => _bytes[offset + index];

  /// Set a byte in the buffer relative to the current read position.
  operator []=(int index, int value) => _bytes[offset + index] = value;
}
