// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

// ignore_for_file: public_member_api_docs, constant_identifier_names

/// Contains required constants referenced by the following header files:
/// *decode.h*
/// *encode.h*
mixin BrotliConstants {
  static const BROTLI_FALSE = 0;
  static const BROTLI_TRUE = 1;

  static const BROTLI_DEFAULT_MODE = 0;
  static const BROTLI_MODE_FONT = 2;
  static const BROTLI_MODE_GENERIC = 0;
  static const BROTLI_MODE_TEXT = 1;

  static const BROTLI_DEFAULT_QUALITY = 11;
  static const BROTLI_MIN_QUALITY = 0;
  static const BROTLI_MAX_QUALITY = 11;

  static const BROTLI_DEFAULT_WINDOW = 22;
  static const BROTLI_MIN_WINDOW_BITS = 10;
  static const BROTLI_MAX_WINDOW_BITS = 24;
  static const BROTLI_LARGE_MAX_WINDOW_BITS = 30;
  static const BROTLI_LAST_ERROR_CODE = -31;

  static const BROTLI_MIN_INPUT_BLOCK_BITS = 16;
  static const BROTLI_MAX_INPUT_BLOCK_BITS = 24;

  static const BROTLI_MAX_NPOSTFIX = 3;

  static const BROTLI_PARAM_DISABLE_LITERAL_CONTEXT_MODELING = 4;
  static const BROTLI_PARAM_LARGE_WINDOW = 6;
  static const BROTLI_PARAM_LGBLOCK = 3;
  static const BROTLI_PARAM_LGWIN = 2;
  static const BROTLI_PARAM_MODE = 0;
  static const BROTLI_PARAM_NDIRECT = 8;
  static const BROTLI_PARAM_NPOSTFIX = 7;
  static const BROTLI_PARAM_QUALITY = 1;
  static const BROTLI_PARAM_SIZE_HINT = 5;

  static const BROTLI_OPERATION_EMIT_METADATA = 3;
  static const BROTLI_OPERATION_FINISH = 2;
  static const BROTLI_OPERATION_FLUSH = 1;
  static const BROTLI_OPERATION_PROCESS = 0;

  static const BROTLI_DECODER_ERROR_ALLOC_BLOCK_TYPE_TREES = -30;
  static const BROTLI_DECODER_ERROR_ALLOC_CONTEXT_MAP = -25;
  static const BROTLI_DECODER_ERROR_ALLOC_CONTEXT_MODES = -21;
  static const BROTLI_DECODER_ERROR_ALLOC_RING_BUFFER_1 = -26;
  static const BROTLI_DECODER_ERROR_ALLOC_RING_BUFFER_2 = -27;
  static const BROTLI_DECODER_ERROR_ALLOC_TREE_GROUPS = -22;
  static const BROTLI_DECODER_ERROR_DICTIONARY_NOT_SET = -19;
  static const BROTLI_DECODER_ERROR_FORMAT_BLOCK_LENGTH_1 = -9;
  static const BROTLI_DECODER_ERROR_FORMAT_BLOCK_LENGTH_2 = -10;
  static const BROTLI_DECODER_ERROR_FORMAT_CL_SPACE = -6;
  static const BROTLI_DECODER_ERROR_FORMAT_CONTEXT_MAP_REPEAT = -8;
  static const BROTLI_DECODER_ERROR_FORMAT_DICTIONARY = -12;
  static const BROTLI_DECODER_ERROR_FORMAT_DISTANCE = -16;
  static const BROTLI_DECODER_ERROR_FORMAT_EXUBERANT_META_NIBBLE = -3;
  static const BROTLI_DECODER_ERROR_FORMAT_EXUBERANT_NIBBLE = -1;
  static const BROTLI_DECODER_ERROR_FORMAT_HUFFMAN_SPACE = -7;
  static const BROTLI_DECODER_ERROR_FORMAT_PADDING_1 = -14;
  static const BROTLI_DECODER_ERROR_FORMAT_PADDING_2 = -15;
  static const BROTLI_DECODER_ERROR_FORMAT_RESERVED = -2;
  static const BROTLI_DECODER_ERROR_FORMAT_SIMPLE_HUFFMAN_ALPHABET = -4;
  static const BROTLI_DECODER_ERROR_FORMAT_SIMPLE_HUFFMAN_SAME = -5;
  static const BROTLI_DECODER_ERROR_FORMAT_TRANSFORM = -11;
  static const BROTLI_DECODER_ERROR_FORMAT_WINDOW_BITS = -13;
  static const BROTLI_DECODER_ERROR_INVALID_ARGUMENTS = -20;
  static const BROTLI_DECODER_ERROR_UNREACHABLE = -31;
  static const BROTLI_DECODER_NEEDS_MORE_INPUT = 2;
  static const BROTLI_DECODER_NEEDS_MORE_OUTPUT = 3;
  static const BROTLI_DECODER_NO_ERROR = 0;
  static const BROTLI_DECODER_PARAM_DISABLE_RING_BUFFER_REALLOCATION = 0;
  static const BROTLI_DECODER_PARAM_LARGE_WINDOW = 1;
  static const BROTLI_DECODER_RESULT_ERROR = 0;
  static const BROTLI_DECODER_RESULT_NEEDS_MORE_INPUT = 2;
  static const BROTLI_DECODER_RESULT_NEEDS_MORE_OUTPUT = 3;
  static const BROTLI_DECODER_RESULT_SUCCESS = 1;
  static const BROTLI_DECODER_SUCCESS = 1;
}
