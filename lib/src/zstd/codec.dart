// Copyright (c) 2020, Seth Berman (Instantiations, Inc). Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'decoder.dart';
import 'encoder.dart';
import 'options.dart';

/// The [ZstdCodec] encodes/decodes raw bytes using the Zstd (ZStandard)
/// algorithm
class ZstdCodec extends Codec<List<int>, List<int>> {
  /// The compression-[level] can be set in the range of `0..16`, with
  /// 0 (fast mode) being the default compression level.
  final int level;

  /// Construct an [ZstdCodec] that is configured with the following parameters.
  ///
  /// Default values are provided for unspecified parameters.
  /// Validation is performed which may result in throwing a [RangeError] or
  /// [ArgumentError]
  ZstdCodec({this.level = ZstdOption.defaultLevel}) {
    validateZstdLevel(level);
  }

  const ZstdCodec._default() : level = ZstdOption.defaultLevel;

  @override
  Converter<List<int>, List<int>> get encoder => ZstdEncoder(level: level);

  @override
  Converter<List<int>, List<int>> get decoder => ZstdDecoder();
}

/// An instance of the default implementation of the [ZstdCodec].
const ZstdCodec zstd = ZstdCodec._default();
