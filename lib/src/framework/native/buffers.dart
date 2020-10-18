import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi;

import '../buffers.dart';

class NativeCodecBuffer extends CodecBuffer<Pointer<Uint8>> {
  /// Internal buffer of native bytes.
  final Pointer<Uint8> _bytes;

  NativeCodecBuffer(int length)
      : _bytes = ffi.allocate<Uint8>(count: length),
        super(length);

  /// Return the native byte pointer to the [_bytes] base address.
  @override
  Pointer<Uint8> get basePtr => _bytes;

  /// Return the native byte pointer to the memory location at the [writeCount]
  /// offset from the [_bytes] base address.
  @override
  Pointer<Uint8> get writePtr => _bytes.elementAt(writeCount);

  /// Return the native byte pointer to the memory location at the [readCount]
  /// offset from the [_bytes] base address.
  @override
  Pointer<Uint8> get readPtr => _bytes.elementAt(readCount);

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
  int doNext() => _bytes[readCount++];

  /// Return the next byte, do not increment the [readCount].
  @override
  int doPeek() => _bytes[readCount];

  /// Put the next [byte] into the buffer.
  @override
  void doNextPut(int byte) => basePtr[writeCount++] = byte;

  /// Free internal resources used by the buffer.
  @override
  void release() {
    if (_bytes != null) ffi.free(_bytes);
  }
}

