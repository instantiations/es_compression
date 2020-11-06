## Examples
The examples provided in this directory serve two purposes:
1. Provide users a consumable usage example for each codec.
2. Provide codec implementors a simple demonstration of how to integrate with the compression framework.

### Codec Implementations
An example is provided for each codec implementation.\
Each example includes how to get the *version number* and usage of codecs in *one-shot* and *streaming* scenarios.\
Below are the links to each codec implementation example:
- [brotli_example.dart](brotli_example.dart)
- [lz4_example.dart](lz4_example.dart)
- [zstd_example.dart](zstd_example.dart)

#### Version Number
For FFI-based codec implementations, the version number:
1. Is a simple call to demonstrate that the codec FFI is working.
2. Gives assurance as to what exact OS library the program has bound to. 

#### One-Shot
In simple cases, a `List` of bytes is available in memory which describes either data to compress or decompress.\
In these cases, a selected `Codec` can be constructed and used to perform these operations in one call.\
For example, the following shows a round-trip encode/decode of data using the `brotli` codec.
```dart
final codec = BrotliCodec();
final encoded = codec.encode(bytes);
final decoded = codec.decode(encoded);
assert(bytes == decoded);
```

#### Streaming
There are many scenarios where holding larger input, and subsequent output, in memory would provide unfavorable
performance and memory characteristics.\
Other scenarios exist where it would be cleaner to integrate encoders/decoders into existing async stream flows.

In these scenarios, a streaming approach (via Dart's *chunked conversion*) is preferred and codec implementations from
this library are designed to be compatible with it.\
Below is the one-shot example from above, modified for streaming:
```dart
final codec = BrotliCodec();
bytesStream = asStream(bytes);
bytesStream
  .transform(codec.encoder)
  .transform(codec.decoder)
  .fold<List<int>>(<int>[], (buffer, data) {
    buffer.addAll(data);
    return buffer;
  }).then((decoded) {
    assert(bytes == decoded)
  });
```

### Compression Framework
This library comes with an [abstract compression framework](../lib/framework.dart) which all provided codecs
utilize.\
The framework offers performant double-buffer codecs that orchestrate encoding/decoding of data.\
It also provides a set of abstractions that implement the non-algorithmic details leaving the implementor free to focus on
just providing the algorithm implementation.\
The framework can accommodate both FFI and non-FFI based implementations.

For non-FFI based implementations that work in all contexts *(including the web)*, import the `framework.dart` library.
```dart
import 'package:es_compression/framework.dart';
```

For FFI based implementations, import the `framework_io.dart` library.
```dart
import 'package:es_compression/framework_io.dart';
```

There is a [design document](../doc/design_doc.md) that provides more details behind the framework.

Codec implementors that want to know more about how this is accomplished should look at the following example:
- [rle_example.dart](rle_example.dart)

