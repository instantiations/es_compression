## Description
Compression framework providing FFI implementations for Brotli, Lz4, Zstd with ready-to-use prebuilt binaries for Win/Linux/Mac.

This work is an inspired port of the *Unified Compression Framework* from the [VAST Platform] (VA Smalltalk) language
and development environment.

## Examples
In the `example` subdirectory, the following examples are provided to demonstrate usage of the converters and framework.

| Example                   | Description                                                                               |
| ------------------------- | ----------------------------------------------------------------------------------------- |
| `brotli_example.dart`     | Encode/Decode in one-shot and streaming modes using the Brotli FFI-based implementation   |
| `lz4_example.dart`        | Encode/Decode in one-shot and streaming modes using the Lz4 FFI-based implementation      |
| `rle_example.dart`        | A simple RLE compression example designed to show how build custom codecs                 |
| `zstd_example.dart`       | Encode/Decode in one-shot and streaming modes using the Zstd FFI-based implementation     |

To run (brotli shown below):
```console
dart example\brotli_example.dart
```

## Tests
In the `test` subdirectory, the following tests are provided for the compression framework and encoder/decoder
implementations.

| Test                  | Description                                                   |
| ----------------------| ------------------------------------------------------------- |
| `brotli_tests.dart`   | Test encoding/decode of the Brotli FFI-based implementation   |
| `buffer_tests.dart`   | Test `CodecBuffer` and friends in the compression framework   |
| `lz4_tests.dart`      | Test encoding/decode of the Lz4 FFI-based implementation      |
| `zstd_tests.dart`     | Test encoding/decode of the Zstd FFI-based implementation     |

To run test suite:
```console
pub run test
```

## Benchmarks
In the `benchmark` subdirectory, the following benchmarks are provided to help understand encoder/decoder performance
and tradeoffs involved with parameters like buffer sizing.

| Benchmark                 | Description                                                        |
| ------------------------- | ------------------------------------------------------------------ |
| `brotli_benchmark.dart`   | Benchmark encoding/decode of the Brotli FFI-based implementation   |
| `lz4_benchmark.dart`      | Benchmark encoding/decode of the Lz4 FFI-based implementation      |
| `zstd_benchmark.dart`     | Benchmark encoding/decode of the Zstd FFI-based implementation     |

To run (lz4 shown below):
```console
dart benchmark\lz4_benchmark.dart
```

## Executables
In the `bin` subdirectory, the following executables are provided.

| Executable    | Source                | Description                                            |
| --------------| ----------------------|------------------------------------------------------- |
| `escompress`  | `es_compress.dart`    | Encode/Decode files using brotli, gzip, lz4 and zstd   |

If you want to use escompress on the command line,
install it using `pub global activate`:

```console
> pub global activate escompress
```

## Framework
Initial codecs provided by this library use FFI-based implementations. However, the framework easily allows for pure
dart implementations for use within a web context. [rle_example.dart](example/rle_example.dart) shows a simple
example of how to accomplish this.

The `GZipCodec` from `dart:io` served as a great starting point for understanding how to put the VAST Platform framework
abstractions in terms of Dart codecs, converters, filters, sinks.

The major compression framework abstractions are:
- `CodecConverter` - Connects the compression framework to `Converter` in `dart:convert`.
- `CodecFilter` - Direct processing of byte data and provides low-level compression implementation and hooks.
- `CodecSink` - A type of `ByteConversionSink` for efficient transmission of byte data.
- `CodecBuffer` - A buffer with a streaming API that is backed by either [native](lib/src/framework/native/buffers.dart)
or [dart](lib/src/framework/dart/buffers.dart) heap bytes.

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].\
They will be reviewed and addressed on a best-effort basis by [Instantiations, Inc].

[tracker]: https://github.com/instantiations/es_compression/issues
[VAST Platform]: https://www.instantiations.com/products/vasmalltalk/index.html
