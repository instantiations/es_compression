# Design Document for ES Compression
This document provides the design and rationale for the components in this library, as well as background information
for those that may be curious.

We hope that it will be helpful information for codec implementors, as well as an interesting read for developers.

## Table Of Contents
- [Design](#design-document-for-es-compression)
- [Objective](#objective)
- [Background](#background)
    - [Inspired-Port](#inspired-port)
- [Compression Framework](#compression-framework)
- [Target Platforms](#target-platforms)
- [Locating Shared Libraries](#locating-shared-libraries)
- [Building Shared Libraries](#building-shared-libraries)
- [Buffers](#buffers)
    - [Native](#native)
    - [Dart](#dart)
- [Filters](#filters)

### Objective
- Provide a robust and performant framework for codec implementations.
- Relieve codec implementors from data-flow implementation details.
- Provide a set of modern compression scheme implementations for users to incorporate.

### Background
This document will mostly focus on the architecture and implementation of the compression framework as it pertains to
*Dart*.

However, as part of the background, it is worth a short discussion on where the primary design of this framework came
from.

#### Inspired-Port
The compression framework from this library is based on the **Unified Compression Framework** from the
[VAST Platform](https://www.instantiations.com/products/vasmalltalk/index.html) (which we will refer to as *VAST* for
the remainder of this document). VAST's compression framework is integrated into its *Streams* library. These streams are more like Java synchronous
streams and less like Dart asynchronous streams.

Dart has a different architecture, and way of doing business based on `dart:convert`, so we felt it wasn't appropriate to
try and do a straight port from VAST.

Instead we modelled the interface layer off what we could see in Dart's `GZipCodec` implementation, and used that as the
entry point to our *compression framework*. It is the internals (i.e. double-buffers, filters) that reflects VAST's compression framework implementation.
**Anyone who has used Dart's codecs should have almost no learning curve when it comes to making use of the
codecs provided in this library.**

Included in VAST are codec implementations (`brotli`, `lz4`, `gzip`, `zstd`), some of which we thought could be useful
for Dart.

We chose to port `brotli`, `lz4` and `zstd` which are all FFI-based implementations in VAST. As such, we implemented them 
as FFI-based implementations in Dart and they all utilize the compression framework.

In order to accomplish this swiftly, pseudo-automation scripts from VAST were created along the way to help translate
VAST's FFI implementations to Dart. By the time we got to the third codec in this library (*brotli*), the ffi subdirectory 
was almost entirely auto-generated.

### Compression Framework
When implementing compression schemes, one must implement the details of the compression algorithm.\
For it to be integrated and useful in practice, one must also implement...**everything else**.\
The goal of the compression framework is to implement **"everything else"**.

Specifically, for compression schemes an input is supplied, and the processing of that input produces a change
in state, which typically results in a production of output (often a compressed or decompressed form of the input).
The details of the algorithm describe how that input is mapped to a resulting output.
Certainly the implementation will end up defining the trade-offs that go into different compression schemes such as
compression-ratio and performance.

However, there are important details regarding the flow of data in and out of the algorithm processors and interfacing
cleanly with the rest of the system.
It is these types of recurring considerations that can be captured in a framework to be made available for others to use
so they can specifically focus on algorithm details.

This is the fundamental motivation of the compression framework, to try and relieve the implementor from these
algorithm-independent considerations without sacrificing performance.

#### Target Platforms
Dart has a lot of targets. Win/Linux/Mac/iOS/Android/Web...\
Also several types of deployments. Executables, aot, snapshot, source...\
**The compression framework should be useful in each of these contexts.**

Especially with FFI-based codecs that interface with external shared libraries, there has to be a plan for how these
libraries are to be located by the program.

#### Locating Shared Libraries
[open_library.dart](../lib/src/framework/native/library/open_library.dart) is a library module whose responsibility is to locate
and open OS shared libraries for use with FFI-codec implementations.

See the comment for the `OpenLibrary` mixin for an explanation of the ways a given shared library is found and loaded.

#### Building Shared Libraries
The shared libraries are built using the [blob_builder](../tool/blob_builder) from the `tool` directory.
This is a cmake-based build generator that will handle the building of prebuilt libraries for win/linux/mac.
The tool will also install them in the appropriate locations within the package to make updating simple for the
maintainers.

The cmake project is based on the internal cmake project used to build the virtual machine and third-party
libraries for the VAST Platform.

#### Buffers
The compression framework uses a double-buffered approach for managing incoming/outgoing data.
One buffer collects up all incoming data until the buffer is full. The other buffer is used for storing processed
outgoing data. The goal is to hand-off as much incoming data as possible to the codec routines so they can maximize the amount of
outgoing data written to the output buffer.

For FFI-based codecs, we want to minimize alloc/free of temporary buffers and reduce the total number of FFI calls to
C functions.

There are two types of buffers provided by the framework. Both are designed to be polymorphic with respect to each other:
- A *native* buffer which is backed by bytes allocated from the native OS heap of the Dart process.
- A *Dart* buffer which is backed by bytes from Dart's managed heap.

##### Native
The *native* buffer is used by FFI-based codec implementations where bytes must be accessible within C Functions.
During processing, incoming data is copied to the writable portion of the input buffer.

A native pointer to this buffer is passed to the codec routines, along with a native pointer to the writable portion of
the output buffer.

As the output buffer is flushed, a Dart heap-allocated copy of the buffered bytes is produced and passed on to
consumers.

With this persistent double-buffer approach, there is a copy to get incoming data into the buffer and a copy to get
processed outgoing data out of the buffer.
However, the buffers can be passed directly to C, as is. There isn't a need to alloc/free temporary buffers for the
purpose of getting the data from each incoming invocation into a format suitable for passing to a C function.

###### One-Shot Algorithms
At the time of this writing *(NOV-02-2020)*, a Dart managed byte object can not be passed directly to a C-Function via FFI.
In VAST, this is not the case, a *ByteArray* or *String* are both byte-shaped objects that the FFI engine knows about
and can address just the byte contents of the object so it can be handed off to C.
Furthermore, the memory-manager and FFI-call machinery itself ensure the contents will remain where they are for the
duration of the C call.

This impacts the ability to have efficient **one-shot** implementations where the full contents to encode/decode are
available to be passed directly to the C codec routine via FFI.
This was experimented with, and basically there is not a very large payoff (or its slower) because one must incur both
the cost of marshalling the complete data to native memory, and then back again to Dart.
At this point, it's essentially just a specialization of the double-buffer technique where the buffers are sized to
accommodate all the data. 

While the one-shot algorithms from VAST were not ported for the reason described above, we did make a framework hook
available for ourselves and others.

See the [CodecConverter](../lib/src/framework/converters.dart) for more information.

##### Dart
We also developed Dart-based buffers which are suitable to be used for pure Dart codec implementations.
This is part of the `framework.dart` library and does not have any dependencies on `dart:io`.
A Dart-based buffer is backed by `Uint8List` and there is a pointer abstraction that has the same feel as a
`Pointer<Uint8>`.

A [simple example](../example/rle_example.dart) was created so implementors could see how it works.

#### Filters
The framework offers a `CodecFilter` that handles most of the external concerns of codec implementations.
This class is designed to be subclassed, and subclass implementors will override callback hooks for codec initialization
, processing, flushing, finalizing and closing.

To simplify things even more, we provide two `CodecFilter` subclasses for implementors to extend:
- [DartCodecFilter](../lib/src/framework/dart/filters.dart) for non-ffi codec implementations
- [NativeCodecFilter](../lib/src/framework/native/filters.dart) for ffi codec implementations
