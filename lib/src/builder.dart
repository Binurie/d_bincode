// ============================================================
// Disclaimer: This source code is provided "as is", without any
// warranty of any kind, express or implied, including but not
// limited to the warranties of merchantability or fitness for
// a particular purpose.
// ============================================================

import 'dart:typed_data';

import '../d_bincode.dart';

/// Abstract interface for writing bincode‐formatted data.
abstract class BincodeWriterBuilder {
  /// Gets the current write cursor position in bytes.
  int get position;

  /// Sets the write cursor to the given [value] (in bytes).
  ///
  /// Throws a [RangeError] if the [value] is outside the valid range.
  set position(int value);

  // -- Cursor / Positioning Methods --

  /// Moves the cursor by an [offset] relative to its current position.
  ///
  /// If [offset] is negative, the cursor moves backward.
  void seek(int offset);

  /// Moves the cursor to the specified absolute position [absolutePosition].
  void seekTo(int absolutePosition);

  /// Resets the cursor to the beginning (position 0).
  void rewind();

  /// Moves the cursor to the end of the written data.
  void skipToEnd();

  // -- Base Write Methods --

  /// Writes an unsigned 8‑bit integer [value] to the output.
  void writeU8(int value);

  /// Writes an unsigned 16‑bit integer [value] to the output.
  void writeU16(int value);

  /// Writes an unsigned 32‑bit integer [value] to the output.
  void writeU32(int value);

  /// Writes an unsigned 64‑bit integer [value] to the output.
  void writeU64(int value);

  /// Writes a signed 8‑bit integer [value] to the output.
  void writeI8(int value);

  /// Writes a signed 16‑bit integer [value] to the output.
  void writeI16(int value);

  /// Writes a signed 32‑bit integer [value] to the output.
  void writeI32(int value);

  /// Writes a signed 64‑bit integer [value] to the output.
  void writeI64(int value);

  /// Writes a 32‑bit floating‑point [value] to the output.
  void writeF32(double value);

  /// Writes a 64‑bit floating‑point [value] to the output.
  void writeF64(double value);

  /// Writes a boolean [value] to the output.
  ///
  /// Booleans are represented as 0 (false) or 1 (true).
  void writeBool(bool value);

  /// Writes a list of bytes [bytes] to the output.
  void writeBytes(List<int> bytes);

  /// Writes a length‑prefixed string [value] using the specified [encoding].
  ///
  /// The method first writes the length of the encoded string as an unsigned 64‑bit integer,
  /// followed by the encoded bytes.
  /// The default [encoding] is UTF‑8.
  void writeString(String value, [StringEncoding encoding = StringEncoding.utf8]);

  /// Writes a fixed‑length string [value], padding with zeros if necessary.
  ///
  /// If [value] is shorter than [length] bytes, the output is padded with zeros.
  /// If it is longer, it is truncated.
  void writeFixedString(String value, int length);

  // -- Optional Write Methods --

  /// Writes an optional boolean [value].
  ///
  /// Writes a tag (1 for Some, 0 for None) followed by the boolean (if present).
  void writeOptionBool(bool? value);

  /// Writes an optional unsigned 8‑bit integer [value].
  void writeOptionU8(int? value);

  /// Writes an optional unsigned 16‑bit integer [value].
  void writeOptionU16(int? value);

  /// Writes an optional unsigned 32‑bit integer [value].
  void writeOptionU32(int? value);

  /// Writes an optional unsigned 64‑bit integer [value].
  void writeOptionU64(int? value);

  /// Writes an optional signed 8‑bit integer [value].
  void writeOptionI8(int? value);

  /// Writes an optional signed 16‑bit integer [value].
  void writeOptionI16(int? value);

  /// Writes an optional signed 32‑bit integer [value].
  void writeOptionI32(int? value);

  /// Writes an optional signed 64‑bit integer [value].
  void writeOptionI64(int? value);

  /// Writes an optional 32‑bit floating‑point [value].
  void writeOptionF32(double? value);

  /// Writes an optional 64‑bit floating‑point [value].
  void writeOptionF64(double? value);

  /// Writes an optional 3‑element Float32List [vec3].
  ///
  /// Expects a [Float32List] of exactly 3 elements, or null.
  void writeOptionF32Triple(Float32List? vec3);

  /// Writes an optional string [value] using the specified [encoding].
  ///
  /// Writes a tag (1 for Some, 0 for None) followed by the string (if present).
  void writeOptionString(String? value, [StringEncoding encoding = StringEncoding.utf8]);

  /// Writes an optional fixed‑length string [value] of given [length].
  void writeOptionFixedString(String? value, int length);

  // -- Collection Write Methods --

  /// Writes a list [values] by first writing its length (as a u64) followed by each element.
  ///
  /// The [writeElement] callback is used to serialize each individual element.
  void writeList<T>(List<T> values, void Function(T value) writeElement);

  /// Writes a map [values] by first writing its length (as a u64) followed by each key/value pair.
  ///
  /// The [writeKey] and [writeValue] callbacks are used to serialize the keys and values.
  void writeMap<K, V>(Map<K, V> values, void Function(K key) writeKey, void Function(V value) writeValue);

  // -- Primitive List Helper Methods --

  /// Writes a list of signed 8‑bit integers [values].
  void writeInt8List(List<int> values);

  /// Writes a list of signed 16‑bit integers [values].
  void writeInt16List(List<int> values);

  /// Writes a list of signed 32‑bit integers [values].
  void writeInt32List(List<int> values);

  /// Writes a list of signed 64‑bit integers [values].
  void writeInt64List(List<int> values);

  /// Writes a list of unsigned 8‑bit integers [values].
  void writeUint8List(List<int> values);

  /// Writes a list of unsigned 16‑bit integers [values].
  void writeUint16List(List<int> values);

  /// Writes a list of unsigned 32‑bit integers [values].
  void writeUint32List(List<int> values);

  /// Writes a list of unsigned 64‑bit integers [values].
  void writeUint64List(List<int> values);

  /// Writes a list of 32‑bit floating‑point values [values].
  void writeFloat32List(List<double> values);

  /// Writes a list of 64‑bit floating‑point values [values].
  void writeFloat64List(List<double> values);

  /// Writes a nested encodable [nested] object.
  ///
  /// The object is serialized into bytes (with its length) and then written.
  void writeNested(BincodeEncodable nested);

  /// Writes an optional nested encodable object [nested].
  ///
  /// Writes a tag (1 for Some, 0 for None) and, if not null, serializes the object.
  void writeOptionNested(BincodeEncodable? nested);

  // -- Output Methods --

  /// Asynchronously writes the current buffer content (up to the current position) to the file at [path].
  ///
  /// Only the used portion of the buffer is written, not the full allocated size.
  Future<void> toFile(String path);

  /// Returns the written portion of the buffer as a [Uint8List].
  Uint8List toBytes();
}


/// Abstract interface for reading bincode‐formatted data.
///
/// Implementations of this interface are responsible for reading primitive
/// types, collections, and nested decodable objects from a binary buffer.
/// The reader supports operations such as seeking, rewinding, and accessing the underlying bytes.
abstract class BincodeReaderBuilder {
  /// Gets the current read cursor position (in bytes).
  int get position;

  /// Sets the read cursor position to [value].
  ///
  /// Throws a [RangeError] if [value] is outside the valid buffer range.
  set position(int value);

  // -- Cursor / Positioning Methods --

  /// Moves the cursor by an [offset] relative to its current position.
  ///
  /// If [offset] is negative, the cursor moves backward.
  void seek(int offset);

  /// Moves the cursor to the given absolute position [absolutePosition].
  void seekTo(int absolutePosition);

  /// Rewinds the cursor to the beginning (position 0).
  void rewind();

  /// Moves the cursor to the end of the readable portion of the buffer.
  void skipToEnd();

  // -- Base Read Methods --

  /// Reads an unsigned 8‑bit integer from the current position.
  ///
  /// Advances the cursor by 1 byte.
  int readU8();

  /// Reads an unsigned 16‑bit integer from the current position.
  ///
  /// Advances the cursor by 2 bytes.
  int readU16();

  /// Reads an unsigned 32‑bit integer from the current position.
  ///
  /// Advances the cursor by 4 bytes.
  int readU32();

  /// Reads an unsigned 64‑bit integer from the current position.
  ///
  /// Advances the cursor by 8 bytes.
  int readU64();

  /// Reads a signed 8‑bit integer from the current position.
  int readI8();

  /// Reads a signed 16‑bit integer from the current position.
  int readI16();

  /// Reads a signed 32‑bit integer from the current position.
  int readI32();

  /// Reads a signed 64‑bit integer from the current position.
  int readI64();

  /// Reads a 32‑bit floating‑point number from the current position.
  double readF32();

  /// Reads a 64‑bit floating‑point number from the current position.
  double readF64();

  /// Reads a boolean value stored as a single byte (0 for false, 1 for true).
  bool readBool();

  /// Reads [count] bytes from the current position and returns them as a [List<int>].
  List<int> readBytes(int count);

  /// Reads a length‑prefixed string using the specified [encoding].
  ///
  /// The string length is determined by a preceding unsigned 64‑bit integer.
  /// The default [encoding] is UTF‑8.
  String readString([StringEncoding encoding = StringEncoding.utf8]);

  /// Reads a fixed‑length string from the current position.
  ///
  /// [length] specifies the number of bytes to read.
  /// The [encoding] parameter determines how the bytes are interpreted.
  String readFixedString(int length, {StringEncoding encoding});

  /// Reads a fixed‑length string and trims any trailing zero bytes.
  ///
  /// This is useful when strings are padded with zero bytes.
  String readCleanFixedString(int length, {StringEncoding encoding});

  // -- Optional Read Methods --

  /// Reads an optional boolean value.
  ///
  /// Returns `null` if the option tag is 0.
  bool? readOptionBool();

  /// Reads an optional unsigned 8‑bit integer.
  int? readOptionU8();

  /// Reads an optional unsigned 16‑bit integer.
  int? readOptionU16();

  /// Reads an optional unsigned 32‑bit integer.
  int? readOptionU32();

  /// Reads an optional unsigned 64‑bit integer.
  int? readOptionU64();

  /// Reads an optional signed 8‑bit integer.
  int? readOptionI8();

  /// Reads an optional signed 16‑bit integer.
  int? readOptionI16();

  /// Reads an optional signed 32‑bit integer.
  int? readOptionI32();

  /// Reads an optional signed 64‑bit integer.
  int? readOptionI64();

  /// Reads an optional 32‑bit floating‑point number.
  double? readOptionF32();

  /// Reads an optional 64‑bit floating‑point number.
  double? readOptionF64();

  /// Reads an optional string using the specified [encoding] (default is UTF‑8).
  ///
  /// Returns `null` if the option tag indicates the value is not present.
  String? readOptionString([StringEncoding encoding = StringEncoding.utf8]);

  /// Reads an optional fixed‑length string.
  ///
  /// Returns the raw fixed‑length string or `null` if not present.
  String? readOptionFixedString(int length, {StringEncoding encoding});

  /// Reads a fixed‑length string and trims trailing zero bytes, returning `null` if not present.
  String? readCleanOptionFixedString(int length, {StringEncoding encoding});

  /// Reads an optional 3‑element [Float32List].
  ///
  /// If the option tag is 0, it consumes 13 bytes (1 tag + 12 zeros) and returns null.
  Float32List? readOptionF32Triple();

  // -- Collection Read Methods --

  /// Reads a list of elements.
  ///
  /// The length of the list is prefixed as an unsigned 64‑bit integer.
  /// [readElement] is a callback used to read each element.
  List<T> readList<T>(T Function() readElement);

  /// Reads a map from the stream.
  ///
  /// The length of the map (number of key/value pairs) is prefixed as an unsigned 64‑bit integer.
  /// [readKey] and [readValue] are callbacks used to read the key and value for each pair.
  Map<K, V> readMap<K, V>(K Function() readKey, V Function() readValue);

  // -- Primitive List Read Helper Methods --

  /// Reads [length] signed 8‑bit integers from the stream.
  List<int> readInt8List(int length);

  /// Reads [length] signed 16‑bit integers from the stream.
  List<int> readInt16List(int length);

  /// Reads [length] signed 32‑bit integers from the stream.
  List<int> readInt32List(int length);

  /// Reads [length] signed 64‑bit integers from the stream.
  List<int> readInt64List(int length);

  /// Reads [length] unsigned 8‑bit integers from the stream.
  List<int> readUint8List(int length);

  /// Reads [length] unsigned 16‑bit integers from the stream.
  List<int> readUint16List(int length);

  /// Reads [length] unsigned 32‑bit integers from the stream.
  List<int> readUint32List(int length);

  /// Reads [length] unsigned 64‑bit integers from the stream.
  List<int> readUint64List(int length);

  /// Reads [length] 32‑bit floating‑point numbers from the stream.
  List<double> readFloat32List(int length);

  /// Reads [length] 64‑bit floating‑point numbers from the stream.
  List<double> readFloat64List(int length);

  // -- Nested Object Reading --

  /// Reads a nested object from the stream.
  ///
  /// First reads a 64‑bit length, then reads that many bytes,
  /// and finally calls [instance.loadFromBytes] on the given [instance].
  /// Returns the populated instance.
  T readNestedObject<T extends BincodeDecodable>(T instance);

  /// Reads an optional nested object from the stream.
  ///
  /// Returns `null` if the optional tag is 0.
  /// If present, creates a new instance using [creator] and loads it from the bytes.
  T? readOptionNestedObject<T extends BincodeDecodable>(T Function() creator);

  /// Returns the entire underlying byte buffer as a [Uint8List].
  Uint8List toBytes();
}
