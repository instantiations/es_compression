import 'dart:ffi';
import 'dart:io';

// Note that kernel32.dll is the correct name in both 32-bit and 64-bit.
final DynamicLibrary stdlib = Platform.isWindows
    ? DynamicLibrary.open('kernel32.dll')
    : DynamicLibrary.process();

typedef PosixMallocNative = Pointer Function(IntPtr);
typedef PosixMalloc = Pointer Function(int);
final PosixMalloc posixMalloc =
stdlib.lookupFunction<PosixMallocNative, PosixMalloc>('malloc');

typedef PosixFreeNative = Void Function(Pointer);
typedef PosixFree = void Function(Pointer);
final PosixFree posixFree =
stdlib.lookupFunction<PosixFreeNative, PosixFree>('free');

typedef WinGetProcessHeapFn = Pointer Function();
final WinGetProcessHeapFn winGetProcessHeap = stdlib
    .lookupFunction<WinGetProcessHeapFn, WinGetProcessHeapFn>('GetProcessHeap');
final Pointer processHeap = winGetProcessHeap();

typedef WinHeapAllocNative = Pointer Function(Pointer, Uint32, IntPtr);
typedef WinHeapAlloc = Pointer Function(Pointer, int, int);
final WinHeapAlloc winHeapAlloc =
stdlib.lookupFunction<WinHeapAllocNative, WinHeapAlloc>('HeapAlloc');

typedef WinHeapFreeNative = Int32 Function(
    Pointer heap, Uint32 flags, Pointer memory);
typedef WinHeapFree = int Function(Pointer heap, int flags, Pointer memory);
final WinHeapFree winHeapFree =
stdlib.lookupFunction<WinHeapFreeNative, WinHeapFree>('HeapFree');

/// Manages memory on the native heap.
///
/// Does not initialize newly allocated memory to zero.
///
/// For POSIX-based systems, this uses `malloc` and `free`. On Windows, it uses
/// `HeapAlloc` and `HeapFree` against the default public heap.
class _MallocAllocator implements Allocator {
  const _MallocAllocator();

  /// Allocates [byteCount] bytes of of unitialized memory on the native heap.
  ///
  /// For POSIX-based systems, this uses `malloc`. On Windows, it uses
  /// `HeapAlloc` against the default public heap.
  ///
  /// Throws an [ArgumentError] if the number of bytes or alignment cannot be
  /// satisfied.
  @override
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment}) {
    Pointer<T> result;
    if (Platform.isWindows) {
      result = winHeapAlloc(processHeap, /*flags=*/ 0, byteCount).cast();
    } else {
      result = posixMalloc(byteCount).cast();
    }
    if (result.address == 0) {
      throw ArgumentError('Could not allocate $byteCount bytes.');
    }
    return result;
  }

  /// Releases memory allocated on the native heap.
  ///
  /// For POSIX-based systems, this uses `free`. On Windows, it uses `HeapFree`
  /// against the default public heap. It may only be used against pointers
  /// allocated in a manner equivalent to [allocate].
  ///
  /// Throws an [ArgumentError] if the memory pointed to by [pointer] cannot be
  /// freed.
  @override
  void free(Pointer pointer) {
    if (Platform.isWindows) {
      if (winHeapFree(processHeap, /*flags=*/ 0, pointer) == 0) {
        throw ArgumentError('Could not free $pointer.');
      }
    } else {
      posixFree(pointer);
    }
  }
}

/// Manages memory on the native heap.
///
/// Does not initialize newly allocated memory to zero.
///
/// For POSIX-based systems, this uses `malloc` and `free`. On Windows, it uses
/// `HeapAlloc` and `HeapFree` against the default public heap.
const Allocator malloc = _MallocAllocator();