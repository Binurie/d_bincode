// ============================================================
// Disclaimer: This source code is provided "as is", without any
// warranty of any kind, express or implied, including but not
// limited to the warranties of merchantability or fitness for
// a particular purpose.
// ============================================================

import 'dart:typed_data';

import '../d_bincode.dart';
import 'builder.dart';
import 'exception/exception.dart';
import 'internal_utils/byte_data_wrapper.dart';

/// A low-level binary reader that decodes data previously encoded in the [Bincode] format.
///
/// This class supports reading primitives, optionals, strings, collections, and
/// nested objects from binary data using an internal [ByteDataWrapper]. It keeps track
/// of the current read position and provides methods corresponding to Bincode encoding rules.
///
/// The `unsafe` mode skips checks for sufficient remaining bytes before reads, can
/// improving performance but risking runtime [RangeError] exceptions if reads go beyond
/// the buffer bounds.
///
/// Example:
/// ```dart
/// final reader = BincodeReader(encodedBytes);
/// try {
///   final id = reader.readU32();
///   final name = reader.readString();
///   final score = reader.readOptionF64();
///   // ... read other data
/// } on BincodeException catch (e) {
///   print('Failed to decode Bincode data: $e');
/// }
/// ```
class BincodeReader implements BincodeReaderBuilder {
  final ByteDataWrapper _wrapper;
  final bool unsafe;

  /// Creates a new [BincodeReader] to read from the provided [bytes].
  ///
  /// The reader maintains its own position cursor within the data.
  ///
  /// - [bytes]: A [Uint8List] containing the Bincode-encoded binary data.
  /// - [unsafe]: If `true`, bounds checks (ensuring enough data remains for a read)
  ///   are skipped for performance. Reading past the end of the buffer in unsafe mode
  ///   will result in a `RangeError` crash. Defaults to `false` (safe).
  BincodeReader(Uint8List bytes, {this.unsafe = false})
      : _wrapper = ByteDataWrapper(bytes.buffer,
            parentOffset: bytes.offsetInBytes, length: bytes.length);

  /// Internal constructor for creating a reader from an existing [ByteDataWrapper].
  /// Used by factory constructors like [fromFile].
  BincodeReader._fromWrapper(this._wrapper, this.unsafe);

  /// Asynchronously creates a [BincodeReader] by reading data from a file at the given [path].
  ///
  /// Returns a [Future] that completes with the [BincodeReader] instance after
  /// the file content has been loaded into memory.
  ///
  /// - [path]: The file system path to the Bincode data file.
  /// - [unsafe]: Sets the `unsafe` mode for the created reader (see main constructor).
  static Future<BincodeReader> fromFile(String path,
      {bool unsafe = false}) async {
    final wrapper = await ByteDataWrapper.fromFile(path);
    return BincodeReader._fromWrapper(wrapper, unsafe);
  }

  // -----------------------------
  // Positioning
  // -----------------------------

  /// Gets the current read cursor position within the underlying buffer.
  /// Indicates the byte offset where the next read operation will start.
  @override
  int get position => _wrapper.position;

  /// Sets the current read cursor position to an absolute byte offset [value].
  ///
  /// Allows random access within the buffer. The [value] must be within the
  /// valid range `[0, buffer_length]`. Setting the position beyond the end
  /// will cause subsequent reads to fail.
  /// Throws a [RangeError] if [value] is outside the valid range (handled by buffer wrapper).
  @override
  set position(int value) => _wrapper.position = value;

  /// Moves the read cursor position by [offset] bytes relative to the current position.
  ///
  /// Use a positive [offset] to move forward (skip bytes), negative to move backward.
  /// Throws a [RangeError] if the resulting position is outside the valid buffer range.
  @override
  void seek(int offset) => position += offset; // Relies on setter's range check

  /// Sets the read cursor to the absolute byte position [absolutePosition].
  /// Alias for setting the [position] property directly.
  @override
  void seekTo(int absolutePosition) => position = absolutePosition;

  /// Resets the read cursor position to the beginning of the buffer (index 0).
  @override
  void rewind() => position = 0;

  /// Moves the read cursor position to the end of the available data (the buffer's length).
  /// Subsequent reads will fail unless the position is moved back.
  @override
  void skipToEnd() => position = _wrapper.length;

  /// Returns the number of bytes remaining from the current position to the end of the buffer.
  /// Useful for checking available data before reads, especially in safe mode.
  int remainingBytes() {
    return _wrapper.length - _wrapper.position;
  }

  // -----------------------------
  // Primitives
  // -----------------------------

  /// Reads an unsigned 8-bit integer (byte) from the buffer.
  ///
  /// Corresponds to deserializing a `u8` in Rust. Advances position by 1 byte.
  /// If `unsafe` is false, throws [BincodeReadException] if not enough data remains.
  /// If `unsafe` is true, skips checks; reading past bounds throws [RangeError].
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct Header { version: u8 }
  /// ```
  @override
  int readU8() => unsafe
      ? _wrapper.readUint8()
      : _readOrThrow(() => _wrapper.readUint8(), "u8");

  /// Reads an unsigned 16-bit integer (Little Endian) from the buffer.
  ///
  /// Corresponds to deserializing a `u16` in Rust. Advances position by 2 bytes.
  /// If `unsafe` is false, throws [BincodeReadException] if not enough data remains.
  /// If `unsafe` is true, skips checks; reading past bounds throws [RangeError].
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct Item { item_code: u16 }
  /// ```
  @override
  int readU16() => unsafe
      ? _wrapper.readUint16()
      : _readOrThrow(() => _wrapper.readUint16(), "u16");

  /// Reads an unsigned 32-bit integer (Little Endian) from the buffer.
  ///
  /// Corresponds to deserializing a `u32` in Rust. Advances position by 4 bytes.
  /// If `unsafe` is false, throws [BincodeReadException] if not enough data remains.
  /// If `unsafe` is true, skips checks; reading past bounds throws [RangeError].
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct Message { message_id: u32 }
  /// ```
  @override
  int readU32() => unsafe
      ? _wrapper.readUint32()
      : _readOrThrow(() => _wrapper.readUint32(), "u32");

  /// Reads an unsigned 64-bit integer (Little Endian) from the buffer.
  ///
  /// Reads two 32-bit parts and combines them. Advances position by 8 bytes.
  /// Corresponds to deserializing a `u64` in Rust.
  /// If `unsafe` is false, throws [BincodeReadException] if not enough data remains for either part.
  /// If `unsafe` is true, skips checks; reading past bounds throws [RangeError].
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct Timestamps { creation_time_ns: u64 }
  /// ```
  @override
  int readU64() {
    if (unsafe) {
      final low = _wrapper.readUint32();
      final high = _wrapper.readUint32();
      return (high << 32) | low;
    } else {
      final low = _readOrThrow(() => _wrapper.readUint32(), "low part of u64");
      final high =
          _readOrThrow(() => _wrapper.readUint32(), "high part of u64");
      return (high << 32) | low;
    }
  }

  /// Reads a signed 8-bit integer from the buffer.
  ///
  /// Corresponds to deserializing an `i8` in Rust. Advances position by 1 byte.
  /// If `unsafe` is false, throws [BincodeReadException] if not enough data remains.
  /// If `unsafe` is true, skips checks; reading past bounds throws [RangeError].
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct Adjustment { offset: i8 }
  /// ```
  @override
  int readI8() => unsafe
      ? _wrapper.readInt8()
      : _readOrThrow(() => _wrapper.readInt8(), "i8");

  /// Reads a signed 16-bit integer (Little Endian) from the buffer.
  ///
  /// Corresponds to deserializing an `i16` in Rust. Advances position by 2 bytes.
  /// If `unsafe` is false, throws [BincodeReadException] if not enough data remains.
  /// If `unsafe` is true, skips checks; reading past bounds throws [RangeError].
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct Point { x_coord: i16 }
  /// ```
  @override
  int readI16() => unsafe
      ? _wrapper.readInt16()
      : _readOrThrow(() => _wrapper.readInt16(), "i16");

  /// Reads a signed 32-bit integer (Little Endian) from the buffer.
  ///
  /// Corresponds to deserializing an `i32` in Rust. Advances position by 4 bytes.
  /// If `unsafe` is false, throws [BincodeReadException] if not enough data remains.
  /// If `unsafe` is true, skips checks; reading past bounds throws [RangeError].
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct Event { status_code: i32 }
  /// ```
  @override
  int readI32() => unsafe
      ? _wrapper.readInt32()
      : _readOrThrow(() => _wrapper.readInt32(), "i32");

  /// Reads a signed 64-bit integer (Little Endian) from the buffer.
  ///
  /// Corresponds to deserializing an `i64` in Rust. Advances position by 8 bytes.
  /// If `unsafe` is false, throws [BincodeReadException] if not enough data remains.
  /// If `unsafe` is true, skips checks; reading past bounds throws [RangeError].
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct FileInfo { file_id: i64 }
  /// ```
  @override
  int readI64() => unsafe
      ? _wrapper.readInt64()
      : _readOrThrow(() => _wrapper.readInt64(), "i64");

  /// Reads a 32-bit float (IEEE 754, Little Endian) from the buffer.
  ///
  /// Corresponds to deserializing an `f32` in Rust. Advances position by 4 bytes.
  /// If `unsafe` is false, throws [BincodeReadException] if not enough data remains.
  /// If `unsafe` is true, skips checks; reading past bounds throws [RangeError].
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct Measurement { value: f32 }
  /// ```
  @override
  double readF32() => unsafe
      ? _wrapper.readFloat32()
      : _readOrThrow(() => _wrapper.readFloat32(), "f32");

  /// Reads a 64-bit float (IEEE 754, Little Endian) from the buffer.
  ///
  /// Corresponds to deserializing an `f64` in Rust. Advances position by 8 bytes.
  /// If `unsafe` is false, throws [BincodeReadException] if not enough data remains.
  /// If `unsafe` is true, skips checks; reading past bounds throws [RangeError].
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct Coordinates { latitude: f64 }
  /// ```
  @override
  double readF64() => unsafe
      ? _wrapper.readFloat64()
      : _readOrThrow(() => _wrapper.readFloat64(), "f64");

  /// Reads exactly [count] bytes from the buffer and returns them as a `List<int>` (typically a `Uint8List` view).
  ///
  /// Use this for reading raw byte sequences corresponding to Rust's `&[u8]` or fixed `[u8; N]`.
  /// Advances the position by [count] bytes.
  /// If `unsafe` is false, throws [BincodeReadException] if fewer than [count] bytes remain.
  /// If `unsafe` is true, skips checks; reading past bounds throws [RangeError].
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct Packet {
  ///     signature: [u8; 64], // Read with readBytes(64)
  /// }
  /// ```
  @override
  List<int> readBytes(int count) => unsafe
      ? _wrapper.asUint8List(count)
      : _readOrThrow(() => _wrapper.asUint8List(count), "$count bytes");

  /// Reads exactly [count] bytes from the buffer and returns them as a new [Uint8List] copy.
  ///
  /// Use this when you need an independent copy of the read bytes, rather than a view.
  /// Advances the position by [count] bytes.
  /// If `unsafe` is false, throws [BincodeReadException] if fewer than [count] bytes remain.
  /// If `unsafe` is true, skips checks; reading past bounds throws [RangeError].
  @override
  Uint8List readRawBytes(int count) {
    final bytesList = readBytes(count);
    if (bytesList is Uint8List &&
        bytesList.offsetInBytes == 0 &&
        bytesList.lengthInBytes == bytesList.buffer.lengthInBytes) {
      return Uint8List.fromList(bytesList);
    }
    return Uint8List.fromList(bytesList);
  }

  // -----------------------------
  // Boolean
  // -----------------------------

  /// Reads a boolean from the buffer, expecting a single byte (0 for false, 1 for true).
  ///
  /// Corresponds to deserializing a `bool` in Rust. Advances position by 1 byte.
  /// If `unsafe` is false:
  ///   - Throws [BincodeReadException] if not enough data remains.
  ///   - Throws [InvalidBooleanValueException] if the byte read is neither 0 nor 1.
  /// If `unsafe` is true:
  ///   - Skips checks; reading past bounds throws [RangeError].
  ///   - Interprets any non-zero byte as `true`.
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct Status { is_active: bool }
  /// ```
  @override
  bool readBool() {
    // readU8 handles safe/unsafe reading and throws if needed (RangeError or BincodeReadException)
    final byte = readU8();
    if (unsafe) {
      // In unsafe mode, mimic typical C-like bool conversion (0 is false, non-zero is true)
      return byte != 0;
    } else {
      // In safe mode, strictly enforce Bincode standard (0 or 1)
      if (byte != 0 && byte != 1) {
        throw InvalidBooleanValueException(byte);
      }
      return byte == 1;
    }
  }

  // -----------------------------
  // String Encoding (Reader Side)
  // -----------------------------

  /// Reads a string prefixed with a U64 length from the buffer.
  ///
  /// First reads the U64 length, then reads that many bytes and decodes them
  /// using the specified [encoding] (defaults to UTF-8).
  /// Corresponds to deserializing a `String` in Rust.
  /// Advances position by 8 (for length) + length bytes.
  /// Internal reads respect the `unsafe` flag.
  ///
  /// Warning: Always check if other encodings are supported besides Dart <-> Dart coding
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct User { username: String }
  /// ```
  @override
  String readString([StringEncoding encoding = StringEncoding.utf8]) {
    final length = readU64();
    return readFixedString(length, encoding: encoding);
  }

  /// Reads a fixed-length string of [length] bytes from the buffer.
  ///
  /// Reads exactly [length] bytes and decodes them using the specified [encoding] (defaults to UTF-8).
  /// Use when the exact byte length of the string data is known beforehand.
  /// Corresponds to deserializing fixed-size byte arrays (`[u8; N]`) intended as string data in Rust.
  /// Advances position by [length] bytes.
  /// If `unsafe` is false, throws [BincodeReadException] if not enough data remains or decoding fails.
  /// If `unsafe` is true, skips checks; reading past bounds throws [RangeError].
  ///
  /// Warning: Always check if other encodings are supported besides Dart <-> Dart coding
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct LegacyRecord {
  ///     name_fixed: [u8; 32],
  /// }
  /// // Read with readFixedString(32)
  /// ```
  @override
  String readFixedString(int length,
      {StringEncoding encoding = StringEncoding.utf8}) {
    return unsafe
        ? _wrapper.readString(length, encoding: encoding)
        : _readOrThrow(() => _wrapper.readString(length, encoding: encoding),
            "fixed string of length $length");
  }

  /// Reads a fixed-length string (like [readFixedString]) and removes trailing null (`\x00`) characters.
  ///
  /// Advances position by [length] bytes.
  /// Internal calls respect the `unsafe` flag.
  ///
  /// Warning: Always check if other encodings are supported besides Dart <-> Dart coding
  @override
  String readCleanFixedString(int length,
      {StringEncoding encoding = StringEncoding.utf8}) {
    final rawString = readFixedString(length, encoding: encoding);
    return rawString.replaceAll('\x00', '');
  }

  // -----------------------------
  // Optionals
  // -----------------------------

  /// Reads an optional boolean value according to Bincode's `Option<T>` encoding.
  ///
  /// Reads a 1-byte flag (0 for None, 1 for Some). If Some, reads the boolean value.
  /// Corresponds to deserializing `Option<bool>` in Rust.
  /// Internal reads respect the `unsafe` flag. Throws if tag is invalid.
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct Flags { is_enabled: Option<bool> }
  /// ```
  @override
  bool? readOptionBool() => _readOptional<bool>(readBool, readU8);

  /// Reads an optional unsigned 8-bit integer according to Bincode's `Option<T>` encoding.
  ///
  /// Reads a 1-byte flag (0 for None, 1 for Some). If Some, reads the u8 value.
  /// Corresponds to deserializing `Option<u8>` in Rust.
  /// Internal reads respect the `unsafe` flag. Throws if tag is invalid.
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct Config { priority: Option<u8> }
  /// ```
  @override
  int? readOptionU8() => _readOptional<int>(readU8, readU8);

  /// Reads an optional unsigned 16-bit integer according to Bincode's `Option<T>` encoding.
  ///
  /// Reads a 1-byte flag (0 for None, 1 for Some). If Some, reads the u16 value.
  /// Corresponds to deserializing `Option<u16>` in Rust.
  /// Internal reads respect the `unsafe` flag. Throws if tag is invalid.
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct Item { item_id: Option<u16> }
  /// ```
  @override
  int? readOptionU16() => _readOptional<int>(readU16, readU8);

  /// Reads an optional unsigned 32-bit integer according to Bincode's `Option<T>` encoding.
  ///
  /// Reads a 1-byte flag (0 for None, 1 for Some). If Some, reads the u32 value.
  /// Corresponds to deserializing `Option<u32>` in Rust.
  /// Internal reads respect the `unsafe` flag. Throws if tag is invalid.
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct Message { sequence_num: Option<u32> }
  /// ```
  @override
  int? readOptionU32() => _readOptional<int>(readU32, readU8);

  /// Reads an optional unsigned 64-bit integer according to Bincode's `Option<T>` encoding.
  ///
  /// Reads a 1-byte flag (0 for None, 1 for Some). If Some, reads the u64 value.
  /// Corresponds to deserializing `Option<u64>` in Rust.
  /// Internal reads respect the `unsafe` flag. Throws if tag is invalid.
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct Timestamps { last_updated_ns: Option<u64> }
  /// ```
  @override
  int? readOptionU64() => _readOptional<int>(readU64, readU8);

  /// Reads an optional signed 8-bit integer according to Bincode's `Option<T>` encoding.
  ///
  /// Reads a 1-byte flag (0 for None, 1 for Some). If Some, reads the i8 value.
  /// Corresponds to deserializing `Option<i8>` in Rust.
  /// Internal reads respect the `unsafe` flag. Throws if tag is invalid.
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct Adjustment { delta: Option<i8> }
  /// ```
  @override
  int? readOptionI8() => _readOptional<int>(readI8, readU8);

  /// Reads an optional signed 16-bit integer according to Bincode's `Option<T>` encoding.
  ///
  /// Reads a 1-byte flag (0 for None, 1 for Some). If Some, reads the i16 value.
  /// Corresponds to deserializing `Option<i16>` in Rust.
  /// Internal reads respect the `unsafe` flag. Throws if tag is invalid.
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct Point { z_coord: Option<i16> }
  /// ```
  @override
  int? readOptionI16() => _readOptional<int>(readI16, readU8);

  /// Reads an optional signed 32-bit integer according to Bincode's O`Option<T>` encoding.
  ///
  /// Reads a 1-byte flag (0 for None, 1 for Some). If Some, reads the i32 value.
  /// Corresponds to deserializing `Option<i32>` in Rust.
  /// Internal reads respect the `unsafe` flag. Throws if tag is invalid.
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct Event { event_code: Option<i32> }
  /// ```
  @override
  int? readOptionI32() => _readOptional<int>(readI32, readU8);

  /// Reads an optional signed 64-bit integer according to Bincode's `Option<T>` encoding.
  ///
  /// Reads a 1-byte flag (0 for None, 1 for Some). If Some, reads the i64 value.
  /// Corresponds to deserializing `Option<i64>` in Rust.
  /// Internal reads respect the `unsafe` flag. Throws if tag is invalid.
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct FileInfo { size_bytes: Option<i64> }
  /// ```
  @override
  int? readOptionI64() => _readOptional<int>(readI64, readU8);

  /// Reads an optional 32-bit float according to Bincode's `Option<T>` encoding.
  ///
  /// Reads a 1-byte flag (0 for None, 1 for Some). If Some, reads the f32 value.
  /// Corresponds to deserializing `Option<f32>` in Rust.
  /// Internal reads respect the `unsafe` flag. Throws if tag is invalid.
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct Measurement { temperature: Option<f32> }
  /// ```
  @override
  double? readOptionF32() => _readOptional<double>(readF32, readU8);

  /// Reads an optional 64-bit float according to Bincode's `Option<T>` encoding.
  ///
  /// Reads a 1-byte flag (0 for None, 1 for Some). If Some, reads the f64 value.
  /// Corresponds to deserializing `Option<f64>` in Rust.
  /// Internal reads respect the `unsafe` flag. Throws if tag is invalid.
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct Coordinates { longitude: Option<f64> }
  /// ```
  @override
  double? readOptionF64() => _readOptional<double>(readF64, readU8);

  /// Reads an optional string according to Bincode's `Option<T>` encoding.
  ///
  /// Reads a 1-byte flag (0 for None, 1 for Some). If Some, reads the string
  /// (including its U64 length prefix) using [readString]. Uses the specified [encoding].
  /// Corresponds to deserializing `Option<String>` in Rust.
  /// Internal reads respect the `unsafe` flag. Throws if tag is invalid.
  ///
  /// Warning: Always check if other encodings are supported besides Dart <-> Dart coding
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct UserProfile { nickname: Option<String> }
  /// ```
  @override
  String? readOptionString([StringEncoding encoding = StringEncoding.utf8]) =>
      _readOptional<String>(() => readString(encoding), readU8);

  /// Reads an optional fixed-length string representation from the buffer.
  ///
  /// Reads a 1-byte flag (0 for None, 1 for Some). If Some, reads exactly [length] bytes
  /// and decodes them as a string using [readFixedString] with the given [encoding].
  /// Useful if the source data contains optional strings stored in fixed-size buffers.
  /// Internal reads respect the `unsafe` flag. Throws if tag is invalid.
  ///
  /// Warning: Always check if other encodings are supported besides Dart <-> Dart coding
  ///
  /// #### Rust Context Example (Conceptual):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct LegacyRecord {
  ///     // Optional tag stored in fixed 8 bytes
  ///     optional_tag: Option<[u8; 8]>,
  /// }
  /// // Read with readOptionFixedString(8)
  /// ```
  @override
  String? readOptionFixedString(int length,
          {StringEncoding encoding = StringEncoding.utf8}) =>
      _readOptional<String>(
          () => readFixedString(length, encoding: encoding), readU8);

  /// Reads an optional fixed-length string and removes trailing null characters (`\x00`).
  ///
  /// Combines [readOptionFixedString] with null character removal.
  /// Internal reads respect the `unsafe` flag.
  ///
  /// Warning: Always check if other encodings are supported besides Dart <-> Dart coding
  @override
  String? readCleanOptionFixedString(int length,
      {StringEncoding encoding = StringEncoding.utf8}) {
    // readOptionFixedString handles safe/unsafe logic internally via _readOptional
    final rawString = readOptionFixedString(length, encoding: encoding);
    // Removing null chars is safe
    return rawString?.replaceAll('\x00', '');
  }

  /// Reads an optional 3-element [Float32List] corresponding to `Option<[f32; 3]>`.
  ///
  /// Reads a 1-byte flag (0 for None, 1 for Some).
  /// If Some (tag == 1), reads three `f32` values and returns them in a [Float32List].
  /// If None (tag == 0), returns null.
  /// Throws [InvalidOptionTagException] if tag is not 0 or 1.
  /// Internal reads respect the `unsafe` flag.
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct Transform {
  ///     scale: Option<[f32; 3]>,
  /// }
  /// ```
  /// **Layout:** `[0]` if `null`, `[1][f32][f32][f32]` otherwise.
  @override
  Float32List? readOptionF32Triple() {
    final tag = readU8();
    if (tag != 0 && tag != 1) {
      throw InvalidOptionTagException(tag);
    }
    if (tag == 1) {
      // Some
      final f1 = readF32();
      final f2 = readF32();
      final f3 = readF32();
      return Float32List.fromList([f1, f2, f3]);
    } else {
      return null;
    }
  }

  // -----------------------------
  // Collections
  // -----------------------------

  /// Reads a list of elements, where the list length is prefixed as a U64.
  ///
  /// First reads the U64 length, then calls the [readElement] callback function
  /// exactly `length` times to read each element.
  /// Corresponds to deserializing `Vec<T>` in Rust for any serializable `T`.
  /// Internal reads (length and elements via callback) respect the `unsafe` flag.
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct Scene {
  ///     objects: Vec<SceneObject>, // Deserializes length, then uses callback logic for each object
  /// }
  /// #[derive(Deserialize)]
  /// struct SceneObject { /* ... */ }
  /// ```
  @override
  List<T> readList<T>(T Function() readElement) {
    final length = readU64();
    return List<T>.generate(length, (_) => readElement());
  }

  /// Reads a map of key-value pairs, where the number of entries is prefixed as a U64.
  ///
  /// First reads the U64 length (number of entries), then calls [readKey] followed by
  /// [readValue] `length` times to read each key-value pair.
  /// Corresponds to deserializing map types like `HashMap<K, V>` or `BTreeMap<K, V>` in Rust.
  /// Internal reads (length and keys/values via callbacks) respect the `unsafe` flag.
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// use std::collections::HashMap;
  /// #[derive(Deserialize)]
  /// struct GameState {
  ///     players: HashMap<String, PlayerData>, // Deserializes length, then key/value pairs
  /// }
  /// #[derive(Deserialize)]
  /// struct PlayerData { /* ... */ }
  /// ```
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
  // Numeric Lists (Specialized)
  // -----------------------------

  /// Reads a Bincode sequence of 32-bit float values from the buffer.
  ///
  /// First reads a U64 length prefix, then reads that many f32 elements.
  /// Corresponds to deserializing `Vec<f32>` in Rust.
  /// If `unsafe` is false (default), checks ensure enough data remains before reading the length and elements.
  /// If `unsafe` is true, checks are skipped; reading past buffer bounds will throw a [RangeError].
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct SignalData { samples_f32: Vec<f32> }
  /// ```
  /// Returns a `List<double>` containing the read elements.
  /// Throws [BincodeReadException] (via _readOrThrow) if not enough data and `unsafe` is false.
  @override
  List<double> readFloat32List() {
    final length = readU64();
    if (length < 0 || length > 0x1FFFFFFFFFFFFF) {
      throw BincodeException("Invalid list length read: $length");
    }
    return unsafe
        ? _wrapper.readFloat32List(length) // Use read length
        : _readOrThrow(
            () => _wrapper.readFloat32List(length), // Use read length
            "Float32 list of calculated length $length"); // Use read length
  }

  /// Reads a Bincode sequence of 64-bit float values from the buffer.
  ///
  /// First reads a U64 length prefix, then reads that many f64 elements.
  /// Corresponds to deserializing `Vec<f64>` in Rust.
  /// Handles `unsafe` flag for bounds checks (throws `RangeError` if unsafe and out of bounds).
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct GraphPoints { y_values: Vec<f64> }
  /// ```
  /// Throws [BincodeReadException] if not enough data and `unsafe` is false.
  @override
  List<double> readFloat64List() {
    final length = readU64();
    if (length < 0 || length > 0x1FFFFFFFFFFFFF) {
      throw BincodeException("Invalid list length read: $length");
    }
    return unsafe
        ? _wrapper.readFloat64List(length)
        : _readOrThrow(() => _wrapper.readFloat64List(length),
            "Float64 list of calculated length $length");
  }

  /// Reads a Bincode sequence of signed 8-bit integers from the buffer.
  ///
  /// First reads a U64 length prefix, then reads that many i8 elements.
  /// Corresponds to deserializing `Vec<i8>` in Rust.
  /// Handles `unsafe` flag for bounds checks (throws `RangeError` if unsafe and out of bounds).
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct AudioSample { pcm_data_i8: Vec<i8> }
  /// ```
  /// Throws [BincodeReadException] if not enough data and `unsafe` is false.
  @override
  List<int> readInt8List() {
    final length = readU64();
    if (length < 0 || length > 0x1FFFFFFFFFFFFF) {
      throw BincodeException("Invalid list length read: $length");
    }
    return unsafe
        ? _wrapper.readInt8List(length)
        : _readOrThrow(() => _wrapper.readInt8List(length),
            "Int8 list of calculated length $length");
  }

  /// Reads a Bincode sequence of signed 16-bit integers (Little Endian) from the buffer.
  ///
  /// First reads a U64 length prefix, then reads that many i16 elements.
  /// Corresponds to deserializing `Vec<i16>` in Rust.
  /// Handles `unsafe` flag for bounds checks (throws `RangeError` if unsafe and out of bounds).
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct PointCloud { coords_i16: Vec<i16> }
  /// ```
  /// Throws [BincodeReadException] if not enough data and `unsafe` is false.
  @override
  List<int> readInt16List() {
    final length = readU64();
    if (length < 0 || length > 0x1FFFFFFFFFFFFF) {
      throw BincodeException("Invalid list length read: $length");
    }
    return unsafe
        ? _wrapper.readInt16List(length)
        : _readOrThrow(() => _wrapper.readInt16List(length),
            "Int16 list of calculated length $length");
  }

  /// Reads a Bincode sequence of signed 32-bit integers (Little Endian) from the buffer.
  ///
  /// First reads a U64 length prefix, then reads that many i32 elements.
  /// Corresponds to deserializing `Vec<i32>` in Rust.
  /// Handles `unsafe` flag for bounds checks (throws `RangeError` if unsafe and out of bounds).
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct IdList { user_ids: Vec<i32> }
  /// ```
  /// Throws [BincodeReadException] if not enough data and `unsafe` is false.
  @override
  List<int> readInt32List() {
    final length = readU64();
    if (length < 0 || length > 0x1FFFFFFFFFFFFF) {
      throw BincodeException("Invalid list length read: $length");
    }
    return unsafe
        ? _wrapper.readInt32List(length)
        : _readOrThrow(() => _wrapper.readInt32List(length),
            "Int32 list of calculated length $length");
  }

  /// Reads a Bincode sequence of signed 64-bit integers (Little Endian) from the buffer.
  ///
  /// First reads a U64 length prefix, then reads that many i64 elements.
  /// Corresponds to deserializing `Vec<i64>` in Rust.
  /// Handles `unsafe` flag for bounds checks (throws `RangeError` if unsafe and out of bounds).
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct EventLog { timestamps_ms: Vec<i64> }
  /// ```
  /// Throws [BincodeReadException] if not enough data and `unsafe` is false.
  @override
  List<int> readInt64List() {
    final length = readU64();
    if (length < 0 || length > 0x1FFFFFFFFFFFFF) {
      throw BincodeException("Invalid list length read: $length");
    }
    return unsafe
        ? _wrapper.readInt64List(length)
        : _readOrThrow(() => _wrapper.readInt64List(length),
            "Int64 list of calculated length $length");
  }

  /// Reads a Bincode sequence of unsigned 8-bit integers (bytes) from the buffer.
  ///
  /// First reads a U64 length prefix, then reads that many u8 elements.
  /// Corresponds to deserializing `Vec<u8>` in Rust.
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct RawData { buffer: Vec<u8> }
  /// ```
  /// Throws [BincodeReadException] if not enough data and `unsafe` is false.
  @override
  List<int> readUint8List() {
    final length = readU64();
    if (length < 0 || length > 0x1FFFFFFFFFFFFF) {
      throw BincodeException("Invalid list length read: $length");
    }
    return unsafe
        ? _wrapper.readUint8List(length)
        : _readOrThrow(() => _wrapper.readUint8List(length),
            "Uint8 list of calculated length $length");
  }

  /// Reads a Bincode sequence of unsigned 16-bit integers (Little Endian) from the buffer.
  ///
  /// First reads a U64 length prefix, then reads that many u16 elements.
  /// Corresponds to deserializing `Vec<u16>` in Rust.
  /// Handles `unsafe` flag for bounds checks (throws `RangeError` if unsafe and out of bounds).
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct CharCodes { utf16_codes: Vec<u16> }
  /// ```
  /// Throws [BincodeReadException] if not enough data and `unsafe` is false.
  @override
  List<int> readUint16List() {
    final length = readU64();
    if (length < 0 || length > 0x1FFFFFFFFFFFFF) {
      throw BincodeException("Invalid list length read: $length");
    }
    return unsafe
        ? _wrapper.readUint16List(length)
        : _readOrThrow(() => _wrapper.readUint16List(length),
            "Uint16 list of calculated length $length");
  }

  /// Reads a Bincode sequence of unsigned 32-bit integers (Little Endian) from the buffer.
  ///
  /// First reads a U64 length prefix, then reads that many u32 elements.
  /// Corresponds to deserializing `Vec<u32>` in Rust.
  /// Handles `unsafe` flag for bounds checks (throws `RangeError` if unsafe and out of bounds).
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct ColorPalette { rgba_colors: Vec<u32> }
  /// ```
  /// Throws [BincodeReadException] if not enough data and `unsafe` is false.
  @override
  List<int> readUint32List() {
    final length = readU64();
    if (length < 0 || length > 0x1FFFFFFFFFFFFF) {
      throw BincodeException("Invalid list length read: $length");
    }
    return unsafe
        ? _wrapper.readUint32List(length)
        : _readOrThrow(() => _wrapper.readUint32List(length),
            "Uint32 list of calculated length $length");
  }

  /// Reads a Bincode sequence of unsigned 64-bit integers (Little Endian) from the buffer.
  ///
  /// First reads a U64 length prefix, then reads that many u64 elements.
  /// Corresponds to deserializing `Vec<u64>` in Rust.
  /// Handles `unsafe` flag for bounds checks (throws `RangeError` if unsafe and out of bounds).
  ///
  /// #### Rust Context Example (Deserialization):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct IdentifierList { unique_ids: Vec<u64> }
  /// ```
  /// Throws [BincodeReadException] if not enough data and `unsafe` is false.
  @override
  List<int> readUint64List() {
    final length = readU64();
    if (length < 0 || length > 0x1FFFFFFFFFFFFF) {
      throw BincodeException("Invalid list length read: $length");
    }
    return unsafe
        ? _wrapper.readUint64List(length)
        : _readOrThrow(() => _wrapper.readUint64List(length),
            "Uint64 list of calculated length $length");
  }

  /// Returns a [Uint8List] view of the entire underlying byte buffer used by the reader.
  ///
  /// This provides access to the complete raw data the reader was initialized with,
  /// regardless of the current read position. Modifying the returned list view
  /// **will modify** the reader's underlying buffer.
  @override
  Uint8List toBytes() => _wrapper.buffer.asUint8List();

  // -----------------------------
  // Nested Objects
  // -----------------------------

  /// **Deprecated:** Use [readNestedObjectForCollection] or [readNestedObjectForFixed].
  /// Reads a nested object that was encoded with a length prefix.
  ///
  /// Reads a U64 length, reads that many bytes, then populates the provided [instance]
  /// using its `fromBincode` method.
  @Deprecated(
      'Use readNestedObjectForCollection or readNestedObjectForFixed instead')
  @override
  T readNestedObject<T extends BincodeDecodable>(T instance) {
    final length = readU64();
    final bytes = Uint8List.fromList(readBytes(length));
    instance.fromBincode(bytes);
    return instance;
  }

  /// **Deprecated:** Use [readOptionNestedObjectForCollection] or [readOptionNestedObjectForFixed].
  /// Reads an optional nested object encoded with a length prefix when Some.
  ///
  /// Reads a 1-byte flag. If 1 (Some), reads U64 length, reads bytes, creates an
  /// instance using [creator], and calls `fromBincode`. Returns null if flag is 0 (None).
  @Deprecated(
      'Use readOptionNestedObjectForCollection or readOptionNestedObjectForFixed instead')
  @override
  T? readOptionNestedObject<T extends BincodeDecodable>(T Function() creator) {
    final tag = readU8();
    if (tag == 0) return null;
    if (tag != 1) throw InvalidOptionTagException(tag);
    final length = readU64();
    final bytes = Uint8List.fromList(readBytes(length));
    final instance = creator();
    instance.fromBincode(bytes);
    return instance;
  }

  /// Reads and decodes a nested object that was encoded with a U64 length prefix.
  ///
  /// Reads the U64 length, reads that many bytes, then populates the fields of
  /// the provided [instance] using its `fromBincode` method. Returns the
  /// populated [instance].
  /// Use this when reading elements of a list/Vec where each element *was*
  /// individually length-prefixed (e.g., written using [writeNestedValueForCollection]
  /// within a `writeList` callback).
  /// Requires `T` to implement [BincodeDecodable].
  /// Internal reads respect the `unsafe` flag.
  ///
  /// #### Rust Context Example (Deserialization):
  /// Corresponds to reading each `MyItem` element when deserializing `Vec<MyItem>`
  /// where `MyItem` serialization itself isn't fixed-size or requires explicit length.
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct Container { items: Vec<MyItem> } // MyItem written with per-item length
  /// #[derive(Deserialize)]
  /// struct MyItem { id: u32, name: String }
  /// ```
  /// #### Dart Usage Example:
  /// Typically used within a `readList` callback when elements have length prefixes:
  /// ```dart
  /// class MyItem implements BincodeDecodable {
  ///   int id = 0; String name = '';
  ///   @override void fromBincode(Uint8List bytes) { /* ... decode id, name */ }
  /// }
  /// // BincodeReader reader;
  /// List<MyItem> items = reader.readList<MyItem>(() {
  ///   final item = MyItem(); // Create instance
  ///   // Read item data (which includes its own length prefix)
  ///   reader.readNestedObjectForCollection<MyItem>(item);
  ///   return item;
  /// });
  /// ```
  @override
  T readNestedObjectForCollection<T extends BincodeDecodable>(T instance) {
    final length = readU64();
    final bytes = readRawBytes(length);
    instance.fromBincode(bytes);
    return instance;
  }

  /// Reads and decodes a nested object that was encoded *without* a length prefix.
  ///
  /// Use this for reading nested values corresponding to fixed-size Rust struct fields
  /// OR for reading elements within a list where each element has the *same known fixed size*
  /// and was written without individual length prefixes (like your `LayoutConfig` example).
  /// **Requires `T` to implement `BincodeCodable` (both encode and decode)**
  /// to automatically determine the expected fixed byte size via `instance.toBincode().length`.
  /// Reads exactly that many bytes and populates the provided [instance] via `fromBincode`.
  /// Returns the populated [instance].
  /// Internal read respects the `unsafe` flag. Throws if size cannot be determined or read fails.
  ///
  /// #### Rust Context Examples (Deserialization):
  /// 1. Reading a fixed-size struct field:
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct Outer { id: u32, inner: InnerStruct } // Reading 'inner'
  /// #[derive(Deserialize, Serialize)] // Requires Serialize for size check
  /// struct InnerStruct { value: f64 }
  /// ```
  /// 2. Reading elements of `Vec<FixedStruct>` (where only list length was written):
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct Layout { configs: Vec<LayoutConfig> } // Reading each 'LayoutConfig'
  /// #[derive(Deserialize, Serialize)] // Requires Serialize for size check
  /// struct LayoutConfig { x: f32, y: f32, width: f32 } // Fixed size
  /// ```
  /// #### Dart Usage Examples:
  /// 1. Reading a single fixed-size field:
  /// ```dart
  /// class InnerStruct implements BincodeCodable { /* ... fixed size ... */ }
  /// // BincodeReader reader;
  /// final inner = InnerStruct();
  /// reader.readNestedObjectForFixed<InnerStruct>(inner); // Populate single instance
  /// print(inner);
  /// ```
  /// 2. Reading elements of a list containing fixed-size items:
  /// ```dart
  /// class LayoutConfig implements BincodeCodable { /* ... fixed size ... */ }
  /// // BincodeReader reader;
  /// // Corresponds to writer using writeList<LC>(..., (c)=>writeNestedValueForFixed(c))
  /// List<LayoutConfig> configs = reader.readList<LayoutConfig>(() {
  ///   final config = LayoutConfig(); // Create instance
  ///   // Read fixed-size bytes for one element (no per-element length read)
  ///   reader.readNestedObjectForFixed<LayoutConfig>(config);
  ///   return config;
  /// });
  /// print(configs);
  /// ```
  @override
  T readNestedObjectForFixed<T extends BincodeCodable>(T instance) {
    int bytesToRead;
    try {
      bytesToRead = instance.toBincode().length;
    } catch (e) {
      throw BincodeException(
          "Cannot determine fixed size for nested object type ${T.runtimeType}. Ensure it implements BincodeCodable.",
          e);
    }
    if (bytesToRead < 0) {
      throw BincodeException(
          "Calculated negative size for fixed nested object type ${T.runtimeType}.");
    }
    final bytes = readRawBytes(bytesToRead);
    instance.fromBincode(bytes);
    return instance;
  }

  /// Reads an optional nested object that was encoded with a U64 length prefix when Some.
  ///
  /// Reads a 1-byte flag (0 for None, 1 for Some). If Some, reads the U64 length,
  /// reads that many bytes, creates a new object using the [creator] function,
  /// populates it via `fromBincode`, and returns it. Returns `null` if the flag was 0.
  /// Use for optional fields corresponding to Rust `Option<T>` where `T` itself is treated
  /// as dynamically sized during encoding (e.g., `Option<String>`, `Option<Vec<CustomStruct>>`).
  /// Requires `T` to implement [BincodeDecodable].
  /// Internal reads respect the `unsafe` flag. Throws [InvalidOptionTagException] if tag invalid.
  ///
  /// #### Rust Context Example (Deserialization):
  /// Corresponds to reading the `maybe_dynamic_item` field:
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct Container { maybe_dynamic_item: Option<MyItem> } // Where MyItem isn't encoded as fixed-size
  /// #[derive(Deserialize)]
  /// struct MyItem { /* ... */ }
  /// ```
  /// #### Dart Usage Example:
  /// ```dart
  /// class MyItem implements BincodeDecodable { /* ... */ @override void fromBincode(Uint8List bytes) {} }
  /// // BincodeReader reader;
  /// MyItem? maybeItemData = reader.readOptionNestedObjectForCollection<MyItem>(
  ///   () => MyItem() // Provide function to create a new MyItem instance
  /// );
  /// if (maybeItemData != null) { /* use it */ }
  /// ```
  @override
  T? readOptionNestedObjectForCollection<T extends BincodeDecodable>(
      T Function() creator) {
    final tag = readU8();
    if (tag == 0) return null;
    if (!unsafe) {
      if (tag != 1) {
        throw InvalidOptionTagException(tag);
      }
    }

    final length = readU64();
    final bytes = readRawBytes(length);
    final instance = creator();
    instance.fromBincode(bytes);
    return instance;
  }

  /// Reads an optional nested object that was encoded *without* a length prefix when Some.
  ///
  /// Reads a 1-byte flag (0 for None, 1 for Some). If Some, determines the object's
  /// fixed size (requires `T` implements `BincodeCodable` via the instance returned by [creator]),
  /// reads that many bytes, creates a *new* object using [creator], populates it via `fromBincode`,
  /// and returns it. Returns `null` if the flag was 0.
  /// Use for optional fields corresponding to Rust `Option<T>` where `T` is a fixed-size struct.
  /// Internal read respects the `unsafe` flag. Throws [InvalidOptionTagException] or errors during size calculation/read.
  ///
  /// #### Rust Context Example (Deserialization):
  /// Corresponds to reading the `optional_settings` field:
  /// ```rust
  /// #[derive(Deserialize)]
  /// struct Config { optional_settings: Option<InnerSettings> }
  /// #[derive(Deserialize, Serialize)] // Requires Serialize for size check
  /// struct InnerSettings { value: f64 }
  /// ```
  /// #### Dart Usage Example:
  /// ```dart
  /// class InnerSettings implements BincodeCodable { /* ... fixed size ... */ }
  /// // BincodeReader reader;
  /// InnerSettings? settings = reader.readOptionNestedObjectForFixed<InnerSettings>(
  ///   () => InnerSettings() // Provide function to create instance
  /// );
  /// if (settings != null) { /* use settings */ }
  /// ```
  @override
  T? readOptionNestedObjectForFixed<T extends BincodeCodable>(
      T Function() creator) {
    final tag = readU8();
    if (tag == 0) return null;
    if (tag != 1) throw InvalidOptionTagException(tag);

    T instanceForSize;
    int bytesToRead;
    try {
      instanceForSize = creator();
      bytesToRead = instanceForSize.toBincode().length;
    } catch (e) {
      throw BincodeException(
          "Cannot determine fixed size for nested object type ${T.runtimeType} from creator. Ensure it implements BincodeCodable.",
          e);
    }
    if (bytesToRead < 0) {
      throw BincodeException(
          "Calculated negative size for fixed nested object type ${T.runtimeType}.");
    }

    final bytes = readRawBytes(bytesToRead);
    final instance = creator();
    instance.fromBincode(bytes);
    return instance;
  }

  // -----------------------------
  // Helpers
  // -----------------------------

  /// Internal helper: Wraps a read operation [readFn] in a try-catch block.
  T _readOrThrow<T>(T Function() readFn, String description) {
    assert(!unsafe);
    try {
      return readFn();
    } on RangeError {
      throw UnexpectedEndOfBufferException();
    } catch (e) {
      throw BincodeException("Error reading $description", e);
    }
  }

  /// Internal helper for reading optional values based on Bincode's standard
  /// `Option<T>` encoding (a 1-byte tag followed by the value if the tag is 1).
  T? _readOptional<T>(T Function() readFn, int Function() readTagFn) {
    final tag = readTagFn();
    if (!unsafe) {
      if (tag != 0 && tag != 1) {
        throw InvalidOptionTagException(tag);
      }
    }
    return tag == 1 ? readFn() : null;
  }
}
