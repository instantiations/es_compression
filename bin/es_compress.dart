// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:es_compression/brotli.dart';
import 'package:es_compression/lz4.dart';
import 'package:es_compression/zstd.dart';

const encodeArg = 'encode';
const decodeArg = 'decode';
const helpArg = 'help';
const inputFileArg = 'input-file';
const outputFileArg = 'output-file';
const levelArg = 'level';
const algorithmArg = 'algorithm';
const algorithms = {
  'brotli': 'Brotli compression',
  'gzip': 'Gzip compression',
  'lz4': 'LZ4 compression',
  'zstd': 'ZStandard compression'
};

/// Compresses/Decompresses files using the [algorithms] available.
///
/// Usage Example: Lz4 compress *input.txt* to *output.lz4*
/// > dart es_compress.dart -i"input.txt" -o"output.lz4"
///
/// Usage Example: Zstd decompress *input.zstd* to *output.txt*
/// > dart es_compress.dart -i"input.zstd" -o"output.txt"
///
/// Usage Example: Gzip compress *input.txt* to file with custom extension
/// named *output.mygzip*. (User must require -e for encode and -a for algo
/// selection)
/// > dart es_compress.dart -e -a gzip -i"input.txt" -o"output.mygzip"
///
/// Usage Example: Print help
/// > dart es_compress.dart -h
Future<int> main(List<String> arguments) async {
  final argParser = _buildArgParser();
  final argResults = argParser.parse(arguments);
  Future<int> exited;
  exitCode = 0;

  if (argResults.arguments.isEmpty || argResults[helpArg] as bool == true) {
    print(argParser.usage);
    exited = Future<int>.sync(() => 0);
  } else {
    // Read/Interpret arguments
    final algorithm =
        argResults[algorithmArg] as String ?? _guessAlgorithm(argResults);
    final level = argResults[levelArg] as String;
    final encode = _shouldEncode(argResults);
    final codec = _selectCodec(algorithm, level);
    final coder = (encode == true) ? codec.encoder : codec.decoder;

    // Open IO File Streams
    final input = _toFile(argResults[inputFileArg]);
    final output = _toFile(argResults[outputFileArg], mustExist: false);
    final inputStream = input.openRead();
    final outputSink = output.openWrite();
    var numChunks = 0;

    // Print the stats of the encode/decode
    void _printStats(Stopwatch stopwatch) {
      final inputLength = input.lengthSync();
      final outputLength = output.lengthSync();
      final uncompressedLength = encode ? inputLength : outputLength;
      final compressedLength = encode ? outputLength : inputLength;
      final elapsedTime = stopwatch.elapsed;
      final bytesPerSecond = elapsedTime.inMicroseconds > 0
          ? (uncompressedLength * 1e6) / elapsedTime.inMicroseconds
          : 0;
      final megabytesPerSecond = bytesPerSecond / 1048576;
      final speed = megabytesPerSecond.toStringAsFixed(2);
      final ratio =
          '${(uncompressedLength / compressedLength).toStringAsFixed(1)}:1';
      print('Stats:\n\tInput: $inputLength bytes split into $numChunks chunks'
          '\n\tOutput: $outputLength bytes'
          '\n\tTime: $elapsedTime'
          '\n\tSpeed: $speed MB/sec'
          '\n\tRatio: $ratio');
    }

    // Encode/Decode the input in chunks and write the results to the
    // output file.
    final stopwatch = Stopwatch()..start();
    final completer = Completer<int>();
    exited = completer.future;
    final stream = inputStream.transform(coder);
    stream.listen((chunk) {
      numChunks++;
      outputSink.add(chunk);
    }, onDone: () {
      outputSink.close().then((Object f) {
        stopwatch.stop();
        print('Completed $algorithm ${encode ? 'encoding' : 'decoding'}');
        _printStats(stopwatch);
        completer.complete(0);
      });
    }, onError: (Object e) {
      outputSink.close().then((Object f) {
        print(e.toString());
        completer.complete(-1);
      });
    }, cancelOnError: true);
  }

  exitCode = await exited;
  return exitCode;
}

/// Return true if encoding, false if decoding.
///
/// First try and determine based on the command line parameters.
/// If missing, then guess based off the file extension.
bool _shouldEncode(ArgResults argResults) {
  if (argResults[encodeArg] as bool == true) return true;
  if (argResults[decodeArg] as bool == true) return false;

  // Guess based on file extension
  final input = _toFile(argResults[inputFileArg]);
  if (algorithms.keys.any((ext) => input.path.endsWith(ext))) return false;
  final output = _toFile(argResults[outputFileArg], mustExist: false);
  if (algorithms.keys.any((ext) => output.path.endsWith(ext))) return true;
  return false;
}

/// Guess the algorithm to use based off the file extension of the
/// input/output
String _guessAlgorithm(ArgResults argResults) {
  // Guess based on file extension
  final input = _toFile(argResults[inputFileArg]);
  var algo = algorithms.keys
      .firstWhere((ext) => input.path.endsWith(ext), orElse: () => null);
  if (algo != null) return algo;

  final output = _toFile(argResults[outputFileArg], mustExist: false);
  algo = algorithms.keys
      .firstWhere((ext) => output.path.endsWith(ext), orElse: () => null);
  if (algo != null) return algo;

  return null;
}

/// Convert the [path] to a [File].
/// Ensure that the file exists if [mustExist] is [:true:]
File _toFile(dynamic path, {bool mustExist = true}) {
  if (path is! String) {
    throw Exception('File is not defined');
  }
  final file = File(path as String);
  if (mustExist && file.existsSync() == false) {
    throw Exception('File does not exist: $path');
  }
  return file;
}

/// Build and return a parser for the program arguments.
ArgParser _buildArgParser() {
  final sortedAlgorithms = algorithms.keys.toList();
  sortedAlgorithms.sort((a, b) => a.compareTo(b));
  return ArgParser()
    ..addFlag(helpArg,
        help: 'print this help usage', negatable: false, abbr: 'h')
    ..addFlag(encodeArg, help: 'encode', negatable: false, abbr: 'e')
    ..addFlag(decodeArg, help: 'decode', negatable: false, abbr: 'd')
    ..addOption(inputFileArg, help: 'input filename', abbr: 'i')
    ..addOption(outputFileArg, help: 'output filename', abbr: 'o')
    ..addOption(levelArg, help: 'compression level', abbr: 'l')
    ..addOption(algorithmArg,
        help: 'selected algorithm',
        abbr: 'a',
        allowed: sortedAlgorithms,
        allowedHelp: algorithms);
}

/// Select the appropriate codec class based on the [algorithm].
/// Configure it with the level provided.
Codec<List<int>, List<int>> _selectCodec(String algorithm, String levelStr) {
  final level = levelStr == null ? null : int.parse(levelStr);
  switch (algorithm) {
    case 'lz4':
      return level != null ? Lz4Codec(level: level) : Lz4Codec();
    case 'gzip':
      return level != null ? GZipCodec(level: level) : GZipCodec();
    case 'brotli':
      return level != null ? BrotliCodec(level: level) : BrotliCodec();
    case 'zstd':
      return level != null ? ZstdCodec(level: level) : ZstdCodec();
    default:
      throw Exception('Undefined algorithm name');
  }
}
