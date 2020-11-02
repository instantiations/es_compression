// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'package:es_compression/src/framework/buffers.dart';
import 'package:es_compression/src/framework/dart/buffers.dart';
import 'package:es_compression/src/framework/native/buffers.dart';
import 'package:test/test.dart';

void main() {
  doTest('DartCodecBuffer', (length) => DartCodecBuffer(length));
  doTest('NativeCodecBuffer', (length) => NativeCodecBuffer(length));
}

void doTest(String name, CodecBuffer Function(int length) newBuffer) {
  CodecBuffer buffer;

  test('Test $name default size', () {
    buffer = newBuffer(16384);
    expect(buffer.length, 16384);
    expect(buffer.totalReadCount, 0);
    expect(buffer.readCount, 0);
    expect(buffer.writeCount, 0);
    expect(buffer.totalWriteCount, 0);
  });

  test('Test $name custom size', () {
    buffer = newBuffer(65536);
    expect(buffer.length, 65536);
    expect(buffer.totalReadCount, 0);
    expect(buffer.readCount, 0);
    expect(buffer.writeCount, 0);
    expect(buffer.totalWriteCount, 0);
  });

  test('Test $name allocation', () {
    buffer = newBuffer(16384);
    expect(buffer.writeCount, 0);
    buffer.incrementBytesWritten(0);
    expect(buffer.writeCount, 0);
    buffer.incrementBytesWritten(10);
    expect(buffer.writeCount, 10);
    expect(buffer.unwrittenCount, buffer.length - buffer.writeCount);
    expect(buffer.readCount, 0);
    buffer.incrementBytesWritten(buffer.unwrittenCount);
    expect(buffer.writeCount, buffer.length);
    expect(buffer.unwrittenCount, 0);
    expect(buffer.readCount, 0);
    expect(() => buffer.incrementBytesWritten(-1), throwsRangeError);
    expect(
        () => buffer.incrementBytesWritten(1),
        throwsA(predicate((Error e) =>
            e is ArgumentError &&
            e.message == 'illegal attempt to write 1 byte past the buffer')));
    expect(
        () => buffer.incrementBytesWritten(10),
        throwsA(predicate((Error e) =>
            e is ArgumentError &&
            e.message == 'illegal attempt to write 10 bytes past the buffer')));
    expect(buffer.writeCount, buffer.length);
  });

  test('Test $name used', () {
    buffer = newBuffer(16384);
    expect(buffer.readCount, 0);
    expect(buffer.totalReadCount, 0);
    expect(buffer.totalWriteCount, 0);
    buffer.incrementBytesWritten(10);
    expect(buffer.totalReadCount, 0);
    expect(buffer.totalWriteCount, 10);
    expect(buffer.readCount, 0);
    expect(buffer.unreadCount, 10);
    buffer.incrementBytesRead(2);
    expect(buffer.totalReadCount, 2);
    expect(buffer.unreadCount, 8);
    buffer.incrementBytesRead(buffer.unreadCount);
    expect(buffer.totalReadCount, 10);
    expect(buffer.unreadCount, 0);
    expect(() => buffer.incrementBytesRead(-1), throwsRangeError);
    expect(
        () => buffer.incrementBytesRead(1),
        throwsA(predicate((Error e) =>
            e is ArgumentError &&
            e.message ==
                'illegal attempt to read 1 byte more than was written')));
    expect(
        () => buffer.incrementBytesRead(10),
        throwsA(predicate((Error e) =>
            e is ArgumentError &&
            e.message ==
                'illegal attempt to read 10 bytes more than was written')));
    buffer.reset();
    expect(buffer.totalWriteCount, 10);
    expect(buffer.totalReadCount, 10);
    buffer.incrementBytesWritten(buffer.unwrittenCount);
    buffer.incrementBytesRead(2);
    expect(buffer.totalReadCount, 12);
  });

  test('Test $name end/full', () {
    buffer = newBuffer(100);

    // Initial state
    expect(buffer.atEnd(), true);
    expect(buffer.isFull(), false);
    expect(buffer.atEndAndIsFull(), false);

    // Allocate half the total, none used
    buffer.incrementBytesWritten(50);
    expect(buffer.atEnd(), false);
    expect(buffer.isFull(), false);
    expect(buffer.atEndAndIsFull(), false);

    // Use up allocated region
    buffer.incrementBytesRead(50);
    expect(buffer.atEnd(), true);
    expect(buffer.isFull(), false);
    expect(buffer.atEndAndIsFull(), false);

    // Allocated region is now the size of the buffer
    buffer.incrementBytesWritten(buffer.unwrittenCount);
    expect(buffer.atEnd(), false);
    expect(buffer.isFull(), true);
    expect(buffer.atEndAndIsFull(), false);

    // Use up allocated region which is the entire buffer
    buffer.incrementBytesRead(buffer.unreadCount);
    expect(buffer.atEnd(), true);
    expect(buffer.isFull(), true);
    expect(buffer.atEndAndIsFull(), true);

    // Reset the region markers
    buffer.reset();
    expect(buffer.atEnd(), true);
    expect(buffer.isFull(), false);
    expect(buffer.atEndAndIsFull(), false);
  });

  test('Test $name read/write stream apis', () {
    buffer = newBuffer(10);

    // Test next put
    for (var i in List<int>.generate(10, (i) => i)) {
      expect(buffer.nextPut(i), true);
    }
    expect(buffer.isFull(), true);
    buffer.reset(hard: true);
    for (var i in List<int>.generate(10, (i) => i)) {
      expect(buffer.nextPut(i), true);
    }
    expect(() => buffer.nextPut(0, onEnd: () => throw StateError('onEnd')),
        throwsStateError);

    // Test nextPutAll
    buffer.reset(hard: true);
    final nextPutAllList = List<int>.generate(10, (i) => i);
    expect(buffer.nextPutAll(nextPutAllList), 10);
    expect(buffer.isFull(), true);
    expect(buffer.nextPutAll(nextPutAllList), 0);
    buffer.reset(hard: true);

    // Test peek
    buffer.reset(hard: true);
    buffer.incrementBytesWritten(10);
    for (var i in List<int>.generate(10, (i) => i)) {
      expect(buffer.next(), i);
    }
    expect(buffer.next(), -1);
    expect(() => buffer.next(onEnd: () => throw StateError('onEnd')),
        throwsStateError);

    // Test next
    buffer.reset();
    buffer.incrementBytesWritten(10);
    for (var i in List<int>.generate(10, (i) => i)) {
      expect(buffer.peek(), i);
      buffer.incrementBytesRead(1);
    }
    expect(buffer.peek(), -1);
    expect(() => buffer.peek(onEnd: () => throw StateError('onEnd')),
        throwsStateError);

    // Test nextAll
    buffer.reset(hard: true);
    for (var i in List<int>.generate(10, (i) => i)) {
      expect(buffer.nextPut(i), true);
    }
    buffer.reset();
    buffer.incrementBytesWritten(10);
    expect(buffer.nextAll(10), List<int>.generate(10, (i) => i));

    // Test nextAll upTo
    buffer.reset(hard: true);
    for (var i in List<int>.generate(10, (i) => i)) {
      expect(buffer.nextPut(i), true);
    }
    buffer.reset();
    buffer.incrementBytesWritten(10);
    expect(buffer.nextAll(100, upToAmount: true),
        List<int>.generate(10, (i) => i));

    // Test nextAll underflow/overflow
    buffer.reset(hard: true);
    for (var i in List<int>.generate(10, (i) => i)) {
      expect(buffer.nextPut(i), true);
    }
    buffer.reset();
    buffer.incrementBytesWritten(10);
    expect(buffer.readCount, 0);
    expect(buffer.writeCount, 10);
    expect(() => buffer.nextAll(100), throwsRangeError);
    expect(() => buffer.nextAll(-1), throwsRangeError);
    expect(buffer.readCount, 0);
    expect(buffer.writeCount, 10);
    expect(buffer.writtenBytes(), List<int>.generate(10, (i) => i));
    buffer.nextAll(buffer.unreadCount);
    expect(buffer.readBytes(), List<int>.generate(10, (i) => i));
  });

  test('Test codec buffer holder', () {
    final bufferHolder =
        CodecBufferHolder<DartHeapPointer, DartCodecBuffer>(10);
    expect(bufferHolder.length, 10);
    bufferHolder.length = 20;
    expect(bufferHolder.length, 20);
    expect(bufferHolder.isLengthSet(), true);
    expect(bufferHolder.isBufferSet(), false);
    expect(bufferHolder.buffer == null, true);
    bufferHolder.bufferBuilderFunc = (length) => DartCodecBuffer(length);
    expect(bufferHolder.buffer is DartCodecBuffer, true);
    expect(() => bufferHolder.length = 100, throwsStateError);
    bufferHolder.release();
    expect(bufferHolder.isBufferSet(), false);
  });

  tearDown(() {
    buffer?.release();
    buffer = null;
  });
}
