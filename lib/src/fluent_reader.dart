// ============================================================
// Disclaimer: This source code is provided "as is", without any
// warranty of any kind, express or implied, including but not
// limited to the warranties of merchantability or fitness for
// a particular purpose.
// ============================================================

import 'dart:typed_data';

import '../d_bincode.dart';

/// Extension methods for reading specific list types in a fluent style.
///
/// All list readers assume a `u64` length prefix, followed by the list values.
///
/// Example:
/// ```dart
/// BincodeFluentReader(data).u32List((list) {
///   print('Read u32 list of length ${list.length}');
/// });
/// ```
extension FluentListReaders on BincodeFluentReader {
  /// Reads a `Vec<u32>` list (with u64-prefixed length).
  BincodeFluentReader u32List([void Function(List<int>)? callback]) {
    final list = readUint32List(listLength());
    callback?.call(list);
    return this;
  }

  /// Reads a `Vec<u8>` list (with u64-prefixed length).
  BincodeFluentReader u8List([void Function(List<int>)? callback]) {
    final list = readUint8List(listLength());
    callback?.call(list);
    return this;
  }

  /// Reads a `Vec<i8>` list (with u64-prefixed length).
  BincodeFluentReader i8List([void Function(List<int>)? callback]) {
    final list = readInt8List(listLength());
    callback?.call(list);
    return this;
  }

  /// Reads a `Vec<f32>` list (with u64-prefixed length).
  BincodeFluentReader f32List([void Function(List<double>)? callback]) {
    final list = readFloat32List(listLength());
    callback?.call(list);
    return this;
  }

  /// Internal utility for reading the `u64` length prefix of a collection.
  int listLength() => readU64();
}

/// A chainable, fluent API for reading bincode‐encoded binary data.
///
/// This class wraps [BincodeReader] and exposes builder-style methods for
/// each primitive and optional type, improving readability for decoding logic.
///
/// Example:
/// ```dart
/// BincodeFluentReader(data)
///   .u32((v) => print("ID: $v"))
///   .str((v) => print("Name: $v"))
///   .optF32((v) => print("Balance: $v"));
/// ```
class BincodeFluentReader extends BincodeReader {
  /// Constructs a fluent reader from a byte buffer.
  BincodeFluentReader(Uint8List bytes) : super(bytes);

  /// Loads and constructs a fluent reader from a binary file.
  static Future<BincodeFluentReader> fromFile(String path) async {
    final wrapper = await ByteDataWrapper.fromFile(path);
    return BincodeFluentReader(wrapper.buffer.asUint8List());
  }

  // -------------------
  // Base Types
  // -------------------

  BincodeFluentReader u8([void Function(int)? callback]) => _apply(readU8, callback);
  BincodeFluentReader u16([void Function(int)? callback]) => _apply(readU16, callback);
  BincodeFluentReader u32([void Function(int)? callback]) => _apply(readU32, callback);
  BincodeFluentReader u64([void Function(int)? callback]) => _apply(readU64, callback);
  BincodeFluentReader i8([void Function(int)? callback]) => _apply(readI8, callback);
  BincodeFluentReader i16([void Function(int)? callback]) => _apply(readI16, callback);
  BincodeFluentReader i32([void Function(int)? callback]) => _apply(readI32, callback);
  BincodeFluentReader i64([void Function(int)? callback]) => _apply(readI64, callback);
  BincodeFluentReader f32([void Function(double)? callback]) => _apply(readF32, callback);
  BincodeFluentReader f64([void Function(double)? callback]) => _apply(readF64, callback);
  BincodeFluentReader bool_([void Function(bool)? callback]) => _apply(readBool, callback);

  /// Reads a UTF-8 (or encoded) string with u64-prefixed length.
  BincodeFluentReader str([void Function(String)? callback, StringEncoding encoding = StringEncoding.utf8]) {
    return _apply(() => readString(encoding), callback);
  }

  /// Reads a fixed-length string with optional padding.
  BincodeFluentReader fixedStr(int length, [void Function(String)? callback, StringEncoding encoding = StringEncoding.utf8]) {
    return _apply(() => readFixedString(length, encoding: encoding), callback);
  }

  // -------------------
  // Optional Types
  // -------------------

  BincodeFluentReader optU8([void Function(int?)? callback]) => _apply(readOptionU8, callback);
  BincodeFluentReader optU16([void Function(int?)? callback]) => _apply(readOptionU16, callback);
  BincodeFluentReader optU32([void Function(int?)? callback]) => _apply(readOptionU32, callback);
  BincodeFluentReader optU64([void Function(int?)? callback]) => _apply(readOptionU64, callback);
  BincodeFluentReader optI8([void Function(int?)? callback]) => _apply(readOptionI8, callback);
  BincodeFluentReader optI16([void Function(int?)? callback]) => _apply(readOptionI16, callback);
  BincodeFluentReader optI32([void Function(int?)? callback]) => _apply(readOptionI32, callback);
  BincodeFluentReader optI64([void Function(int?)? callback]) => _apply(readOptionI64, callback);
  BincodeFluentReader optF32([void Function(double?)? callback]) => _apply(readOptionF32, callback);
  BincodeFluentReader optF64([void Function(double?)? callback]) => _apply(readOptionF64, callback);
  BincodeFluentReader optBool([void Function(bool?)? callback]) => _apply(readOptionBool, callback);

  /// Reads an optional string with encoding (uses `u8` presence tag).
  BincodeFluentReader optStr([void Function(String?)? callback, StringEncoding encoding = StringEncoding.utf8]) {
    return _apply(() => readOptionString(encoding), callback);
  }

  /// Reads an optional fixed-length string with encoding.
  BincodeFluentReader optFixedStr(int length, [void Function(String?)? callback, StringEncoding encoding = StringEncoding.utf8]) {
    return _apply(() => readOptionFixedString(length, encoding: encoding), callback);
  }

  /// Reads an optional 3-element float vector (vec3).
  ///
  /// Returns `null` if the presence flag is 0.
  BincodeFluentReader optF32Triple([void Function(List<double>?)? callback]) {
    final vec = readOptionF32Triple();
    callback?.call(vec?.toList());
    return this;
  }

  // -------------------
  // Internal
  // -------------------

  /// Utility to call a read function and optionally run a callback with the result.
  BincodeFluentReader _apply<T>(T Function() readFn, [void Function(T)? callback]) {
    final val = readFn();
    callback?.call(val);
    return this;
  }
}
