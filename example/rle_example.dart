// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:es_compression/framework.dart';
import 'package:es_compression/src/framework/dart/filters.dart';

import 'utils/example_utils.dart';

/// This program demonstrates using the compression framework to implement a new
/// encode/decoder defining a very simple run-length compression scheme.
///
/// RLE Algorithm Description: The data to compress will encode repetitive
/// sequences of characters (up to 9) in a 2 byte form.
/// a -> 1a
/// bb -> 2b
/// cccccccccccc -> 9c3c
///
/// In the example below:
/// 'abbcccddddeeeeeffffffffff'
/// will encode to
/// '1a2b3c4d5e9f2f'
///
/// The [exitCode] of this script is 0 if the decoded bytes match the original,
/// otherwise the [exitCode] is -1.
Future<int> main() async {
  exitCode = await _runRleExample();
  return exitCode;
}

/// Rle Example which answers 0 on success, -1 on error
Future<int> _runRleExample() async {
  final bytes = utf8.encode('abbcccddddeeeeefffffffffff');

  // One-shot encode/decode
  final encoded = runLengthCodec.encode(bytes);
  verifyEquality(utf8.encode('1a2b3c4d5e9f2f'), encoded,
      header: 'Verify encoding output');
  var decoded = runLengthCodec.decode(encoded);
  final oneShotResult = verifyEquality(bytes, decoded, header: 'One-shot: ');

  // Streaming encode/decode
  // Split bytes into 10 buckets
  final chunks = splitIntoChunks(bytes, 10);
  final randomStream = Stream.fromIterable(chunks);
  decoded = await randomStream
      .transform(runLengthCodec.encoder)
      .transform(runLengthCodec.decoder)
      .fold<List<int>>(<int>[], (buffer, data) {
    buffer.addAll(data);
    return buffer;
  });
  final streamResult = verifyEquality(bytes, decoded, header: 'Streaming: ');
  return (oneShotResult == true && streamResult == true) ? 0 : -1;
}

/// An instance of the default implementation of the [RunLengthCodec].
const RunLengthCodec runLengthCodec = RunLengthCodec._default();

/// Custom codec providing an [encoder] and [decoder].
class RunLengthCodec extends Codec<List<int>, List<int>> {
  RunLengthCodec();

  const RunLengthCodec._default();

  @override
  Converter<List<int>, List<int>> get decoder => RunLengthDecoder();

  @override
  Converter<List<int>, List<int>> get encoder => RunLengthEncoder();
}

/// Custom encoder that provides a [CodecSink] with the algorithm
/// [RunLengthEncoderFilter].
class RunLengthEncoder extends CodecConverter {
  @override
  ByteConversionSink startChunkedConversion(Sink<List<int>> sink) {
    final byteSink = asByteSink(sink);
    return CodecSink(byteSink, RunLengthEncoderFilter());
  }
}

/// Filter that encodes the incoming bytes using a Dart in-memory buffer.
class RunLengthEncoderFilter extends DartCodecFilterBase {
  int runLength = 1;

  @override
  CodecResult doProcessing(
      DartCodecBuffer inputBuffer, DartCodecBuffer outputBuffer) {
    final readPos = inputBuffer.readCount;
    final writePos = outputBuffer.writeCount;
    while (!inputBuffer.atEnd() && outputBuffer.unwrittenCount > 1) {
      const maxRunLength = 9;
      final next = inputBuffer.next();
      if (runLength < maxRunLength && inputBuffer.peek() == next) {
        runLength++;
      } else {
        final runLengthBytes = utf8.encode(runLength.toString());
        outputBuffer
          ..nextPutAll(runLengthBytes)
          ..nextPut(next);
        runLength = 1;
      }
    }
    final read = inputBuffer.readCount - readPos;
    final written = outputBuffer.writeCount - writePos;
    return CodecResult(read, written, adjustBufferCounts: false);
  }
}

/// Custom decoder that provides a [CodecSink] with the algorithm
/// [RunLengthDecoderFilter].
class RunLengthDecoder extends CodecConverter {
  @override
  ByteConversionSink startChunkedConversion(Sink<List<int>> sink) {
    final byteSink = asByteSink(sink);
    return CodecSink(byteSink, RunLengthDecoderFilter());
  }
}

enum RleState { expectingLength, expectingData }

/// Filter that decodes the incoming bytes using a Dart in-memory buffer.
class RunLengthDecoderFilter extends DartCodecFilterBase {
  RleState _state = RleState.expectingLength;
  int runLength = 1;

  @override
  CodecResult doProcessing(
      DartCodecBuffer inputBuffer, DartCodecBuffer outputBuffer) {
    final readPos = inputBuffer.readCount;
    final writePos = outputBuffer.writeCount;
    while (!inputBuffer.atEnd() && !outputBuffer.isFull()) {
      switch (_state) {
        case RleState.expectingLength:
          final runLengthStr = String.fromCharCode(inputBuffer.next());
          runLength = int.parse(runLengthStr);
          _state = RleState.expectingData;
          break;
        case RleState.expectingData:
          final nextChar = inputBuffer.next();
          for (var i = 0; i < runLength; i++) {
            outputBuffer.nextPut(nextChar);
          }
          _state = RleState.expectingLength;
          break;
      }
    }
    final read = inputBuffer.readCount - readPos;
    final written = outputBuffer.writeCount - writePos;
    return CodecResult(read, written, adjustBufferCounts: false);
  }
}
