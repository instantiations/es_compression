// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:es_compression/lz4.dart';
import 'package:es_compression/brotli.dart';
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
/// Usage Example: Encode a file
/// >dart es_compress.dart -e -i"inputFile.txt" -o"outputFile.lz4" -alz4 -l-1
///
/// Usage Example: Decode a file
/// >dart es_compress.dart -d -i"inputFile.lz4" -o"outputFile.txt" -alz4
///
/// Usage Example: Print help
/// >dart es_compress.dart -h
void main(List<String> arguments) {
  final argParser = _buildArgParser();
  final argResults = argParser.parse(arguments);

  if (argResults.arguments.isEmpty || argResults[helpArg] as bool == true) {
    print(argParser.usage);
  } else {
    final algorithm = argResults[algorithmArg] as String;
    final inputPath = argResults[inputFileArg] as String;
    final outputPath = argResults[outputFileArg] as String;
    final level = argResults[levelArg] as String;
    var encode = argResults[encodeArg] as bool;
    if (argResults[decodeArg] as bool == true) encode = false;

    final input = File(inputPath);
    if (input.existsSync() == false) {
      throw Exception('Input file does not exist: $inputPath');
    }
    final inputBytes = input.readAsBytesSync();
    final codec = _selectCodec(algorithm, level);
    final coder = (encode == true) ? codec.encoder : codec.decoder;
    final bytes = coder.convert(inputBytes);
    final outputFile = File(outputPath);
    outputFile.writeAsBytesSync(bytes);
  }

  exitCode = 0;
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
