## 0.1.0 [In Progress]

- Initial development release, created by Seth Berman [Instantiations, Inc](https://www.instantiations.com).
- Implemented general codec framework.
- Implemented FFI read/write streamable buffers.
- Implemented Dart Heap read/write streamable buffers.
- Implemented FFI bindings for [LZ4 v1.9.2](https://github.com/lz4/lz4/tree/v1.9.2).
- Implemented LZ4 codec framework extensions.
- Implemented [LZ4 benchmarks](benchmark/lz4_benchmark.dart)
- Implemented [LZ4 examples](example/lz4_example.dart)
- Implemented [escompress](bin/es_compress.dart) binary script with lz4 integration
- Implemented shared library and LZ4 [Cmake build instructions](tool/blob_builder/CMakeLists.txt)
- Provided prebuilt [Win64 Brotli native shared library](lib/src/brotli/blobs/esbrotli-win64.dll)
- Provided prebuilt [Win64 LZ4 native shared library](lib/src/lz4/blobs/eslz4-win64.dll)
- Provided prebuilt [Win64 Zstd (ZStandard) native shared library](lib/src/zstd/blobs/eszstd-win64.dll)
- Implemented flexible library loading with [OpenLibrary](lib/src/framework/native/openlibrary.dart) mixin