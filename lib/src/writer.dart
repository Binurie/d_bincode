// ============================================================
// Disclaimer: This source code is provided "as is", without any
// warranty of any kind, express or implied, including but not
// limited to the warranties of merchantability or fitness for
// a particular purpose.
// ============================================================

import 'dart:io';
import 'dart:typed_data';

import '../d_bincode.dart';

/// A low-level binary writer that encodes structured data in [Bincode] format.
///
/// This class provides methods to write primitive types, strings, optionals,
/// collections, and nested objects into an internal byte buffer that expands
/// automatically as needed. It supports seeking, rewinding, and writing to file.
/// 
/// ## Features
/// - Automatic buffer resizing
/// - Seek and rewind support
/// - Support for optional types and nested objects
/// - Little‑endian encoding for compact output
/// - Ability to write to file using [toFile()]
///
/// ## Example
/// ```dart
/// final writer = BincodeWriter();
/// writer.writeU32(42);
/// writer.writeString("hello");
/// await writer.toFile('output.bin');
/// ```
class BincodeWriter implements BincodeWriterBuilder {
  late ByteDataWrapper _wrapper;
  int _capacity;
  int _position = 0;

  /// Creates a new [BincodeWriter] with an optional [initialCapacity] (in bytes).
  ///
  /// The [initialCapacity] parameter determines the starting size of the buffer.
  /// The buffer automatically grows if additional space is needed.
  BincodeWriter([int initialCapacity = 128]) : _capacity = initialCapacity {
    _wrapper = ByteDataWrapper.allocate(_capacity);
  }

  // --- Positioning Methods ---

  /// Moves the write cursor by [offset] bytes relative to the current position.
  ///
  /// The [offset] may be positive (move forward) or negative (move backward).
  /// Throws a [RangeError] if the resulting position is invalid.
  @override
  void seek(int offset) {
    position += offset;
  }

  /// Returns the current write cursor position within the buffer.
  @override
  int get position => _wrapper.position;

  /// Sets the write cursor to an absolute byte position [value].
  ///
  /// Throws a [RangeError] if [value] is outside the valid range.
  @override
  set position(int value) {
    _wrapper.position = value;
  }

  /// Resets the write cursor to the beginning of the buffer.
  @override
  void rewind() {
    _wrapper.position = 0;
  }

  /// Moves the write cursor to the end of the written data.
  @override
  void skipToEnd() {
    _wrapper.position = _position;
  }

  /// Sets the write cursor to the absolute byte position [offset].
  @override
  void seekTo(int offset) {
    _wrapper.position = offset;
  }

  // --- Internal Buffer Management ---

  /// Ensures that there is at least [neededBytes] available in the buffer.
  ///
  /// If the current buffer does not have enough space, [_grow] is called to expand it.
  void _ensureCapacity(int neededBytes) {
    if (_position + neededBytes > _capacity) {
      _grow(_position + neededBytes);
    }
  }

  /// Expands the internal buffer so that its capacity is at least [minCapacity] bytes.
  ///
  /// The new capacity is chosen by doubling the current capacity, yet never lower than [minCapacity].
  void _grow(int minCapacity) {
    final newCapacity = (_capacity * 2).clamp(minCapacity, minCapacity * 2);
    final newWrapper = ByteDataWrapper.allocate(newCapacity);
    final oldBytes = _wrapper.buffer.asUint8List(0, _position);
    newWrapper.writeBytes(oldBytes);
    _wrapper = newWrapper;
    _capacity = newCapacity;
  }

  // --- Primitive Writing Methods ---

  /// Writes an unsigned 8‑bit integer [value] to the buffer.
  ///
  /// Throws an [InvalidWriteRangeException] if [value] is not in the range 0 to 255.
  @override
  void writeU8(int value) {
    if (value < 0 || value > 0xFF) {
      throw InvalidWriteRangeException(value, 'u8', minValue: 0, maxValue: 0xFF);
    }
    _ensureCapacity(1);
    _wrapper.writeUint8(value);
    _position += 1;
  }

  /// Writes an unsigned 16‑bit integer [value] to the buffer.
  ///
  /// Throws an [InvalidWriteRangeException] if [value] is not in the range 0 to 65535.
  @override
  void writeU16(int value) {
    if (value < 0 || value > 0xFFFF) {
      throw InvalidWriteRangeException(value, 'u16', minValue: 0, maxValue: 0xFFFF);
    }
    _ensureCapacity(2);
    _wrapper.writeUint16(value);
    _position += 2;
  }

  /// Writes an unsigned 32‑bit integer [value] to the buffer.
  ///
  /// Throws an [InvalidWriteRangeException] if [value] is not in the range 0 to 0xFFFFFFFF.
  @override
  void writeU32(int value) {
    if (value < 0 || value > 0xFFFFFFFF) {
      throw InvalidWriteRangeException(value, 'u32', minValue: 0, maxValue: 0xFFFFFFFF);
    }
    _ensureCapacity(4);
    _wrapper.writeUint32(value);
    _position += 4;
  }

  /// Writes an unsigned 64‑bit integer [value] to the buffer.
  ///
  /// The 64‑bit value is split into two 32‑bit parts (low and high).
  /// Throws an [InvalidWriteRangeException] if [value] is outside the valid range (0 to 2^64‑1).
  @override
  void writeU64(int value) {
    final BigInt maxU64 = BigInt.parse("18446744073709551615");
    final BigInt bigValue = BigInt.from(value);
    if (bigValue < BigInt.zero || bigValue > maxU64) {
      throw InvalidWriteRangeException(value, 'u64', minValue: 0, maxValue: maxU64);
    }
    _ensureCapacity(8);
    final int low = value & 0xFFFFFFFF;
    final int high = (value >> 32) & 0xFFFFFFFF;
    _wrapper.writeUint32(low);
    _wrapper.writeUint32(high);
    _position += 8;
  }

  /// Writes a signed 8‑bit integer [value] to the buffer.
  ///
  /// Throws an [InvalidWriteRangeException] if [value] is not in the range -128 to 127.
  @override
  void writeI8(int value) {
    if (value < -0x80 || value > 0x7F) {
      throw InvalidWriteRangeException(value, 'i8', minValue: -0x80, maxValue: 0x7F);
    }
    _ensureCapacity(1);
    _wrapper.writeInt8(value);
    _position += 1;
  }

  /// Writes a signed 16‑bit integer [value] to the buffer.
  ///
  /// Throws an [InvalidWriteRangeException] if [value] is not in the range -32768 to 32767.
  @override
  void writeI16(int value) {
    if (value < -0x8000 || value > 0x7FFF) {
      throw InvalidWriteRangeException(value, 'i16', minValue: -0x8000, maxValue: 0x7FFF);
    }
    _ensureCapacity(2);
    _wrapper.writeInt16(value);
    _position += 2;
  }

  /// Writes a signed 32‑bit integer [value] to the buffer.
  ///
  /// Throws an [InvalidWriteRangeException] if [value] is not in the range -2147483648 to 2147483647.
  @override
  void writeI32(int value) {
    if (value < -0x80000000 || value > 0x7FFFFFFF) {
      throw InvalidWriteRangeException(value, 'i32', minValue: -0x80000000, maxValue: 0x7FFFFFFF);
    }
    _ensureCapacity(4);
    _wrapper.writeInt32(value);
    _position += 4;
  }

  /// Writes a signed 64‑bit integer [value] to the buffer.
  ///
  /// Throws an [InvalidWriteRangeException] if [value] is not within the 64‑bit 2's complement range.
  @override
  void writeI64(int value) {
    final minI64 = -0x8000000000000000;
    final maxI64 = 0x7FFFFFFFFFFFFFFF;
    if (value < minI64 || value > maxI64) {
      throw InvalidWriteRangeException(value, 'i64', minValue: minI64, maxValue: maxI64);
    }
    _ensureCapacity(8);
    _wrapper.writeInt64(value);
    _position += 8;
  }

  /// Writes a 32‑bit floating point number [value] to the buffer using IEEE 754 format.
  @override
  void writeF32(double value) {
    _ensureCapacity(4);
    _wrapper.writeFloat32(value);
    _position += 4;
  }

  /// Writes a 64‑bit floating point number [value] to the buffer using IEEE 754 format.
  @override
  void writeF64(double value) {
    _ensureCapacity(8);
    _wrapper.writeFloat64(value);
    _position += 8;
  }

  /// Writes a boolean [value] to the buffer as a single byte (1 for true, 0 for false).
  @override
  void writeBool(bool value) {
    writeU8(value ? 1 : 0);
  }

  /// Writes the list of bytes [bytes] to the buffer.
  ///
  /// This method first ensures that there is sufficient space before writing.
  @override
  void writeBytes(List<int> bytes) {
    _ensureCapacity(bytes.length);
    _wrapper.writeBytes(bytes);
    _position += bytes.length;
  }

  /// Encodes the given string [value] using the specified [encoding]
  /// (default is UTF‑8), writes a u64 length prefix, then writes the bytes.
  @override
  void writeString(String value, [StringEncoding encoding = StringEncoding.utf8]) {
    final encoded = encodeString(value, encoding);
    writeU64(encoded.length);
    writeBytes(encoded);
  }

  /// Writes a fixed‑length string [value] to the buffer.
  ///
  /// If [value]'s code units are fewer than [length], the result is padded with zeros.
  /// If [value] is longer, it is truncated.
  @override
  void writeFixedString(String value, int length) {
    if (length < 0) {
      throw BincodeWriteException('Fixed string length cannot be negative: $length');
    }
    final codes = List<int>.filled(length, 0);
    final valueCodes = value.codeUnits;
    for (var i = 0; i < length; i++) {
      codes[i] = i < valueCodes.length ? valueCodes[i] : 0;
    }
    writeBytes(codes);
  }

  // --- Optional Value Writing Methods ---

  /// Writes an optional boolean [value] to the buffer.
  ///
  /// First writes a flag byte (1 if [value] is non-null, 0 if null), followed by the boolean value if present.
  @override
  void writeOptionBool(bool? value) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeBool(value);
  }

  /// Writes an optional unsigned 8‑bit integer [value] to the buffer.
  @override
  void writeOptionU8(int? value) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeU8(value);
  }

  /// Writes an optional unsigned 16‑bit integer [value] to the buffer.
  @override
  void writeOptionU16(int? value) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeU16(value);
  }

  /// Writes an optional unsigned 32‑bit integer [value] to the buffer.
  @override
  void writeOptionU32(int? value) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeU32(value);
  }

  /// Writes an optional unsigned 64‑bit integer [value] to the buffer.
  @override
  void writeOptionU64(int? value) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeU64(value);
  }

  /// Writes an optional signed 8‑bit integer [value] to the buffer.
  @override
  void writeOptionI8(int? value) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeI8(value);
  }

  /// Writes an optional signed 16‑bit integer [value] to the buffer.
  @override
  void writeOptionI16(int? value) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeI16(value);
  }

  /// Writes an optional signed 32‑bit integer [value] to the buffer.
  @override
  void writeOptionI32(int? value) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeI32(value);
  }

  /// Writes an optional signed 64‑bit integer [value] to the buffer.
  @override
  void writeOptionI64(int? value) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeI64(value);
  }

  /// Writes an optional 32‑bit floating point number [value] to the buffer.
  @override
  void writeOptionF32(double? value) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeF32(value);
  }

  /// Writes an optional 64‑bit floating point number [value] to the buffer.
  @override
  void writeOptionF64(double? value) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeF64(value);
  }

  /// Writes an optional string [value] (with optional [encoding], default UTF‑8) to the buffer.
  @override
  void writeOptionString(String? value, [StringEncoding encoding = StringEncoding.utf8]) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeString(value, encoding);
  }

  /// Writes an optional fixed‑length string [value] to the buffer.
  ///
  /// [length] specifies the fixed length in bytes.
  @override
  void writeOptionFixedString(String? value, int length) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeFixedString(value, length);
  }

  /// Writes an optional 3‑element [Float32List] [vec3] to the buffer.
  ///
  /// If [vec3] is null, writes a flag byte of 0 and then 12 zero bytes.
  /// If present, writes a flag byte of 1 followed by three 32‑bit floating point numbers.
  @override
  void writeOptionF32Triple(Float32List? vec3) {
    if (vec3 == null) {
      writeU8(0);
      writeBytes(List.filled(12, 0));
    } else if (vec3.length != 3) {
      throw BincodeWriteException('Expected Float32List with 3 elements, but got ${vec3.length}');
    } else {
      writeU8(1);
      for (var v in vec3) {
        writeF32(v);
      }
    }
  }

  // --- Collection Writing Methods ---

  /// Writes a list of values [values] to the buffer.
  ///
  /// First writes a u64 representing the list length, then calls [writeElement] for each element.
  @override
  void writeList<T>(List<T> values, void Function(T value) writeElement) {
    writeU64(values.length);
    for (final value in values) {
      writeElement(value);
    }
  }

  /// Writes a map of key-value pairs [values] to the buffer.
  ///
  /// First writes a u64 indicating the number of entries, then for each entry calls [writeKey] and [writeValue].
  @override
  void writeMap<K, V>(Map<K, V> values, void Function(K key) writeKey, void Function(V value) writeValue) {
    writeU64(values.length);
    for (final entry in values.entries) {
      writeKey(entry.key);
      writeValue(entry.value);
    }
  }

  /// Writes a list of signed 8‑bit integers [values] to the buffer.
  @override
  void writeInt8List(List<int> values) => values.forEach(writeI8);

  /// Writes a list of signed 16‑bit integers [values] to the buffer.
  @override
  void writeInt16List(List<int> values) => values.forEach(writeI16);

  /// Writes a list of signed 32‑bit integers [values] to the buffer.
  @override
  void writeInt32List(List<int> values) => values.forEach(writeI32);

  /// Writes a list of signed 64‑bit integers [values] to the buffer.
  @override
  void writeInt64List(List<int> values) => values.forEach(writeI64);

  /// Writes a list of unsigned 8‑bit integers [values] to the buffer.
  @override
  void writeUint8List(List<int> values) => values.forEach(writeU8);

  /// Writes a list of unsigned 16‑bit integers [values] to the buffer.
  @override
  void writeUint16List(List<int> values) => values.forEach(writeU16);

  /// Writes a list of unsigned 32‑bit integers [values] to the buffer.
  @override
  void writeUint32List(List<int> values) => values.forEach(writeU32);

  /// Writes a list of unsigned 64‑bit integers [values] to the buffer.
  @override
  void writeUint64List(List<int> values) => values.forEach(writeU64);

  /// Writes a list of 32‑bit floating point numbers [values] to the buffer.
  @override
  void writeFloat32List(List<double> values) => values.forEach(writeF32);

  /// Writes a list of 64‑bit floating point numbers [values] to the buffer.
  @override
  void writeFloat64List(List<double> values) => values.forEach(writeF64);

  /// Writes a nested [BincodeEncodable] object [value] to the buffer.
  ///
  /// The object is first serialized using [toBincode()], then its length and raw bytes are written.
  @override
  void writeNested(BincodeEncodable value) {
    final bytes = value.toBincode();
    writeU64(bytes.length);
    writeBytes(bytes);
  }
  
  /// Writes an optional nested [BincodeEncodable] object [value] to the buffer.
  ///
  /// Writes a flag byte of 1 if [value] is non-null, then writes the nested object.
  /// If [value] is null, writes a flag byte of 0.
  @override
  void writeOptionNested(BincodeEncodable? value) {
    if (value == null) {
      writeU8(0);
      return;
    }
    writeU8(1);
    writeNested(value);
  }

  // --- Final Output Methods ---

  /// Returns the portion of the buffer that has been written, as a [Uint8List].
  ///
  /// This is typically less than the allocated size if the buffer has grown.
  @override
  Uint8List toBytes() => _wrapper.buffer.asUint8List(0, _position);

  /// Writes the serialized data to a file located at [path].
  ///
  /// Only the portion of the buffer that contains data (up to the current write cursor)
  /// is written to the file.
  @override
  Future<void> toFile(String path) async {
    final trimmedBuffer = Uint8List.fromList(toBytes());
    await File(path).writeAsBytes(trimmedBuffer);
  }
}