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
/// and common collections directly to an internal byte buffer using an
/// expandable strategy. It's useful for efficient binary serialization,
/// especially for communicating with native (e.g., Rust) or binary-heavy systems.
///
/// ## Features
/// - Automatic buffer resizing
/// - Seek and rewind support
/// - Support for optional types (`Option<T>`)
/// - Compact output using little-endian encoding
/// - Writes to file with `toFile()`
///
/// ## Example
/// ```dart
/// final writer = BincodeWriter();
/// writer.writeU32(42);
/// writer.writeString("hello");
/// await writer.toFile('output.bin');
/// ```
class BincodeWriter implements BincodeBuilder {
  late ByteDataWrapper _wrapper;
  int _capacity;
  int _position = 0;

  /// Creates a new binary writer with an optional initial buffer size (in bytes).
  BincodeWriter([int initialCapacity = 128]) : _capacity = initialCapacity {
    _wrapper = ByteDataWrapper.allocate(_capacity);
  }

  /// Moves the cursor to a new position relative to the current one.
  ///
  /// For example, calling `seek(-4)` moves the cursor 4 bytes backward.
  /// Throws [RangeError] if the resulting position is invalid.
  void seek(int offset) {
    position += offset;
  }

  /// Current cursor position within the buffer.
  @override
  int get position => _wrapper.position;

  /// Set the absolute write cursor position.
  ///
  /// Useful to manually overwrite previously written data.
  @override
  set position(int value) {
    _wrapper.position = value;
  }

  /// Resets the write cursor to the beginning of the buffer.
  @override
  void rewind() {
    _wrapper.position = 0;
  }

  /// Moves the cursor to the end of the current written data.
  ///
  /// Use this after a `rewind()` or `seekTo()` to continue writing
  /// from the last known write position.
  @override
  void skipToEnd() {
    _wrapper.position = _position;
  }

  /// Moves the cursor to the absolute byte [offset].
  @override
  void seekTo(int offset) {
    _wrapper.position = offset;
  }

  void _ensureCapacity(int neededBytes) {
    if (_position + neededBytes > _capacity) {
      _grow(_position + neededBytes);
    }
  }

  void _grow(int minCapacity) {
    final newCapacity = (_capacity * 2).clamp(minCapacity, minCapacity * 2);
    final newWrapper = ByteDataWrapper.allocate(newCapacity);
    final oldBytes = _wrapper.buffer.asUint8List(0, _position);
    newWrapper.writeBytes(oldBytes);
    _wrapper = newWrapper;
    _capacity = newCapacity;
  }

  // === Primitive Writes ===

  @override
  void writeU8(int value) {
    _ensureCapacity(1);
    _wrapper.writeUint8(value);
    _position += 1;
  }

  @override
  void writeU16(int value) {
    _ensureCapacity(2);
    _wrapper.writeUint16(value);
    _position += 2;
  }

  @override
  void writeU32(int value) {
    _ensureCapacity(4);
    _wrapper.writeUint32(value);
    _position += 4;
  }

  @override
  void writeU64(int value) {
    _ensureCapacity(8);
    final low = value & 0xFFFFFFFF;
    final high = (value >> 32) & 0xFFFFFFFF;
    _wrapper.writeUint32(low);
    _wrapper.writeUint32(high);
    _position += 8;
  }

  @override
  void writeI8(int value) {
    _ensureCapacity(1);
    _wrapper.writeInt8(value);
    _position += 1;
  }

  @override
  void writeI16(int value) {
    _ensureCapacity(2);
    _wrapper.writeInt16(value);
    _position += 2;
  }

  @override
  void writeI32(int value) {
    _ensureCapacity(4);
    _wrapper.writeInt32(value);
    _position += 4;
  }

  @override
  void writeI64(int value) {
    _ensureCapacity(8);
    _wrapper.writeInt64(value);
    _position += 8;
  }

  @override
  void writeF32(double value) {
    _ensureCapacity(4);
    _wrapper.writeFloat32(value);
    _position += 4;
  }

  @override
  void writeF64(double value) {
    _ensureCapacity(8);
    _wrapper.writeFloat64(value);
    _position += 8;
  }

  @override
  void writeBool(bool value) {
    writeU8(value ? 1 : 0);
  }

  @override
  void writeBytes(List<int> bytes) {
    _ensureCapacity(bytes.length);
    _wrapper.writeBytes(bytes);
    _position += bytes.length;
  }

  @override
  void writeString(String value, [StringEncoding encoding = StringEncoding.utf8]) {
    final encoded = encodeString(value, encoding);
    writeU64(encoded.length);
    writeBytes(encoded);
  }

  @override
  void writeFixedString(String value, int length) {
    final codes = List<int>.filled(length, 0);
    final valueCodes = value.codeUnits;
    for (var i = 0; i < length; i++) {
      codes[i] = i < valueCodes.length ? valueCodes[i] : 0;
    }
    writeBytes(codes);
  }

  // === Optionals ===

  @override
  void writeOptionBool(bool? value) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeBool(value);
  }

  @override
  void writeOptionU8(int? value) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeU8(value);
  }

  @override
  void writeOptionU16(int? value) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeU16(value);
  }

  @override
  void writeOptionU32(int? value) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeU32(value);
  }

  @override
  void writeOptionU64(int? value) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeU64(value);
  }

  @override
  void writeOptionI8(int? value) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeI8(value);
  }

  @override
  void writeOptionI16(int? value) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeI16(value);
  }

  @override
  void writeOptionI32(int? value) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeI32(value);
  }

  @override
  void writeOptionI64(int? value) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeI64(value);
  }

  @override
  void writeOptionF32(double? value) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeF32(value);
  }

  @override
  void writeOptionF64(double? value) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeF64(value);
  }

  @override
  void writeOptionString(String? value, [StringEncoding encoding = StringEncoding.utf8]) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeString(value, encoding);
  }

  @override
  void writeOptionFixedString(String? value, int length) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeFixedString(value, length);
  }

  @override
  void writeOptionF32Triple(Float32List? vec3) {
    if (vec3 != null && vec3.length == 3) {
      writeU8(1);
      for (var v in vec3) writeF32(v);
    } else {
      writeU8(0);
      writeBytes(List.filled(12, 0));
    }
  }

  // === Collections ===

  @override
  void writeList<T>(List<T> values, void Function(T value) writeElement) {
    writeU64(values.length);
    for (final value in values) writeElement(value);
  }

  @override
  void writeMap<K, V>(Map<K, V> values, void Function(K key) writeKey, void Function(V value) writeValue) {
    writeU64(values.length);
    for (final entry in values.entries) {
      writeKey(entry.key);
      writeValue(entry.value);
    }
  }

  @override
  void writeInt8List(List<int> values) => values.forEach(writeI8);

  @override
  void writeInt16List(List<int> values) => values.forEach(writeI16);

  @override
  void writeInt32List(List<int> values) => values.forEach(writeI32);

  @override
  void writeInt64List(List<int> values) => values.forEach(writeI64);

  @override
  void writeUint8List(List<int> values) => values.forEach(writeU8);

  @override
  void writeUint16List(List<int> values) => values.forEach(writeU16);

  @override
  void writeUint32List(List<int> values) => values.forEach(writeU32);

  @override
  void writeUint64List(List<int> values) => values.forEach(writeU64);

  @override
  void writeFloat32List(List<double> values) => values.forEach(writeF32);

  @override
  void writeFloat64List(List<double> values) => values.forEach(writeF64);

  /// Returns the written portion of the buffer as a [Uint8List].
  @override
  Uint8List toBytes() => _wrapper.buffer.asUint8List(0, _position);

  /// Writes the serialized data to a binary file at [path].
  ///
  /// Only the used portion of the buffer is written, not the full allocated size.
  @override
  Future<void> toFile(String path) async {
    final trimmedBuffer = Uint8List.fromList(toBytes());
    await File(path).writeAsBytes(trimmedBuffer);
  }
}
