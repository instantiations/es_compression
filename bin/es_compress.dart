// Copyright (c) 2020, Seth Berman (Instantiations, Inc). Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';

const fileNameArg = 'file-name';
const randomBytesArg = 'random-bytes';
const levelArg = 'level';
const streamArg = 'stream';

void main(List<String> arguments) {
  final argParser = _buildArgParser();
  final argResults = argParser.parse(arguments);
  exitCode = 0;
}

ArgParser _buildArgParser() {
  return ArgParser()
    ..addFlag(streamArg,
        help: 'Stream if defined, otherwise convert all at once',
        defaultsTo: false,
        abbr: 's')
    ..addOption(fileNameArg, help: 'The filename to encode/decode', abbr: 'f')
    ..addOption(randomBytesArg,
        help: 'The # of random bytes to generate for encode/decode', abbr: 'r')
    ..addOption(levelArg, help: 'compression level', abbr: 'l');
}
