import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../buffers.dart';

/// Implementation of a [CodecBuffer] backed by bytes allocated from the native
/// OS heap.
///
/// The backing buffer is referenced by a [Pointer].
///
/// This buffer is designed to be used by codec algorithms that are implemented
/// using Dart's ffi framework..
class NativeCodecBuffer extends CodecBuffer<Pointer<Uint8>> {
  /// References the buffer to the native bytes.
  final Pointer<Uint8> _bytes;

  /// Boolean that is [:true:] when the [_bytes] have been freed, [:false:]
  /// if [_bytes] are available for use.
  bool _released = false;

  /// Constructs a buffer that allocates [length] bytes from the native OS-heap.
  NativeCodecBuffer(super.length) : _bytes = malloc<Uint8>(length);

  /// Return the native byte pointer to the [_bytes] base address.
  @override
  Pointer<Uint8> get basePtr => _bytes;

  /// Return the native byte pointer to the memory location at the [writeCount]
  /// offset from the [_bytes] base address.
  @override
  Pointer<Uint8> get writePtr => _bytes + writeCount;

  /// Return the native byte pointer to the memory location at the [readCount]
  /// offset from the [_bytes] base address.
  @override
  Pointer<Uint8> get readPtr => _bytes + readCount;

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
  int basicNext() => _bytes[readCount++];

  /// Return the next byte, do not increment the [readCount].
  @override
  int basicPeek() => _bytes[readCount];

  /// Put the next [byte] into the buffer.
  @override
  void basicNextPut(int byte) => basePtr[writeCount++] = byte;

  /// Native buffer is available if native bytes have not been freed.
  @override
  bool isAvailable() => !_released;

  /// Free internal resources used by the buffer.
  @override
  void release() {
    if (isAvailable()) {
      malloc.free(_bytes);
      _released = true;
    }
  }
}

/// [CodecBufferHolder] for constructing [NativeCodecBuffer] instances.
class NativeCodecBufferHolder
    extends CodecBufferHolder<Pointer<Uint8>, NativeCodecBuffer> {
  /// Construct a [NativeCodecBufferHolder] which generates [NativeCodecBuffer]s
  NativeCodecBufferHolder(int length) : super(length, NativeCodecBuffer.new);
}
