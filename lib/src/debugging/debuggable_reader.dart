// ============================================================
// Disclaimer: This source code is provided "as is", without any
// warranty of any kind, express or implied, including but not
// limited to the warranties of merchantability or fitness for
// a particular purpose.
// ============================================================

import 'dart:typed_data';

import '../../d_bincode.dart';

/// A mixin that enables verbose debug logging for [BincodeReader] operations.
///
/// This mixin overrides all base, optional, list, and collection read methods
/// to log the read values and their contexts for debugging purposes.
///
/// Example:
/// ```dart
/// class DebugReader extends BincodeReader with BincodeReaderDebugLogger {
///   DebugReader(Uint8List bytes) : super(bytes);
/// }
/// ```
mixin BincodeReaderDebugLogger on BincodeReader {
  /// Logs a debug message to the console with `[BincodeDebug - Reader]` prefix.
  void log(String message) {
    print('[BincodeDebug - Reader] $message');
  }

  // -----------------------------
  // Primitive Read Methods
  // -----------------------------

  @override int readU8() => _log(super.readU8(), 'readU8');
  @override int readU16() => _log(super.readU16(), 'readU16');
  @override int readU32() => _log(super.readU32(), 'readU32');
  @override int readU64() => _log(super.readU64(), 'readU64');

  @override int readI8() => _log(super.readI8(), 'readI8');
  @override int readI16() => _log(super.readI16(), 'readI16');
  @override int readI32() => _log(super.readI32(), 'readI32');
  @override int readI64() => _log(super.readI64(), 'readI64');

  @override double readF32() => _log(super.readF32(), 'readF32');
  @override double readF64() => _log(super.readF64(), 'readF64');

  @override bool readBool() => _log(super.readBool(), 'readBool');

  @override
  List<int> readBytes(int count) {
    final value = super.readBytes(count);
    log('readBytes($count): $value');
    return value;
  }

  @override
  String readString([StringEncoding encoding = StringEncoding.utf8]) {
    final value = super.readString(encoding);
    log('readString: "$value" (encoding=${encoding.name})');
    return value;
  }

  @override
  String readFixedString(int length, {StringEncoding encoding = StringEncoding.utf8}) {
    final value = super.readFixedString(length, encoding: encoding);
    log('readFixedString: "$value" (length=$length, encoding=${encoding.name})');
    return value;
  }

  // -----------------------------
  // Optional Values
  // -----------------------------

  @override int? readOptionU8() => _logOpt(super.readOptionU8(), 'readOptionU8');
  @override int? readOptionU16() => _logOpt(super.readOptionU16(), 'readOptionU16');
  @override int? readOptionU32() => _logOpt(super.readOptionU32(), 'readOptionU32');
  @override int? readOptionU64() => _logOpt(super.readOptionU64(), 'readOptionU64');

  @override int? readOptionI8() => _logOpt(super.readOptionI8(), 'readOptionI8');
  @override int? readOptionI16() => _logOpt(super.readOptionI16(), 'readOptionI16');
  @override int? readOptionI32() => _logOpt(super.readOptionI32(), 'readOptionI32');
  @override int? readOptionI64() => _logOpt(super.readOptionI64(), 'readOptionI64');

  @override double? readOptionF32() => _logOpt(super.readOptionF32(), 'readOptionF32');
  @override double? readOptionF64() => _logOpt(super.readOptionF64(), 'readOptionF64');

  @override bool? readOptionBool() => _logOpt(super.readOptionBool(), 'readOptionBool');

  @override
  String? readOptionString([StringEncoding encoding = StringEncoding.utf8]) {
    final value = super.readOptionString(encoding);
    log('readOptionString: ${value ?? "None"} (encoding=${encoding.name})');
    return value;
  }

  @override
  String? readOptionFixedString(int length, {StringEncoding encoding = StringEncoding.utf8}) {
    final value = super.readOptionFixedString(length, encoding: encoding);
    log('readOptionFixedString: ${value ?? "None"} (length=$length, encoding=${encoding.name})');
    return value;
  }

  @override
  Float32List? readOptionF32Triple() {
    final value = super.readOptionF32Triple();
    log('readOptionF32Triple: ${value?.toList() ?? "None"}');
    return value;
  }

  // -----------------------------
  // Fixed-Length Lists
  // -----------------------------

  @override List<int> readInt8List(int length) => _log(super.readInt8List(length), 'readInt8List($length)');
  @override List<int> readInt16List(int length) => _log(super.readInt16List(length), 'readInt16List($length)');
  @override List<int> readInt32List(int length) => _log(super.readInt32List(length), 'readInt32List($length)');
  @override List<int> readInt64List(int length) => _log(super.readInt64List(length), 'readInt64List($length)');

  @override List<int> readUint8List(int length) => _log(super.readUint8List(length), 'readUint8List($length)');
  @override List<int> readUint16List(int length) => _log(super.readUint16List(length), 'readUint16List($length)');
  @override List<int> readUint32List(int length) => _log(super.readUint32List(length), 'readUint32List($length)');
  @override List<int> readUint64List(int length) => _log(super.readUint64List(length), 'readUint64List($length)');

  @override List<double> readFloat32List(int length) => _log(super.readFloat32List(length), 'readFloat32List($length)');
  @override List<double> readFloat64List(int length) => _log(super.readFloat64List(length), 'readFloat64List($length)');

  // -----------------------------
  // Collections
  // -----------------------------

  @override
  List<T> readList<T>(T Function() readElement) {
    final list = super.readList(readElement);
    log('readList: ${list.length} item(s)');
    return list;
  }

  @override
  Map<K, V> readMap<K, V>(K Function() readKey, V Function() readValue) {
    final map = super.readMap(readKey, readValue);
    log('readMap: ${map.length} entries');
    return map;
  }

  // -----------------------------
  // Private Logging Helpers
  // -----------------------------

  /// Logs and returns a value with the given [label].
  T _log<T>(T value, String label) {
    log('$label: $value');
    return value;
  }

  /// Logs an optional value or "None" with a [label].
  T? _logOpt<T>(T? value, String label) {
    log('$label: ${value ?? "None"}');
    return value;
  }
}
