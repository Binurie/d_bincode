// ============================================================
// Disclaimer: This source code is provided "as is", without any
// warranty of any kind, express or implied, including but not
// limited to the warranties of merchantability or fitness for
// a particular purpose.
// ============================================================

import 'dart:typed_data';

import '../../d_bincode.dart';

/// A mixin that provides detailed debug logging for all BincodeWriter operations.
///
/// When applied to a class extending [BincodeWriter], this mixin overrides
/// each write method to print informative logs before delegating to the original implementation.
///
/// Example usage:
/// ```dart
/// class DebugWriter extends BincodeWriter with BincodeWriterDebugLogger {}
/// ```
mixin BincodeWriterDebugLogger on BincodeWriter {
  /// Logs a formatted debug message to stdout.
  void log(String message) {
    print('[BincodeDebug] $message');
  }

  // -------------------------
  // Base Write Methods
  // -------------------------

  @override void writeU8(int value) => _logWrap('writeU8', value, () => super.writeU8(value));
  @override void writeU16(int value) => _logWrap('writeU16', value, () => super.writeU16(value));
  @override void writeU32(int value) => _logWrap('writeU32', value, () => super.writeU32(value));
  @override void writeU64(int value) => _logWrap('writeU64', value, () => super.writeU64(value));

  @override void writeI8(int value) => _logWrap('writeI8', value, () => super.writeI8(value));
  @override void writeI16(int value) => _logWrap('writeI16', value, () => super.writeI16(value));
  @override void writeI32(int value) => _logWrap('writeI32', value, () => super.writeI32(value));
  @override void writeI64(int value) => _logWrap('writeI64', value, () => super.writeI64(value));

  @override void writeF32(double value) => _logWrap('writeF32', value, () => super.writeF32(value));
  @override void writeF64(double value) => _logWrap('writeF64', value, () => super.writeF64(value));

  @override void writeBool(bool value) => _logWrap('writeBool', value, () => super.writeBool(value));

  /// Logs and writes raw byte data.
  @override
  void writeBytes(List<int> bytes) {
    log('writeBytes: ${bytes.length} bytes');
    super.writeBytes(bytes);
  }

  /// Logs and writes a length-prefixed UTF-8 (or encoded) string.
  @override
  void writeString(String value, [StringEncoding encoding = StringEncoding.utf8]) {
    log('writeString: "$value" (encoding=${encoding.name})');
    super.writeString(value, encoding);
  }

  /// Logs and writes a fixed-length string with padding/truncation.
  @override
  void writeFixedString(String value, int length) {
    log('writeFixedString: "$value" (length=$length)');
    super.writeFixedString(value, length);
  }

  // -------------------------
  // Optional Write Methods
  // -------------------------

  @override void writeOptionU8(int? value) => _logOpt('writeOptionU8', value, () => super.writeOptionU8(value));
  @override void writeOptionU16(int? value) => _logOpt('writeOptionU16', value, () => super.writeOptionU16(value));
  @override void writeOptionU32(int? value) => _logOpt('writeOptionU32', value, () => super.writeOptionU32(value));
  @override void writeOptionU64(int? value) => _logOpt('writeOptionU64', value, () => super.writeOptionU64(value));

  @override void writeOptionI8(int? value) => _logOpt('writeOptionI8', value, () => super.writeOptionI8(value));
  @override void writeOptionI16(int? value) => _logOpt('writeOptionI16', value, () => super.writeOptionI16(value));
  @override void writeOptionI32(int? value) => _logOpt('writeOptionI32', value, () => super.writeOptionI32(value));
  @override void writeOptionI64(int? value) => _logOpt('writeOptionI64', value, () => super.writeOptionI64(value));

  @override void writeOptionF32(double? value) => _logOpt('writeOptionF32', value, () => super.writeOptionF32(value));
  @override void writeOptionF64(double? value) => _logOpt('writeOptionF64', value, () => super.writeOptionF64(value));

  @override void writeOptionBool(bool? value) => _logOpt('writeOptionBool', value, () => super.writeOptionBool(value));

  /// Logs and writes an optional UTF-8 string.
  @override
  void writeOptionString(String? value, [StringEncoding encoding = StringEncoding.utf8]) {
    log('writeOptionString: ${value ?? "None"} (encoding=${encoding.name})');
    super.writeOptionString(value, encoding);
  }

  /// Logs and writes an optional fixed-length string.
  @override
  void writeOptionFixedString(String? value, int length) {
    log('writeOptionFixedString: ${value ?? "None"} (length=$length)');
    super.writeOptionFixedString(value, length);
  }

  /// Logs and writes an optional Float32 vector with 3 elements.
  @override
  void writeOptionF32Triple(Float32List? vec3) {
    log('writeOptionF32Triple: ${vec3?.toString() ?? "None"}');
    super.writeOptionF32Triple(vec3);
  }

  // -------------------------
  // List Writes
  // -------------------------

  @override void writeInt8List(List<int> values) => _logList('writeInt8List', values.length, () => super.writeInt8List(values));
  @override void writeInt16List(List<int> values) => _logList('writeInt16List', values.length, () => super.writeInt16List(values));
  @override void writeInt32List(List<int> values) => _logList('writeInt32List', values.length, () => super.writeInt32List(values));
  @override void writeInt64List(List<int> values) => _logList('writeInt64List', values.length, () => super.writeInt64List(values));

  @override void writeUint8List(List<int> values) => _logList('writeUint8List', values.length, () => super.writeUint8List(values));
  @override void writeUint16List(List<int> values) => _logList('writeUint16List', values.length, () => super.writeUint16List(values));
  @override void writeUint32List(List<int> values) => _logList('writeUint32List', values.length, () => super.writeUint32List(values));
  @override void writeUint64List(List<int> values) => _logList('writeUint64List', values.length, () => super.writeUint64List(values));

  @override void writeFloat32List(List<double> values) => _logList('writeFloat32List', values.length, () => super.writeFloat32List(values));
  @override void writeFloat64List(List<double> values) => _logList('writeFloat64List', values.length, () => super.writeFloat64List(values));

  // -------------------------
  // Map / Collection Support
  // -------------------------

  /// Logs the total number of elements written using `writeList`.
  @override
  void writeList<T>(List<T> values, void Function(T value) writeElement) {
    log('writeList: ${values.length} item(s)');
    super.writeList(values, writeElement);
  }

  /// Logs the number of entries written using `writeMap`.
  @override
  void writeMap<K, V>(Map<K, V> values, void Function(K key) writeKey, void Function(V value) writeValue) {
    log('writeMap: ${values.length} entry/entries');
    super.writeMap(values, writeKey, writeValue);
  }

  // -------------------------
  // Internal Logging Helpers
  // -------------------------

  void _logWrap<T>(String label, T value, void Function() action) {
    log('$label: $value');
    action();
  }

  void _logOpt<T>(String label, T? value, void Function() action) {
    log('$label: ${value ?? "None"}');
    action();
  }

  void _logList(String label, int length, void Function() action) {
    log('$label: $length item(s)');
    action();
  }
}
