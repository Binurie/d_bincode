// ============================================================
// Disclaimer: This source code is provided "as is", without any
// warranty of any kind, express or implied, including but not
// limited to the warranties of merchantability or fitness for
// a particular purpose.
// ============================================================

import 'dart:typed_data';

import '../d_bincode.dart';

/// A binary reader that decodes data encoded in the [Bincode] format.
///
/// This class supports reading primitives, optionals, strings, collections, and
/// nested objects from binary data using an internal [ByteDataWrapper].
///
/// Example:
/// ```dart
/// final reader = BincodeReader(encodedBytes);
/// final id = reader.readU32();
/// final name = reader.readString();
/// ```
class BincodeReader implements BincodeReaderBuilder {
  final ByteDataWrapper _wrapper;

  /// Creates a new [BincodeReader] from the provided [bytes].
  ///
  /// [bytes] must be a [Uint8List] containing the binary data.
  BincodeReader(Uint8List bytes)
      : _wrapper = ByteDataWrapper(bytes.buffer, length: bytes.length);

  /// Asynchronously creates a [BincodeReader] from a file at the given [path].
  ///
  /// Returns a [Future] that completes with the [BincodeReader] after reading the file.
  static Future<BincodeReader> fromFile(String path) async {
    final wrapper = await ByteDataWrapper.fromFile(path);
    return BincodeReader(wrapper.buffer.asUint8List());
  }

  // -----------------------------
  // Positioning
  // -----------------------------

  /// Gets the current read cursor position in the binary data.
  @override
  int get position => _wrapper.position;

  /// Sets the current read cursor position to [value].
  ///
  /// Throws a [RangeError] if [value] is not within the valid range.
  @override
  set position(int value) => _wrapper.position = value;

  /// Moves the read cursor by [offset] bytes.
  ///
  /// A positive [offset] moves forward; a negative [offset] moves backward.
  @override
  void seek(int offset) => position += offset;

  /// Sets the read cursor to the absolute byte position [absolutePosition].
  @override
  void seekTo(int absolutePosition) => position = absolutePosition;

  /// Resets the read cursor to the beginning (position 0).
  @override
  void rewind() => position = 0;

  /// Moves the read cursor to the end of the available data.
  @override
  void skipToEnd() => position = _wrapper.length;

  // -----------------------------
  // Primitives
  // -----------------------------

  /// Reads an unsigned 8-bit integer from the binary data.
  ///
  /// Returns the value as an [int]. Throws a [BincodeException] if the data is insufficient.
  @override
  int readU8() => _readOrThrow(() => _wrapper.readUint8(), "u8");

  /// Reads an unsigned 16-bit integer from the binary data.
  ///
  /// Returns the value as an [int]. Throws a [BincodeException] if the data is insufficient.
  @override
  int readU16() => _readOrThrow(() => _wrapper.readUint16(), "u16");

  /// Reads an unsigned 32-bit integer from the binary data.
  ///
  /// Returns the value as an [int]. Throws a [BincodeException] if the data is insufficient.
  @override
  int readU32() => _readOrThrow(() => _wrapper.readUint32(), "u32");

  /// Reads an unsigned 64-bit integer from the binary data.
  ///
  /// The value is read as two 32-bit values (low and high parts) and combined.
  /// Returns the resulting [int]. Throws a [BincodeException] if the data is insufficient.
  @override
  int readU64() {
    final low = _readOrThrow(() => _wrapper.readUint32(), "low part of u64");
    final high = _readOrThrow(() => _wrapper.readUint32(), "high part of u64");
    return (high << 32) | low;
  }

  /// Reads a signed 8-bit integer from the binary data.
  ///
  /// Returns the value as an [int]. Throws a [BincodeException] if the data is insufficient.
  @override
  int readI8() => _readOrThrow(() => _wrapper.readInt8(), "i8");

  /// Reads a signed 16-bit integer from the binary data.
  ///
  /// Returns the value as an [int]. Throws a [BincodeException] if the data is insufficient.
  @override
  int readI16() => _readOrThrow(() => _wrapper.readInt16(), "i16");

  /// Reads a signed 32-bit integer from the binary data.
  ///
  /// Returns the value as an [int]. Throws a [BincodeException] if the data is insufficient.
  @override
  int readI32() => _readOrThrow(() => _wrapper.readInt32(), "i32");

  /// Reads a signed 64-bit integer from the binary data.
  ///
  /// Returns the value as an [int]. Throws a [BincodeException] if the data is insufficient.
  @override
  int readI64() => _readOrThrow(() => _wrapper.readInt64(), "i64");

  /// Reads a 32-bit floating point number from the binary data.
  ///
  /// Returns the value as a [double]. Throws a [BincodeException] if the data is insufficient.
  @override
  double readF32() => _readOrThrow(() => _wrapper.readFloat32(), "f32");

  /// Reads a 64-bit floating point number from the binary data.
  ///
  /// Returns the value as a [double]. Throws a [BincodeException] if the data is insufficient.
  @override
  double readF64() => _readOrThrow(() => _wrapper.readFloat64(), "f64");

  /// Reads a list of [count] bytes from the binary data.
  ///
  /// Returns a [List<int>] of the read bytes.
  @override
  List<int> readBytes(int count) =>
      _readOrThrow(() => _wrapper.asUint8List(count), "$count bytes");

  // -----------------------------
  // Boolean
  // -----------------------------

  /// Reads a boolean value stored as a single byte (0 for false, 1 for true).
  ///
  /// Returns `true` or `false`. Throws [InvalidBooleanValueException] if the byte is not 0 or 1.
  @override
  bool readBool() {
    final value = readU8();
    if (value != 0 && value != 1) {
      throw InvalidBooleanValueException(value);
    }
    return value == 1;
  }

  // -----------------------------
  // String Encoding
  // -----------------------------

  /// Reads a string with a u64 length prefix.
  ///
  /// The method first reads a u64 value specifying the length in bytes, then reads that many bytes and decodes them as a string.
  /// The [encoding] parameter specifies the string encoding and defaults to UTF‑8.
  @override
  String readString([StringEncoding encoding = StringEncoding.utf8]) {
    final length = readU64();
    return readFixedString(length, encoding: encoding);
  }

  /// Reads a fixed-length string from the binary data.
  ///
  /// [length] specifies the number of bytes to read.
  /// The [encoding] parameter defines the character encoding (default is UTF‑8).
  /// Throws a [BincodeException] if the data cannot be read.
  @override
  String readFixedString(int length, {StringEncoding encoding = StringEncoding.utf8}) {
    return _readOrThrow(() => _wrapper.readString(length, encoding: encoding),
        "fixed string of length $length");
  }

  /// Reads a fixed-length string and removes trailing null (`\x00`) padding.
  ///
  /// [length] is the number of bytes allocated for the string.
  /// The [encoding] parameter specifies the character encoding (defaults to UTF‑8).
  @override
  String readCleanFixedString(int length, {StringEncoding encoding = StringEncoding.utf8}) {
    return readFixedString(length, encoding: encoding).replaceAll('\x00', '');
  }

  // -----------------------------
  // Optionals
  // -----------------------------

  /// Reads an optional boolean value.
  ///
  /// First reads a flag byte: 1 indicates the boolean value is present, 0 indicates None.
  /// Returns the boolean value if present, otherwise returns null.
  @override
  bool? readOptionBool() =>
      _readOptional<bool>(readBool, () => readU8());

  /// Reads an optional unsigned 8-bit integer.
  @override
  int? readOptionU8() =>
      _readOptional<int>(readU8, () => readU8());

  /// Reads an optional unsigned 16-bit integer.
  @override
  int? readOptionU16() =>
      _readOptional<int>(readU16, () => readU8());

  /// Reads an optional unsigned 32-bit integer.
  @override
  int? readOptionU32() =>
      _readOptional<int>(readU32, () => readU8());

  /// Reads an optional unsigned 64-bit integer.
  @override
  int? readOptionU64() =>
      _readOptional<int>(readU64, () => readU8());

  /// Reads an optional signed 8-bit integer.
  @override
  int? readOptionI8() =>
      _readOptional<int>(readI8, () => readU8());

  /// Reads an optional signed 16-bit integer.
  @override
  int? readOptionI16() =>
      _readOptional<int>(readI16, () => readU8());

  /// Reads an optional signed 32-bit integer.
  @override
  int? readOptionI32() =>
      _readOptional<int>(readI32, () => readU8());

  /// Reads an optional signed 64-bit integer.
  @override
  int? readOptionI64() =>
      _readOptional<int>(readI64, () => readU8());

  /// Reads an optional 32-bit floating point number.
  @override
  double? readOptionF32() =>
      _readOptional<double>(readF32, () => readU8());

  /// Reads an optional 64-bit floating point number.
  @override
  double? readOptionF64() =>
      _readOptional<double>(readF64, () => readU8());

  /// Reads an optional string with the specified [encoding].
  @override
  String? readOptionString([StringEncoding encoding = StringEncoding.utf8]) =>
      _readOptional<String>(() => readString(encoding), () => readU8());

  /// Reads an optional fixed-length string.
  ///
  /// [length] specifies the number of bytes allocated for the string.
  @override
  String? readOptionFixedString(int length, {StringEncoding encoding = StringEncoding.utf8}) =>
      _readOptional<String>(() => readFixedString(length, encoding: encoding), () => readU8());

  /// Reads an optional fixed-length string and removes trailing null characters.
  @override
  String? readCleanOptionFixedString(int length, {StringEncoding encoding = StringEncoding.utf8}) {
    return readOptionFixedString(length, encoding: encoding)?.replaceAll('\x00', '');
  }

  /// Reads an optional 3-element [Float32List].
  ///
  /// The first byte is a flag (1 if present, 0 if None). If the vector is present,
  /// reads three 32-bit floating point numbers. If absent, skips 12 bytes and returns null.
  @override
  Float32List? readOptionF32Triple() {
    final tag = readU8();
    if (tag != 0 && tag != 1) {
      throw InvalidOptionTagException(tag);
    }
    if (tag == 1) {
      return Float32List.fromList([readF32(), readF32(), readF32()]);
    } else {
      readBytes(12); // Skip 12 placeholder bytes.
      return null;
    }
  }

  // -----------------------------
  // Collections
  // -----------------------------

  /// Reads a list of elements from the binary data.
  ///
  /// The list length is first read as a u64. Then [readElement] is called repeatedly
  /// to populate the list.
  @override
  List<T> readList<T>(T Function() readElement) {
    final length = readU64();
    return List<T>.generate(length, (_) => readElement());
  }

  /// Reads a map from the binary data.
  ///
  /// The number of key-value pairs is read as a u64. Then, [readKey] and [readValue]
  /// are called for each entry.
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

  /// Reads a list of 32-bit floating point numbers of the specified [length].
  @override
  List<double> readFloat32List(int length) =>
      _readOrThrow(() => _wrapper.readFloat32List(length), "Float32 list of length $length");

  /// Reads a list of 64-bit floating point numbers of the specified [length].
  @override
  List<double> readFloat64List(int length) =>
      _readOrThrow(() => _wrapper.readFloat64List(length), "Float64 list of length $length");

  /// Reads a list of signed 8-bit integers of the specified [length].
  @override
  List<int> readInt8List(int length) =>
      _readOrThrow(() => _wrapper.readInt8List(length), "Int8 list of length $length");

  /// Reads a list of signed 16-bit integers of the specified [length].
  @override
  List<int> readInt16List(int length) =>
      _readOrThrow(() => _wrapper.readInt16List(length), "Int16 list of length $length");

  /// Reads a list of signed 32-bit integers of the specified [length].
  @override
  List<int> readInt32List(int length) =>
      _readOrThrow(() => _wrapper.readInt32List(length), "Int32 list of length $length");

  /// Reads a list of signed 64-bit integers of the specified [length].
  @override
  List<int> readInt64List(int length) =>
      _readOrThrow(() => _wrapper.readInt64List(length), "Int64 list of length $length");

  /// Reads a list of unsigned 8-bit integers of the specified [length].
  @override
  List<int> readUint8List(int length) =>
      _readOrThrow(() => _wrapper.readUint8List(length), "Uint8 list of length $length");

  /// Reads a list of unsigned 16-bit integers of the specified [length].
  @override
  List<int> readUint16List(int length) =>
      _readOrThrow(() => _wrapper.readUint16List(length), "Uint16 list of length $length");

  /// Reads a list of unsigned 32-bit integers of the specified [length].
  @override
  List<int> readUint32List(int length) =>
      _readOrThrow(() => _wrapper.readUint32List(length), "Uint32 list of length $length");

  /// Reads a list of unsigned 64-bit integers of the specified [length].
  @override
  List<int> readUint64List(int length) =>
      _readOrThrow(() => _wrapper.readUint64List(length), "Uint64 list of length $length");

  /// Returns the entire underlying byte buffer as a [Uint8List].
  @override
  Uint8List toBytes() => _wrapper.buffer.asUint8List();

  // -----------------------------
  // Nested Objects
  // -----------------------------

  /// Reads and decodes a nested object from the binary data.
  ///
  /// It reads a u64 indicating the byte-length of the nested object,
  /// then reads that many bytes and loads them into [instance] using its [loadFromBytes] method.
  ///
  /// Returns the modified instance.
  @override
  T readNestedObject<T extends BincodeDecodable>(T instance) {
    final length = readU64();
    final bytes = Uint8List.fromList(readBytes(length));
    instance.loadFromBytes(bytes);
    return instance;
  }

  /// Reads an optional nested object.
  ///
  /// The first byte indicates presence (1 for present, 0 for absent).
  /// If present, it reads a u64 for the byte-length and then loads the object using the provided [creator].
  ///
  /// Returns an instance of [T] if present, or `null` otherwise.
  @override
  T? readOptionNestedObject<T extends BincodeDecodable>(T Function() creator) {
    final tag = readU8();
    if (tag == 0) return null;
    final length = readU64();
    final bytes = Uint8List.fromList(readBytes(length));
    final instance = creator();
    instance.loadFromBytes(bytes);
    return instance;
  }
}

/// Helper function that wraps a byte-read operation and rethrows errors as a [BincodeException].
///
/// [readFn] is the function that performs the read.
/// [description] is a textual description of the data being read.
T _readOrThrow<T>(T Function() readFn, String description) {
  try {
    return readFn();
  } on RangeError {
    throw UnexpectedEndOfBufferException();
  } catch (e) {
    throw BincodeException("Error reading $description", e);
  }
}

/// Helper to read an optional value.
/// [readFn] reads the value itself.
/// [readTagFn] reads the flag indicating whether the value is present (should return 0 or 1).
///
/// Returns the value if present, or `null` otherwise.
/// Throws [InvalidOptionTagException] if the tag is not 0 or 1.
T? _readOptional<T>(T Function() readFn, int Function() readTagFn) {
  final tag = readTagFn();
  if (tag != 0 && tag != 1) {
    throw InvalidOptionTagException(tag);
  }
  return tag == 1 ? readFn() : null;
}