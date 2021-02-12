// Copyright (c) 2021, Instantiations, Inc. Please see the AUTHORS
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
  late final DartHeapPointer basePtr = DartHeapPointer(_list);

  /// Wrapped pointer to the memory at the [readCount] offset from the
  /// first element in the list.
  late final DartHeapPointer _readPtr = DartHeapPointer(_list);

  /// Wrapped pointer to the memory at the [writeCount] offset from the
  /// first element in the list.
  late final DartHeapPointer _writePtr = DartHeapPointer(_list);

  /// Constructs a [DartCodecBuffer] that is backed by a [Uint8List] with the
  /// provided [length].
  DartCodecBuffer(int length)
      : _list = Uint8List(length),
        super(length);

  /// Updates the read offset of the wrapped pointer and returns it.
  @override
  DartHeapPointer get readPtr => _readPtr..offset = readCount;

  /// Updates the write offset of the wrapped pointer and returns it.
  @override
  DartHeapPointer get writePtr => _writePtr..offset = writeCount;

  /// Return a subview list from 0..[length]
  @override
  Uint8List baseListView(int length) => basePtr.asTypedList(length);

  /// Return a subview list from [readCount]..[length]
  @override
  Uint8List readListView(int length) => readPtr.asTypedList(length);

  /// Return a subview list from [writeCount]..[length]
  @override
  Uint8List writeListView(int length) => writePtr.asTypedList(length);

  /// Read the next byte, increment the [readCount], return the byte read.
  @override
  int basicNext() => _list[readCount++];

  /// Put the next [byte] into the buffer.
  @override
  int basicNextPut(int byte) => basePtr[writeCount++] = byte;

  /// Peek the next byte from the list.
  ///
  /// No adjustment to the [readCount] offset is made.
  @override
  int basicPeek() => basePtr[readCount];

  /// Always true
  @override
  bool isAvailable() => true;

  /// No action required.
  @override
  void release() {}
}

/// Provides a Dart heap counterpart to Pointer from FFI.
///
/// This is used as the pointer implementation for [DartCodecBuffer]s and is
/// useful when implementing codec algorithms in pure Dart with no FFI deps.
class DartHeapPointer {
  /// Buffer holding the actual bytes.
  final Uint8List _bytes;

  /// Offset of this pointer within the data.
  int offset;

  /// Construct a pointer on the [Uint8List] bytes with a default offset of 0.
  ///
  /// Read and write pointers will have their offsets adjusted as more is read
  /// or written from the buffers.
  DartHeapPointer(this._bytes, {this.offset = 0});

  /// Return a typed list view on the byte data in the range
  /// [offset]..([offset] + [amount]).
  Uint8List asTypedList(int amount) =>
      Uint8List.sublistView(_bytes, offset, offset + amount);

  /// Get a byte in the buffer relative to the current [offset] position.
  int operator [](int index) => _bytes[offset + index];

  /// Set a byte in the buffer relative to the current [offset] position.
  void operator []=(int index, int value) => _bytes[offset + index] = value;
}

/// [CodecBufferHolder] for constructing [DartCodecBuffer] instances.
class DartCodecBufferHolder
    extends CodecBufferHolder<DartHeapPointer, DartCodecBuffer> {
  /// Construct a [DartCodecBufferHolder] which generates [DartCodecBuffer]s
  DartCodecBufferHolder(int length)
      : super(length, (length) => DartCodecBuffer(length));
}
