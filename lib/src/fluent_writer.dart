// ============================================================
// Disclaimer: This source code is provided "as is", without any
// warranty of any kind, express or implied, including but not
// limited to the warranties of merchantability or fitness for
// a particular purpose.
// ============================================================

import 'dart:typed_data';

import '../d_bincode.dart';

/// A chainable, expressive API for constructing bincode-formatted binary data.
///
/// This class wraps [BincodeWriter] but provides a fluent builder interface
/// for better readability and reduced boilerplate in serialization code.
///
/// Example:
/// ```dart
/// final bytes = BincodeFluentBuilder()
///   .u32(42)
///   .str("hello")
///   .optF32(null)
///   .u8List([1, 2, 3])
///   .toBytes();
/// ```
class BincodeFluentBuilder extends BincodeWriter {
  // ---------------------------------------------------------------------------
  // Base Types
  // ---------------------------------------------------------------------------

  BincodeFluentBuilder u8(int value) => _apply(() => writeU8(value));
  BincodeFluentBuilder u16(int value) => _apply(() => writeU16(value));
  BincodeFluentBuilder u32(int value) => _apply(() => writeU32(value));
  BincodeFluentBuilder u64(int value) => _apply(() => writeU64(value));
  BincodeFluentBuilder i8(int value) => _apply(() => writeI8(value));
  BincodeFluentBuilder i16(int value) => _apply(() => writeI16(value));
  BincodeFluentBuilder i32(int value) => _apply(() => writeI32(value));
  BincodeFluentBuilder i64(int value) => _apply(() => writeI64(value));
  BincodeFluentBuilder f32(double value) => _apply(() => writeF32(value));
  BincodeFluentBuilder f64(double value) => _apply(() => writeF64(value));
  BincodeFluentBuilder bool_(bool value) => _apply(() => writeBool(value));

  /// Writes a length-prefixed UTF-8 (or other encoding) string.
  BincodeFluentBuilder str(String value, [StringEncoding encoding = StringEncoding.utf8]) =>
      _apply(() => writeString(value, encoding));

  /// Writes a fixed-length padded string.
  ///
  /// If [value] is shorter than [length], it's padded with null bytes.
  BincodeFluentBuilder strFix(String value, int length) =>
      _apply(() => writeFixedString(value, length));

  // ---------------------------------------------------------------------------
  // Optional Types
  // ---------------------------------------------------------------------------

  BincodeFluentBuilder optU8(int? value) => _apply(() => writeOptionU8(value));
  BincodeFluentBuilder optU16(int? value) => _apply(() => writeOptionU16(value));
  BincodeFluentBuilder optU32(int? value) => _apply(() => writeOptionU32(value));
  BincodeFluentBuilder optU64(int? value) => _apply(() => writeOptionU64(value));
  BincodeFluentBuilder optI8(int? value) => _apply(() => writeOptionI8(value));
  BincodeFluentBuilder optI16(int? value) => _apply(() => writeOptionI16(value));
  BincodeFluentBuilder optI32(int? value) => _apply(() => writeOptionI32(value));
  BincodeFluentBuilder optI64(int? value) => _apply(() => writeOptionI64(value));
  BincodeFluentBuilder optF32(double? value) => _apply(() => writeOptionF32(value));
  BincodeFluentBuilder optF64(double? value) => _apply(() => writeOptionF64(value));
  BincodeFluentBuilder optBool(bool? value) => _apply(() => writeOptionBool(value));

  /// Writes an optional UTF-8 string with a length prefix.
  BincodeFluentBuilder optStr(String? value, [StringEncoding encoding = StringEncoding.utf8]) =>
      _apply(() => writeOptionString(value, encoding));

  /// Writes an optional fixed-length string.
  ///
  /// Pads with null bytes and includes a presence flag.
  BincodeFluentBuilder optFixedStr(String? value, int length,
          [StringEncoding encoding = StringEncoding.utf8]) =>
      _apply(() => writeOptionFixedString(value, length));

  /// Writes an optional 3-element float vector (vec3).
  ///
  /// Uses a presence tag. If [vec3] is null or not length 3, it writes 12 zero bytes.
  BincodeFluentBuilder optVec3(Float32List? vec3) =>
      _apply(() => writeOptionF32Triple(vec3));

  // ---------------------------------------------------------------------------
  // Numeric Lists (with u64 length prefix)
  // ---------------------------------------------------------------------------

  BincodeFluentBuilder u8List(List<int> values) =>
      _apply(() => writeUint8List(values), values.length);

  BincodeFluentBuilder u16List(List<int> values) =>
      _apply(() => writeUint16List(values), values.length);

  BincodeFluentBuilder u32List(List<int> values) =>
      _apply(() => writeUint32List(values), values.length);

  BincodeFluentBuilder u64List(List<int> values) =>
      _apply(() => writeUint64List(values), values.length);

  BincodeFluentBuilder i8List(List<int> values) =>
      _apply(() => writeInt8List(values), values.length);

  BincodeFluentBuilder i16List(List<int> values) =>
      _apply(() => writeInt16List(values), values.length);

  BincodeFluentBuilder i32List(List<int> values) =>
      _apply(() => writeInt32List(values), values.length);

  BincodeFluentBuilder i64List(List<int> values) =>
      _apply(() => writeInt64List(values), values.length);

  BincodeFluentBuilder f32List(List<double> values) =>
      _apply(() => writeFloat32List(values), values.length);

  BincodeFluentBuilder f64List(List<double> values) =>
      _apply(() => writeFloat64List(values), values.length);

  // ---------------------------------------------------------------------------
  // Generic List / Map
  // ---------------------------------------------------------------------------

  /// Writes a list with a u64 length prefix, followed by custom elements.
  ///
  /// ```dart
  /// builder.list([1, 2, 3], builder.writeU8);
  /// ```
  BincodeFluentBuilder list<T>(List<T> values, void Function(T v) write) {
    writeU64(values.length);
    for (final v in values) {
      write(v);
    }
    return this;
  }

  /// Writes a map with a u64 entry count, then each key and value.
  ///
  /// ```dart
  /// builder.map({'a': 1}, builder.str, builder.u32);
  /// ```
  BincodeFluentBuilder map<K, V>(
      Map<K, V> map, void Function(K) writeKey, void Function(V) writeValue) {
    writeU64(map.length);
    map.forEach((key, value) {
      writeKey(key);
      writeValue(value);
    });
    return this;
  }

  // ---------------------------------------------------------------------------
  // Special
  // ---------------------------------------------------------------------------

  /// Saves the result to a file using [BincodeWriter.toFile].
  Future<void> toFile(String path) => super.toFile(path);

  // ---------------------------------------------------------------------------
  // Internal Helper
  // ---------------------------------------------------------------------------

  /// Internal helper that invokes [action], optionally prefixing with a length.
  BincodeFluentBuilder _apply(void Function() action, [int? length]) {
    if (length != null) {
      writeU64(length);
    }
    action();
    return this;
  }
}
