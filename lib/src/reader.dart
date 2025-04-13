// ============================================================
// Disclaimer: This source code is provided "as is", without any
// warranty of any kind, express or implied, including but not
// limited to the warranties of merchantability or fitness for
// a particular purpose.
// ============================================================

import 'dart:typed_data';

import '../d_bincode.dart';

/// A binary reader that decodes data encoded in [Bincode] format.
///
/// This reader supports primitives, optionals, strings, lists, maps, and
/// fixed-length or zero-terminated strings. It maintains an internal cursor
/// position for reading sequentially.
///
/// Typically used for deserializing binary-encoded Dart or Rust data.
///
/// Example:
/// ```dart
/// final reader = BincodeReader(bytes);
/// final id = reader.readU32();
/// final name = reader.readString();
/// ```
class BincodeReader implements BincodeReaderBuilder {
  final ByteDataWrapper _wrapper;

  /// Constructs a [BincodeReader] from a byte array.
  ///
  /// The internal cursor starts at position 0.
  BincodeReader(Uint8List bytes)
      : _wrapper = ByteDataWrapper(bytes.buffer, length: bytes.length);

  /// Reads a file and returns a [BincodeReader] for its contents.
  ///
  /// This method supports large files and reads them into memory.
  static Future<BincodeReader> fromFile(String path) async {
    final wrapper = await ByteDataWrapper.fromFile(path);
    return BincodeReader(wrapper.buffer.asUint8List());
  }

  // -----------------------------
  // Positioning
  // -----------------------------

  /// The current read cursor position.
  @override
  int get position => _wrapper.position;

  /// Sets the read position explicitly.
  ///
  /// Throws [RangeError] if the position is out of bounds.
  @override
  set position(int value) => _wrapper.position = value;

  /// Moves the read cursor by [offset] bytes.
  ///
  /// Offset can be negative to move backward.
  @override
  void seek(int offset) => position += offset;

  /// Moves the read cursor to absolute [absolutePosition].
  @override
  void seekTo(int absolutePosition) => position = absolutePosition;

  /// Resets the read cursor to the beginning (position 0).
  @override
  void rewind() => position = 0;

  /// Moves the cursor to the end of the readable view.
  ///
  /// Typically used to skip remaining unread content.
  @override
  void skipToEnd() => position = _wrapper.length;

  // -----------------------------
  // Primitives
  // -----------------------------

  @override
  int readU8() => _wrapper.readUint8();
  @override
  int readU16() => _wrapper.readUint16();
  @override
  int readU32() => _wrapper.readUint32();
  @override
  int readU64() {
    final low = _wrapper.readUint32();
    final high = _wrapper.readUint32();
    return (high << 32) | low;
  }

  @override
  int readI8() => _wrapper.readInt8();
  @override
  int readI16() => _wrapper.readInt16();
  @override
  int readI32() => _wrapper.readInt32();
  @override
  int readI64() => _wrapper.readInt64();

  @override
  double readF32() => _wrapper.readFloat32();
  @override
  double readF64() => _wrapper.readFloat64();

  @override
  List<int> readBytes(int count) => _wrapper.asUint8List(count);

  /// Reads a boolean value (stored as 0 or 1).
  ///
  /// Throws [FormatException] if value is not 0 or 1.
  @override
  bool readBool() {
    final value = readU8();
    if (value != 0 && value != 1) {
      throw FormatException("Invalid boolean value: $value");
    }
    return value == 1;
  }

  /// Reads a UTF-8 or encoded string with a u64 byte-length prefix.
  @override
  String readString([StringEncoding encoding = StringEncoding.utf8]) {
    final length = readU64();
    return readFixedString(length, encoding: encoding);
  }

  /// Reads a fixed-length string. May contain padding (`\x00`).
  @override
  String readFixedString(int length,
      {StringEncoding encoding = StringEncoding.utf8}) {
    return _wrapper.readString(length, encoding: encoding);
  }

  /// Like [readFixedString] but trims all `\x00` padding.
  String readCleanFixedString(int length,
      {StringEncoding encoding = StringEncoding.utf8}) {
    return readFixedString(length, encoding: encoding).replaceAll('\x00', '');
  }

  // -----------------------------
  // Optionals
  // -----------------------------

  T? _readOptional<T>(T Function() readFn) {
    final flag = readU8();
    return flag == 1 ? readFn() : null;
  }

  @override
  bool? readOptionBool() => _readOptional(readBool);
  @override
  int? readOptionU8() => _readOptional(readU8);
  @override
  int? readOptionU16() => _readOptional(readU16);
  @override
  int? readOptionU32() => _readOptional(readU32);
  @override
  int? readOptionU64() => _readOptional(readU64);
  @override
  int? readOptionI8() => _readOptional(readI8);
  @override
  int? readOptionI16() => _readOptional(readI16);
  @override
  int? readOptionI32() => _readOptional(readI32);
  @override
  int? readOptionI64() => _readOptional(readI64);
  @override
  double? readOptionF32() => _readOptional(readF32);
  @override
  double? readOptionF64() => _readOptional(readF64);
  @override
  String? readOptionString([StringEncoding encoding = StringEncoding.utf8]) =>
      _readOptional(() => readString(encoding));
  @override
  String? readOptionFixedString(int length,
          {StringEncoding encoding = StringEncoding.utf8}) =>
      _readOptional(() => readFixedString(length, encoding: encoding));

  /// Reads a nullable fixed-length string and strips `\x00` if present.
  String? readCleanOptionFixedString(int length,
      {StringEncoding encoding = StringEncoding.utf8}) {
    return readOptionFixedString(length, encoding: encoding)
        ?.replaceAll('\x00', '');
  }

  /// Reads an optional 3-element [Float32List].
  ///
  /// If null, consumes 13 bytes (1 tag + 12 placeholder zeros).
  @override
  Float32List? readOptionF32Triple() {
    final flag = readU8();
    if (flag == 1) {
      return Float32List.fromList([readF32(), readF32(), readF32()]);
    } else {
      readBytes(12); // skip
      return null;
    }
  }

  // -----------------------------
  // Collections
  // -----------------------------

  /// Reads a list encoded with a u64 length prefix.
  @override
  List<T> readList<T>(T Function() readElement) {
    final length = readU64();
    return List<T>.generate(length, (_) => readElement());
  }

  /// Reads a map with u64 length prefix, followed by key-value pairs.
  @override
  Map<K, V> readMap<K, V>(K Function() readKey, V Function() readValue) {
    final length = readU64();
    final result = <K, V>{};
    for (int i = 0; i < length; i++) {
      final key = readKey();
      final value = readValue();
      result[key] = value;
    }
    return result;
  }

  // -----------------------------
  // Numeric Lists
  // -----------------------------

  @override
  List<double> readFloat32List(int length) => _wrapper.readFloat32List(length);
  @override
  List<double> readFloat64List(int length) => _wrapper.readFloat64List(length);
  @override
  List<int> readInt8List(int length) => _wrapper.readInt8List(length);
  @override
  List<int> readInt16List(int length) => _wrapper.readInt16List(length);
  @override
  List<int> readInt32List(int length) => _wrapper.readInt32List(length);
  @override
  List<int> readInt64List(int length) => _wrapper.readInt64List(length);
  @override
  List<int> readUint8List(int length) => _wrapper.readUint8List(length);
  @override
  List<int> readUint16List(int length) => _wrapper.readUint16List(length);
  @override
  List<int> readUint32List(int length) => _wrapper.readUint32List(length);
  @override
  List<int> readUint64List(int length) => _wrapper.readUint64List(length);

  /// Returns the entire underlying byte buffer.
  ///
  /// This may include unread portions or skipped data.
  @override
  Uint8List toBytes() => _wrapper.buffer.asUint8List();
}
