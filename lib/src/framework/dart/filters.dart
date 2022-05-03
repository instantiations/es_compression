import '../buffers.dart';
import '../filters.dart';
import 'buffers.dart';

/// Provides a base-class for codec filters that need to use Dart heap-allocated
/// buffers instead of ffi-based buffers.
abstract class DartCodecFilterBase
    extends CodecFilter<DartHeapPointer, DartCodecBuffer> {
  /// Constructor which allows the user to set the input/output buffer lengths.
  DartCodecFilterBase(
      {int inputBufferLength = 16386, int outputBufferLength = 16386})
      : super(
            inputBufferLength: inputBufferLength,
            outputBufferLength: outputBufferLength);

  /// Return a [DartCodecBufferHolder] with the intended [length].
  @override
  CodecBufferHolder<DartHeapPointer, DartCodecBuffer> newBufferHolder(
          int length) =>
      DartCodecBufferHolder(length);

  /// Init the filter.
  ///
  /// The default behavior is to return 0 for the number of bytes read from
  /// the input [bytes].
  @override
  int doInit(
          CodecBufferHolder<DartHeapPointer, DartCodecBuffer> inputBufferHolder,
          CodecBufferHolder<DartHeapPointer, DartCodecBuffer>
              outputBufferHolder,
          List<int> bytes,
          int start,
          int end) =>
      0;

  /// Flush the internal-algorithm buffered output data.
  ///
  /// The default behavior is to return 0 for the number of bytes flushed to the
  /// [outputBuffer].
  @override
  int doFlush(DartCodecBuffer outputBuffer) => 0;

  /// Perform algorithm-specific finalization.
  ///
  /// The default behavior is to return 0 for the number of bytes written to
  /// the [outputBuffer].
  @override
  int doFinalize(DartCodecBuffer outputBuffer) => 0;

  /// Perform tear-down procedures.
  ///
  /// The default behavior is to take no action.
  @override
  void doClose() {}
}
