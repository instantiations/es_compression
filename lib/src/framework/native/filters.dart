import 'dart:ffi';

import '../buffers.dart';
import '../filters.dart';
import 'buffers.dart';

/// Provides a base-class for codec filters that need to use Dart heap-allocated
/// buffers instead of ffi-based buffers.
abstract class NativeCodecFilterBase
    extends CodecFilter<Pointer<Uint8>, NativeCodecBuffer> {
  /// Constructor which allows the user to set the input/output buffer lengths.
  NativeCodecFilterBase({int inputBufferLength, int outputBufferLength})
      : super(
            inputBufferLength: inputBufferLength,
            outputBufferLength: outputBufferLength);

  /// Return a [DartCodecBufferHolder] with the intended [length].
  @override
  CodecBufferHolder<Pointer<Uint8>, NativeCodecBuffer> newBufferHolder(
      int length) {
    return NativeCodecBufferHolder(length);
  }

  /// Init the filter.
  ///
  /// The default behavior is to return 0 for the number of bytes read from
  /// the input [bytes].
  @override
  int doInit(
      CodecBufferHolder<Pointer<Uint8>, NativeCodecBuffer> inputBufferHolder,
      CodecBufferHolder<Pointer<Uint8>, NativeCodecBuffer> outputBufferHolder,
      List<int> bytes,
      int start,
      int end) {
    return 0;
  }

  /// Flush the internal-algorithm buffered output data.
  ///
  /// The default behavior is to return 0 for the number of bytes flushed to the
  /// [outputBuffer].
  @override
  int doFlush(NativeCodecBuffer outputBuffer) {
    return 0;
  }

  /// Perform algorithm-specific finalization.
  ///
  /// The default behavior is to return 0 for the number of bytes written to
  /// the [outputBuffer].
  @override
  int doFinalize(NativeCodecBuffer outputBuffer) {
    return 0;
  }

  /// Perform tear-down procedures.
  ///
  /// The default behavior is to take no action.
  @override
  void doClose() {}
}
