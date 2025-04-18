// ============================================================
// Disclaimer: This source code is provided "as is", without any
// warranty of any kind, express or implied, including but not
// limited to the warranties of merchantability or fitness for
// a particular purpose.
// ============================================================

import 'dart:io';
import 'dart:typed_data';

import 'builder.dart';
import 'codable.dart';
import 'enums.dart';
import 'exception/exception.dart';
import 'internal_utils/byte_data_wrapper.dart';
import 'internal_utils/utils.dart';

/// A low-level binary writer that encodes structured data in [Bincode] format.
///
/// This class provides methods to write primitive types, strings, optionals,
/// collections, and nested objects into an internal byte buffer.
/// In normal mode (`unchecked = false`), the buffer expands automatically as needed, ensuring safety.
/// In `unchecked = true` mode, buffer expansion and integer range checks are
/// disabled for potential performance gains, but this risks runtime [RangeError] exceptions
/// if the initial buffer capacity is exceeded during writes.
///
/// ## Features
/// - Automatic buffer resizing (only when `unchecked = false`)
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
///
/// // Faster usage with guaranteed capacity (requires care)
/// final fastWriter = BincodeWriter(initialCapacity: 1024, unchecked: true);
/// // ... write data known to fit within 1024 bytes ...
/// final bytes = fastWriter.toBytes();
/// ```
class BincodeWriter implements BincodeWriterBuilder {
  late ByteDataWrapper _wrapper;
  int _capacity;
  int _position = 0;
  final bool unchecked;

  /// Creates a new [BincodeWriter] with an optional [initialCapacity] (in bytes).
  ///
  /// The [initialCapacity] parameter determines the starting size of the internal buffer.
  /// Choose a size large enough for typical data to minimize reallocations in safe mode,
  /// or large enough to hold *all* expected data if using unchecked mode.
  ///
  /// Behavior depends on the [unchecked] flag:
  ///
  /// - **`unchecked = false` (Default, Safe Mode):**
  ///   - Buffer capacity is checked before writes; the buffer grows automatically if needed.
  ///   - **More safety:** Since auto growing prevents out-of-range value errors and ensures sufficient buffer space, avoiding runtime write errors.
  ///   - Incurs overhead for checks and memory reallocations/copying.
  ///
  /// - **`unchecked = true` (Faster, Requires Care):**
  ///   - Integer range checks AND buffer capacity checks (`_ensureCapacity`) are **skipped**.
  ///   - The buffer **WILL NOT grow** beyond the provided [initialCapacity].
  ///   - **Use this mode only if:**
  ///     1. Performance is needed for a specific, measured bottleneck.
  ///     2. You can **guarantee** (e.g., by pre-calculating size or using a sufficiently large overestimate) that the provided [initialCapacity] is large enough for the entire serialization process under all conditions.
  BincodeWriter({int initialCapacity = 128, this.unchecked = false})
      : _capacity = initialCapacity {
    if (initialCapacity <= 0) {
      throw ArgumentError.value(
          initialCapacity, 'initialCapacity', 'must be positive');
    }
    _wrapper = ByteDataWrapper.allocate(_capacity);
  }

  /// Moves the write cursor by [offset] bytes relative to the current [position].
  @override
  void seek(int offset) {
    _wrapper.position += offset;
  }

  /// Returns the current write cursor position within the buffer.
  @override
  int get position => _wrapper.position;

  /// Provides access to the raw underlying [ByteBuffer].
  ByteBuffer get buffer => _wrapper.buffer;

  /// Returns the total number of bytes logically written to the buffer.
  ///
  /// This represents the highest position reached by any write operation,
  /// effectively the current "size" of the serialized data.
  int getBytesWritten() => _position;

  /// Sets the write cursor to an absolute byte position [value].
  @override
  set position(int value) {
    _wrapper.position = value;
  }

  /// Resets the write cursor position to the beginning of the buffer (index 0).
  ///
  /// Does not change the buffer content or the logical size reported by [getBytesWritten].
  @override
  void rewind() {
    _wrapper.position = 0;
  }

  /// Moves the write cursor to the end of the logically written data.
  ///
  /// Sets the cursor [position] to the value returned by [getBytesWritten].
  /// Useful after seeking backwards if you want to append new data.
  @override
  void skipToEnd() {
    // Sets cursor to the high-water mark
    _wrapper.position = _position;
  }

  /// Sets the write cursor to the absolute byte position [offset].
  ///
  /// This is an alias for setting the [position] property directly.
  @override
  void seekTo(int offset) {
    _wrapper.position = offset;
  }

  // --- Internal Buffer Management ---

  /// Ensures that there is at least [neededBytes] available starting from the current position.
  ///
  /// If the current buffer does not have enough space, [_grow] is called to expand it.
  /// **This method is NOT called if `unchecked` is true.**
  void _ensureCapacity(int neededBytes) {
    final currentPos = _wrapper.position;
    if (currentPos + neededBytes > _capacity) {
      _grow(currentPos + neededBytes);
    }
  }

  /// Expands the internal buffer so that its capacity is at least [minCapacity] bytes.
  ///
  /// The new capacity is chosen by doubling the current capacity, yet never lower than [minCapacity].
  /// **This method is NEVER called if `unchecked` is true.**
  void _grow(int minCapacity) {
    final oldPosition = _wrapper.position;
    final newCapacity = (_capacity * 2).clamp(minCapacity, minCapacity * 2);
    final newWrapper = ByteDataWrapper.allocate(newCapacity);
    final oldBytesView = _wrapper.buffer.asUint8List(0, _position);
    newWrapper.writeBytes(oldBytesView);

    _wrapper = newWrapper;
    _capacity = newCapacity;
    _wrapper.position = oldPosition.clamp(0, _capacity);
  }

  /// It tracks the highest byte index written to.
  void _updateLogicalPosition() {
    final currentCursorPos = _wrapper.position;
    if (currentCursorPos > _position) {
      _position = currentCursorPos;
    }
  }

  // --- Primitive Writing Methods ---

  /// Writes an unsigned 8-bit integer [value] (byte) to the buffer.
  ///
  /// Corresponds to serializing a `u8` in Rust.
  /// If `unchecked` is true, range validation and buffer capacity checks are skipped.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct Header {
  ///     version: u8, // Use for this field
  /// }
  /// ```
  /// **Layout:** 1 byte.
  @override
  void writeU8(int value) {
    if (!unchecked) {
      if (value < 0 || value > 0xFF) {
        throw InvalidWriteRangeException(value, 'u8',
            minValue: 0, maxValue: 0xFF);
      }
      _ensureCapacity(1);
    }
    _wrapper.writeUint8(value);
    _updateLogicalPosition();
  }

  /// Writes an unsigned 16-bit integer [value] to the buffer (Little-Endian).
  ///
  /// Corresponds to serializing a `u16` in Rust.
  /// If `unchecked` is true, range validation and buffer capacity checks are skipped.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct Item {
  ///     item_code: u16, // Use for this field
  /// }
  /// ```
  /// **Layout:** 2 bytes, Little Endian.
  @override
  void writeU16(int value) {
    if (!unchecked) {
      if (value < 0 || value > 0xFFFF) {
        throw InvalidWriteRangeException(value, 'u16',
            minValue: 0, maxValue: 0xFFFF);
      }
      _ensureCapacity(2);
    }
    _wrapper.writeUint16(value);
    _updateLogicalPosition();
  }

  /// Writes an unsigned 32-bit integer [value] to the buffer (Little-Endian).
  ///
  /// Corresponds to serializing a `u32` in Rust.
  /// If `unchecked` is true, range validation and buffer capacity checks are skipped.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct Message {
  ///     message_id: u32, // Use for this field
  /// }
  /// ```
  /// **Layout:** 4 bytes, Little Endian.
  @override
  void writeU32(int value) {
    if (!unchecked) {
      if (value < 0 || value > 0xFFFFFFFF) {
        throw InvalidWriteRangeException(value, 'u32',
            minValue: 0, maxValue: 0xFFFFFFFF);
      }
      _ensureCapacity(4);
    }
    _wrapper.writeUint32(value);
    _updateLogicalPosition();
  }

  /// Writes an unsigned 64-bit integer [value] to the buffer (Little-Endian).
  ///
  /// Corresponds to serializing a `u64` in Rust. Accepts a standard Dart [int].
  /// Note that Dart's `int` is signed; values representing the upper half of the
  /// u64 range (>= 2^63) will be negative when interpreted as signed Dart integers,
  /// but their bit patterns are written correctly as unsigned by this method.
  ///
  /// If `unchecked` is true, buffer capacity checks are skipped.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct Timestamps {
  ///     creation_time_ns: u64, // Use for this field
  /// }
  /// ```
  /// **Layout:** 8 bytes, Little Endian.
  @override
  void writeU64(int value) {
    if (!unchecked) {
      // The check `if (value < 0)` was removed.
      // Dart's standard 'int' is signed 64-bit. To represent the full u64 range,
      // values >= 2^63 will appear negative in Dart (e.g., 0xFFFFFFFFFFFFFFFF is -1).
      _ensureCapacity(8);
    }
    _wrapper.writeUint64(value);
    _updateLogicalPosition();
  }

  /// Writes a signed 8-bit integer [value] to the buffer.
  ///
  /// Corresponds to serializing an `i8` in Rust.
  /// If `unchecked` is true, range validation and buffer capacity checks are skipped.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct Adjustment {
  ///     offset: i8, // Use for this field
  /// }
  /// ```
  /// **Layout:** 1 byte.
  @override
  void writeI8(int value) {
    if (!unchecked) {
      if (value < -0x80 || value > 0x7F) {
        throw InvalidWriteRangeException(value, 'i8',
            minValue: -0x80, maxValue: 0x7F);
      }
      _ensureCapacity(1);
    }
    _wrapper.writeInt8(value);
    _updateLogicalPosition();
  }

  /// Writes a signed 16-bit integer [value] to the buffer (Little-Endian).
  ///
  /// Corresponds to serializing an `i16` in Rust.
  /// If `unchecked` is true, range validation and buffer capacity checks are skipped.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct Point {
  ///     x_coord: i16, // Use for this field
  /// }
  /// ```
  /// **Layout:** 2 bytes, Little Endian.
  @override
  void writeI16(int value) {
    if (!unchecked) {
      if (value < -0x8000 || value > 0x7FFF) {
        throw InvalidWriteRangeException(value, 'i16',
            minValue: -0x8000, maxValue: 0x7FFF);
      }
      _ensureCapacity(2);
    }
    _wrapper.writeInt16(value);
    _updateLogicalPosition();
  }

  /// Writes a signed 32-bit integer [value] to the buffer (Little-Endian).
  ///
  /// Corresponds to serializing an `i32` in Rust.
  /// If `unchecked` is true, range validation and buffer capacity checks are skipped.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct Event {
  ///     status_code: i32, // Use for this field
  /// }
  /// ```
  /// **Layout:** 4 bytes, Little Endian.
  @override
  void writeI32(int value) {
    if (!unchecked) {
      if (value < -0x80000000 || value > 0x7FFFFFFF) {
        throw InvalidWriteRangeException(value, 'i32',
            minValue: -0x80000000, maxValue: 0x7FFFFFFF);
      }
      _ensureCapacity(4);
    }
    _wrapper.writeInt32(value);
    _updateLogicalPosition();
  }

  /// Writes a signed 64-bit integer [value] to the buffer (Little-Endian).
  ///
  /// Corresponds to serializing an `i64` in Rust.
  /// If `unchecked` is true, buffer capacity checks are skipped. (Range check implicit in Dart `int`).
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct FileInfo {
  ///     file_id: i64, // Use for this field
  /// }
  /// ```
  /// **Layout:** 8 bytes, Little Endian.
  @override
  void writeI64(int value) {
    if (!unchecked) {
      _ensureCapacity(8);
    }
    _wrapper.writeInt64(value);
    _updateLogicalPosition();
  }

  /// Writes a 32-bit floating point number [value] (IEEE 754) to the buffer (Little-Endian).
  ///
  /// Corresponds to serializing an `f32` in Rust.
  /// If `unchecked` is true, buffer capacity checks are skipped.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct Measurement {
  ///     value: f32, // Use for this field
  /// }
  /// ```
  /// **Layout:** 4 bytes, IEEE 754, Little Endian.
  @override
  void writeF32(double value) {
    if (!unchecked) {
      _ensureCapacity(4);
    }
    _wrapper.writeFloat32(value);
    _updateLogicalPosition();
  }

  /// Writes a 64-bit floating point number [value] (IEEE 754) to the buffer (Little-Endian).
  ///
  /// Corresponds to serializing an `f64` in Rust.
  /// If `unchecked` is true, buffer capacity checks are skipped.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct Coordinates {
  ///     latitude: f64, // Use for this field
  /// }
  /// ```
  /// **Layout:** 8 bytes, IEEE 754, Little Endian.
  @override
  void writeF64(double value) {
    if (!unchecked) {
      _ensureCapacity(8);
    }
    _wrapper.writeFloat64(value);
    _updateLogicalPosition();
  }

  /// Writes a boolean [value] to the buffer as a single byte (1 for true, 0 for false).
  ///
  /// Corresponds to serializing a `bool` in Rust.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct Status {
  ///     is_active: bool, // Use for this field
  /// }
  /// ```
  /// **Layout:** 1 byte (0 or 1).
  @override
  void writeBool(bool value) {
    writeU8(value ? 1 : 0);
  }

  /// Writes the raw list of bytes [bytes] sequentially to the buffer.
  ///
  /// This is suitable for writing data corresponding to Rust's `Vec<u8>`, `&[u8]`, or fixed arrays like `[u8; N]`.
  /// Note that this method does *not* write a length prefix; use [writeList] or [writeUint8List] if a Bincode sequence length is needed.
  /// If `unchecked` is true, buffer capacity checks are skipped.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct Packet {
  ///     payload: Vec<u8>,   // Use writeUint8List (includes length) or writeBytes (raw)
  ///     signature: [u8; 64], // Use writeBytes for this field
  /// }
  /// ```
  /// **Layout:** The raw sequence of bytes provided in the [bytes] list.
  @override
  void writeBytes(List<int> bytes) {
    final length = bytes.length;
    if (!unchecked) {
      _ensureCapacity(length);
    }
    _wrapper.writeBytes(bytes);
    _updateLogicalPosition();
  }

  /// Encodes the given string [value] (default UTF-8) and writes its U64 length prefix followed by the encoded bytes.
  ///
  /// Corresponds directly to serializing a `String` in Rust.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct User {
  ///     username: String, // Use for this field
  /// }
  /// ```
  /// **Layout:** `[u64 length][encoded string bytes...]`
  @override
  void writeString(String value,
      [StringEncoding encoding = StringEncoding.utf8]) {
    final encoded = encodeString(value, encoding);
    writeU64(encoded.length);
    writeBytes(encoded);
  }

  /// Writes a fixed-length byte representation of the string [value] to the buffer.
  ///
  /// Encodes the string (UTF-8), then writes exactly `length` bytes. If the encoded
  /// string is shorter than `length`, it's padded with trailing zeros. If longer,
  /// it's truncated. Throws if `length` is negative.
  ///
  /// #### Rust Context Example (Conceptual):
  /// ```rust
  /// #[derive(Serialize)]
  /// struct LegacyRecord {
  ///     // Fixed-size name field (e.g., UTF-8 truncated/padded to 32 bytes)
  ///     name_fixed: [u8; 32], // Use for this field
  /// }
  /// ```
  /// **Layout:** Exactly `length` bytes.
  @override
  void writeFixedString(String value, int length) {
    if (length < 0) {
      throw BincodeWriteException(
          'Fixed string length cannot be negative: $length');
    }
    final encodedBytes = encodeString(value, StringEncoding.utf8);
    final bytesToWrite = Uint8List(length);

    final bytesToCopy =
        encodedBytes.length < length ? encodedBytes.length : length;

    for (var i = 0; i < bytesToCopy; i++) {
      bytesToWrite[i] = encodedBytes[i];
    }
    writeBytes(bytesToWrite);
  }

  // --- Optional Value Writing Methods ---

  /// Writes an optional boolean [value] according to Bincode's `Option<T>` encoding.
  ///
  /// Writes a 1-byte flag (0 for None/null, 1 for Some/non-null). If Some,
  /// it then writes the boolean value using [writeBool] (as a single byte, 0 or 1).
  /// Corresponds to serializing `Option<bool>` in Rust.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct Flags {
  ///     is_enabled: Option<bool>, // Use for this field
  /// }
  /// ```
  /// **Layout:** `[0]` if `value` is `null`, `[1][0]` (false) or `[1][1]` (true) otherwise.
  @override
  void writeOptionBool(bool? value) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeBool(value);
  }

  /// Writes an optional unsigned 8-bit integer [value] according to Bincode's `Option<T>` encoding.
  ///
  /// Writes a 1-byte flag (0 for None/null, 1 for Some/non-null). If Some,
  /// it then writes the `u8` value using [writeU8].
  /// Corresponds to serializing `Option<u8>` in Rust.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct Config {
  ///     priority: Option<u8>, // Use for this field
  /// }
  /// ```
  /// **Layout:** `[0]` if `value` is `null`, `[1][u8 byte]` otherwise.
  @override
  void writeOptionU8(int? value) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeU8(value);
  }

  /// Writes an optional unsigned 16-bit integer [value] according to Bincode's `Option<T>` encoding.
  ///
  /// Writes a 1-byte flag (0 for None/null, 1 for Some/non-null). If Some,
  /// it then writes the `u16` value using [writeU16].
  /// Corresponds to serializing `Option<u16>` in Rust.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct Item {
  ///     item_id: Option<u16>, // Use for this field
  /// }
  /// ```
  /// **Layout:** `[0]` if `value` is `null`, `[1][u16 bytes]` otherwise.
  @override
  void writeOptionU16(int? value) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeU16(value);
  }

  /// Writes an optional unsigned 32-bit integer [value] according to Bincode's `Option<T>` encoding.
  ///
  /// Writes a 1-byte flag (0 for None/null, 1 for Some/non-null). If Some,
  /// it then writes the `u32` value using [writeU32].
  /// Corresponds to serializing `Option<u32>` in Rust.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct Message {
  ///     sequence_num: Option<u32>, // Use for this field
  /// }
  /// ```
  /// **Layout:** `[0]` if `value` is `null`, `[1][u32 bytes]` otherwise.
  @override
  void writeOptionU32(int? value) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeU32(value);
  }

  /// Writes an optional unsigned 64-bit integer [value] according to Bincode's `Option<T>` encoding.
  ///
  /// Writes a 1-byte flag (0 for None/null, 1 for Some/non-null). If Some,
  /// it then writes the `u64` value using [writeU64].
  /// Corresponds to serializing `Option<u64>` in Rust.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct Timestamps {
  ///     last_updated_ns: Option<u64>, // Use for this field
  /// }
  /// ```
  /// **Layout:** `[0]` if `value` is `null`, `[1][u64 bytes]` otherwise.
  @override
  void writeOptionU64(int? value) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeU64(value);
  }

  /// Writes an optional signed 8-bit integer [value] according to Bincode's `Option<T>` encoding.
  ///
  /// Writes a 1-byte flag (0 for None/null, 1 for Some/non-null). If Some,
  /// it then writes the `i8` value using [writeI8].
  /// Corresponds to serializing `Option<i8>` in Rust.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct Adjustment {
  ///     delta: Option<i8>, // Use for this field
  /// }
  /// ```
  /// **Layout:** `[0]` if `value` is `null`, `[1][i8 byte]` otherwise.
  @override
  void writeOptionI8(int? value) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeI8(value);
  }

  /// Writes an optional signed 16-bit integer [value] according to Bincode's `Option<T>` encoding.
  ///
  /// Writes a 1-byte flag (0 for None/null, 1 for Some/non-null). If Some,
  /// it then writes the `i16` value using [writeI16].
  /// Corresponds to serializing `Option<i16>` in Rust.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct Point {
  ///     z_coord: Option<i16>, // Use for this field
  /// }
  /// ```
  /// **Layout:** `[0]` if `value` is `null`, `[1][i16 bytes]` otherwise.
  @override
  void writeOptionI16(int? value) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeI16(value);
  }

  /// Writes an optional signed 32-bit integer [value] according to Bincode's `Option<T>` encoding.
  ///
  /// Writes a 1-byte flag (0 for None/null, 1 for Some/non-null). If Some,
  /// it then writes the `i32` value using [writeI32].
  /// Corresponds to serializing `Option<i32>` in Rust.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct Event {
  ///     event_code: Option<i32>, // Use for this field
  /// }
  /// ```
  /// **Layout:** `[0]` if `value` is `null`, `[1][i32 bytes]` otherwise.
  @override
  void writeOptionI32(int? value) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeI32(value);
  }

  /// Writes an optional signed 64-bit integer [value] according to Bincode's `Option<T>` encoding.
  ///
  /// Writes a 1-byte flag (0 for None/null, 1 for Some/non-null). If Some,
  /// it then writes the `i64` value using [writeI64].
  /// Corresponds to serializing `Option<i64>` in Rust.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct FileInfo {
  ///     size_bytes: Option<i64>, // Use for this field
  /// }
  /// ```
  /// **Layout:** `[0]` if `value` is `null`, `[1][i64 bytes]` otherwise.
  @override
  void writeOptionI64(int? value) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeI64(value);
  }

  /// Writes an optional 32-bit floating point number [value] according to Bincode's `Option<T>`encoding.
  ///
  /// Writes a 1-byte flag (0 for None/null, 1 for Some/non-null). If Some,
  /// it then writes the `f32` value using [writeF32].
  /// Corresponds to serializing `Option<f32>` in Rust.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct Measurement {
  ///     temperature: Option<f32>, // Use for this field
  /// }
  /// ```
  /// **Layout:** `[0]` if `value` is `null`, `[1][f32 bytes]` otherwise.
  @override
  void writeOptionF32(double? value) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeF32(value);
  }

  /// Writes an optional 64-bit floating point number [value] according to Bincode's `Option<T>` encoding.
  ///
  /// Writes a 1-byte flag (0 for None/null, 1 for Some/non-null). If Some,
  /// it then writes the `f64` value using [writeF64].
  /// Corresponds to serializing `Option<f64>` in Rust.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct Coordinates {
  ///     longitude: Option<f64>, // Use for this field
  /// }
  /// ```
  /// **Layout:** `[0]` if `value` is `null`, `[1][f64 bytes]` otherwise.
  @override
  void writeOptionF64(double? value) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeF64(value);
  }

  /// Writes an optional string [value] according to Bincode's `Option<T>` encoding.
  ///
  /// Writes a 1-byte flag (0 for None/null, 1 for Some/non-null). If Some,
  /// it then writes the string value using [writeString], which includes a
  /// U64 length prefix followed by the string bytes (default UTF-8).
  /// Corresponds to serializing `Option<String>` in Rust.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct UserProfile {
  ///     nickname: Option<String>, // Use for this field
  /// }
  /// ```
  /// **Layout:** `[0]` if `value` is `null`, `[1][u64 length][string bytes...]` otherwise.
  @override
  void writeOptionString(String? value,
      [StringEncoding encoding = StringEncoding.utf8]) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeString(value, encoding);
  }

  /// Writes an optional fixed-length string representation [value] to the buffer.
  ///
  /// Writes a 1-byte flag (0 for None/null, 1 for Some/non-null). If Some,
  /// it then writes a fixed number of bytes (`length`) derived from the string
  /// using [writeFixedString], padding with zeros or truncating as necessary.
  ///
  /// #### Rust Context Example (Conceptual):
  /// ```rust
  /// #[derive(Serialize)]
  /// struct Record {
  ///     // If tag is optional and always stored in 8 bytes (UTF-8, padded/truncated)
  ///     optional_tag: Option<[u8; 8]>, // Use for this field conceptually
  /// }
  /// ```
  /// **Layout:** `[0]` if `value` is `null`, `[1][N fixed bytes...]` otherwise.
  @override
  void writeOptionFixedString(String? value, int length) {
    writeU8(value != null ? 1 : 0);
    if (value != null) writeFixedString(value, length);
  }

  /// Writes an optional 3-element Float32List [vec3] according to Bincode's `Option<T>` encoding for fixed arrays.
  ///
  /// Writes a 1-byte flag (0 for None/null, 1 for Some/non-null). If Some,
  /// it verifies the list has exactly 3 elements and then writes the three `f32`
  /// values sequentially using [writeF32]. Does not write extra padding for the None case.
  /// Throws [BincodeWriteException] if a non-null list with length != 3 is provided.
  /// Corresponds to serializing `Option<[f32; 3]>` in Rust.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct Transform {
  ///     // Optional 3D scale vector
  ///     scale: Option<[f32; 3]>, // Use for this field
  /// }
  /// ```
  /// **Layout:** `[0]` if `vec3` is `null`, `[1][f32 bytes][f32 bytes][f32 bytes]` otherwise.
  @override
  void writeOptionF32Triple(Float32List? vec3) {
    if (vec3 == null) {
      writeU8(0);
    } else {
      if (vec3.length != 3) {
        throw BincodeWriteException(
            'Expected Float32List with 3 elements, but got ${vec3.length}');
      }
      writeU8(1);
      writeF32(vec3[0]);
      writeF32(vec3[1]);
      writeF32(vec3[2]);
    }
  }

  /// Writes a generic list of [values] as a Bincode sequence.
  ///
  /// Writes a U64 length prefix (number of elements) followed by each element
  /// serialized using the provided [writeElement] callback function.
  /// This is the generic method for lists of any type `T`. For lists of primitive
  /// types, prefer the specialized methods like [writeInt32List] for better performance.
  /// Corresponds to serializing `Vec<T>` in Rust where `T` can be any serializable type.
  ///
  /// **Performance Warning:** This method can be less performant for large lists compared
  /// to specialized methods (e.g., [writeInt32List], [writeFloat64List]) for primitive types,
  /// or using `writeBytes` directly for `Uint8List`, due to Dart loop overhead and
  /// function call indirection for each element.
  ///
  /// The internal calls to [writeU64] and any methods called within the [writeElement]
  /// callback respect the `unchecked` flag for range and capacity checks.
  ///
  /// #### Rust Context Example:
  ///  Used when serializing `Vec<T>` where T is a custom struct, enum, or complex type.
  /// ```rust
  /// #[derive(Serialize)]
  /// struct Scene {
  ///     // Vec of custom structs, each serialized via callback in Dart
  ///     objects: Vec<SceneObject>, // Use for this field
  /// }
  ///
  /// #[derive(Serialize)]
  /// struct SceneObject { /* id, position, etc. */ }
  /// ```
  /// **Layout:** `[u64 length][element 1 bytes][element 2 bytes]...`
  @override
  void writeList<T>(List<T> values, void Function(T value) writeElement) {
    writeU64(values.length);
    for (final value in values) {
      writeElement(value);
    }
  }

  /// Writes a generic map of key-value pairs [values] as a Bincode sequence.
  ///
  /// Writes a U64 length prefix (number of key-value entries) followed by each entry.
  /// Each entry consists of the key serialized using the [writeKey] callback,
  /// immediately followed by the value serialized using the [writeValue] callback.
  /// This is the generic method for maps with any serializable key/value types `K` and `V`.
  /// Corresponds to serializing map types like `HashMap<K, V>` or `BTreeMap<K, V>` in Rust.
  ///
  /// **Performance Warning:** Similar to [writeList], this can be less performant for large
  /// maps due to iteration and callback overhead for each key and value.
  ///
  /// The internal calls to [writeU64] and any methods called within the [writeKey] and
  /// [writeValue] callbacks respect the `unchecked` flag for range and capacity checks.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// use std::collections::HashMap;
  ///
  /// #[derive(Serialize)]
  /// struct GameState {
  ///     // Map from player ID (String) to PlayerData (custom struct)
  ///     players: HashMap<String, PlayerData>, // Use for this field
  /// }
  ///
  /// #[derive(Serialize)]
  /// struct PlayerData { /* score, position, inventory, etc. */ }
  /// ```
  /// **Layout:** `[u64 num_entries][key 1 bytes][value 1 bytes][key 2 bytes][value 2 bytes]...`
  @override
  void writeMap<K, V>(Map<K, V> values, void Function(K key) writeKey,
      void Function(V value) writeValue) {
    writeU64(values.length);
    for (final entry in values.entries) {
      writeKey(entry.key);
      writeValue(entry.value);
    }
  }

// --- Specialized List Writers ---

  /// Writes a u64 length prefix followed by the list of signed 8‑bit integers [values].
  /// Optimizes for `Int8List` by writing its raw bytes.
  /// Writes a Bincode sequence representation of the list of signed 8-bit integers [values].
  ///
  /// Writes a U64 length prefix followed by the elements. It optimizes performance
  /// by checking if [values] is an [Int8List] and writing its raw byte
  /// representation directly using [writeBytes] if possible. Otherwise, it iterates
  /// and writes each element individually using [writeI8].
  /// Corresponds to serializing `Vec<i8>` in Rust.
  /// The internal write calls respect the `unchecked` flag.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct AudioSample {
  ///     pcm_data_i8: Vec<i8>, // Use for this field
  /// }
  /// ```
  /// **Layout:** `[u64 length][i8 byte][i8 byte]...`
  @override
  void writeInt8List(List<int> values) {
    writeU64(values.length);
    if (values is Int8List) {
      writeBytes(values.buffer
          .asUint8List(values.offsetInBytes, values.lengthInBytes));
    } else {
      values.forEach(writeI8);
    }
  }

  /// Writes a Bincode sequence representation of the list of signed 16-bit integers [values].
  ///
  /// Writes a U64 length prefix followed by the elements. It optimizes performance
  /// by checking if [values] is an [Int16List] and writing its raw byte
  /// representation directly using [writeBytes] if possible. Otherwise, it iterates
  /// and writes each element individually using [writeI16].
  /// Corresponds to serializing `Vec<i16>` in Rust.
  /// The internal write calls respect the `unchecked` flag.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct PointCloud {
  ///     coords_i16: Vec<i16>, // Use for this field (e.g., x1, y1, z1, x2, y2, z2...)
  /// }
  /// ```
  /// **Layout:** `[u64 length][i16 bytes][i16 bytes]...` (Little Endian elements)
  @override
  void writeInt16List(List<int> values) {
    writeU64(values.length);
    if (values is Int16List) {
      writeBytes(values.buffer
          .asUint8List(values.offsetInBytes, values.lengthInBytes));
    } else {
      values.forEach(writeI16);
    }
  }

  /// Writes a Bincode sequence representation of the list of signed 32-bit integers [values].
  ///
  /// Writes a U64 length prefix followed by the elements. It optimizes performance
  /// by checking if [values] is an [Int32List] and writing its raw byte
  /// representation directly using [writeBytes] if possible. Otherwise, it iterates
  /// and writes each element individually using [writeI32].
  /// Corresponds to serializing `Vec<i32>` in Rust.
  /// The internal write calls respect the `unchecked` flag.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct IdList {
  ///     user_ids: Vec<i32>, // Use for this field
  /// }
  /// ```
  /// **Layout:** `[u64 length][i32 bytes][i32 bytes]...` (Little Endian elements)
  @override
  void writeInt32List(List<int> values) {
    writeU64(values.length);
    if (values is Int32List) {
      writeBytes(values.buffer
          .asUint8List(values.offsetInBytes, values.lengthInBytes));
    } else {
      values.forEach(writeI32);
    }
  }

  /// Writes a Bincode sequence representation of the list of signed 64-bit integers [values].
  ///
  /// Writes a U64 length prefix followed by the elements. It optimizes performance
  /// by checking if [values] is an [Int64List] and writing its raw byte
  /// representation directly using [writeBytes] if possible. Otherwise, it iterates
  /// and writes each element individually using [writeI64].
  /// Corresponds to serializing `Vec<i64>` in Rust.
  /// The internal write calls respect the `unchecked` flag.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct EventLog {
  ///     timestamps_ms: Vec<i64>, // Use for this field
  /// }
  /// ```
  /// **Layout:** `[u64 length][i64 bytes][i64 bytes]...` (Little Endian elements)
  @override
  void writeInt64List(List<int> values) {
    writeU64(values.length);
    if (values is Int64List) {
      writeBytes(values.buffer
          .asUint8List(values.offsetInBytes, values.lengthInBytes));
    } else {
      values.forEach(writeI64);
    }
  }

  /// Writes a Bincode sequence representation of the list of unsigned 8-bit integers [values].
  ///
  /// Writes a U64 length prefix followed by the bytes. It optimizes performance
  /// by checking if [values] is a [Uint8List] and writing it directly using [writeBytes]
  /// if possible (most efficient). Otherwise, it iterates and writes each byte
  /// individually using [writeU8].
  /// Corresponds to serializing `Vec<u8>` in Rust.
  /// The internal write calls respect the `unchecked` flag.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct RawData {
  ///     buffer: Vec<u8>, // Use for this field
  /// }
  /// ```
  /// **Layout:** `[u64 length][u8 byte][u8 byte]...`
  @override
  void writeUint8List(List<int> values) {
    writeU64(values.length);
    if (values is Uint8List) {
      // If it's already Uint8List, write its bytes directly (most efficient)
      writeBytes(values);
    } else {
      // Otherwise, iterate and write each element
      values.forEach(writeU8);
    }
  }

  /// Writes a Bincode sequence representation of the list of unsigned 16-bit integers [values].
  ///
  /// Writes a U64 length prefix followed by the elements. It optimizes performance
  /// by checking if [values] is a [Uint16List] and writing its raw byte
  /// representation directly using [writeBytes] if possible. Otherwise, it iterates
  /// and writes each element individually using [writeU16].
  /// Corresponds to serializing `Vec<u16>` in Rust.
  /// The internal write calls respect the `unchecked` flag.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct CharCodes {
  ///     utf16_codes: Vec<u16>, // Use for this field
  /// }
  /// ```
  /// **Layout:** `[u64 length][u16 bytes][u16 bytes]...` (Little Endian elements)
  @override
  void writeUint16List(List<int> values) {
    writeU64(values.length);
    if (values is Uint16List) {
      writeBytes(values.buffer
          .asUint8List(values.offsetInBytes, values.lengthInBytes));
    } else {
      values.forEach(writeU16);
    }
  }

  /// Writes a Bincode sequence representation of the list of unsigned 32-bit integers [values].
  ///
  /// Writes a U64 length prefix followed by the elements. It optimizes performance
  /// by checking if [values] is a [Uint32List] and writing its raw byte
  /// representation directly using [writeBytes] if possible. Otherwise, it iterates
  /// and writes each element individually using [writeU32].
  /// Corresponds to serializing `Vec<u32>` in Rust.
  /// The internal write calls respect the `unchecked` flag.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct ColorPalette {
  ///     rgba_colors: Vec<u32>, // Use for this field
  /// }
  /// ```
  /// **Layout:** `[u64 length][u32 bytes][u32 bytes]...` (Little Endian elements)
  @override
  void writeUint32List(List<int> values) {
    writeU64(values.length);
    if (values is Uint32List) {
      writeBytes(values.buffer
          .asUint8List(values.offsetInBytes, values.lengthInBytes));
    } else {
      values.forEach(writeU32);
    }
  }

  /// Writes a Bincode sequence representation of the list of unsigned 64-bit integers [values].
  ///
  /// Writes a U64 length prefix followed by the elements. It optimizes performance
  /// by checking if [values] is a [Uint64List] and writing its raw byte
  /// representation directly using [writeBytes] if possible. Otherwise, it iterates
  /// and writes each element individually using [writeU64].
  /// Corresponds to serializing `Vec<u64>` in Rust.
  /// The internal write calls respect the `unchecked` flag.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct IdentifierList {
  ///     unique_ids: Vec<u64>, // Use for this field
  /// }
  /// ```
  /// **Layout:** `[u64 length][u64 bytes][u64 bytes]...` (Little Endian elements)
  @override
  void writeUint64List(List<int> values) {
    writeU64(values.length);
    if (values is Uint64List) {
      writeBytes(values.buffer
          .asUint8List(values.offsetInBytes, values.lengthInBytes));
    } else {
      values.forEach(writeU64);
    }
  }

  /// Writes a Bincode sequence representation of the list of 32-bit floats [values].
  ///
  /// Writes a U64 length prefix followed by the elements. It optimizes performance
  /// by checking if [values] is a [Float32List] and writing its raw byte
  /// representation directly using [writeBytes] if possible. Otherwise, it iterates
  /// and writes each element individually using [writeF32].
  /// Corresponds to serializing `Vec<f32>` in Rust.
  /// The internal write calls respect the `unchecked` flag.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct SignalData {
  ///     samples_f32: Vec<f32>, // Use for this field
  /// }
  /// ```
  /// **Layout:** `[u64 length][f32 bytes][f32 bytes]...` (IEEE 754, Little Endian elements)
  @override
  void writeFloat32List(List<double> values) {
    writeU64(values.length);
    if (values is Float32List) {
      writeBytes(values.buffer
          .asUint8List(values.offsetInBytes, values.lengthInBytes));
    } else {
      values.forEach(writeF32);
    }
  }

  /// Writes a Bincode sequence representation of the list of 64-bit floats [values].
  ///
  /// Writes a U64 length prefix followed by the elements. It optimizes performance
  /// by checking if [values] is a [Float64List] and writing its raw byte
  /// representation directly using [writeBytes] if possible. Otherwise, it iterates
  /// and writes each element individually using [writeF64].
  /// Corresponds to serializing `Vec<f64>` in Rust.
  /// The internal write calls respect the `unchecked` flag.
  ///
  /// #### Rust Context Example:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct GraphPoints {
  ///     y_values: Vec<f64>, // Use for this field
  /// }
  /// ```
  /// **Layout:** `[u64 length][f64 bytes][f64 bytes]...` (IEEE 754, Little Endian elements)
  @override
  void writeFloat64List(List<double> values) {
    writeU64(values.length);
    if (values is Float64List) {
      writeBytes(values.buffer
          .asUint8List(values.offsetInBytes, values.lengthInBytes));
    } else {
      values.forEach(writeF64);
    }
  }

  // --- Nested Object Writing Methods ---

  /// Writes a nested [BincodeEncodable] object [value] to the buffer **with a length prefix**.
  /// Corresponds to dynamic collection elements (e.g., `Vec<T>`).
  /// **DEPRECATED:** Use `writeNestedValueForCollection` explicitly.
  @Deprecated(
      'Use writeNestedValueForCollection or writeNestedValueForFixed instead')
  @override
  void writeNested(BincodeEncodable value) {
    final bytes = value.toBincode();
    writeU64(bytes.length);
    writeBytes(bytes);
  }

  /// Writes an optional nested [BincodeEncodable] object [value] to the buffer.
  /// Writes flag byte, then (if Some) length prefix and bytes.
  /// Corresponds to `Option<T>` where T is dynamic.
  /// **DEPRECATED:** Use `writeOptionNestedValueForCollection` explicitly.
  @Deprecated(
      'Use writeOptionNestedValueForCollection or writeOptionNestedValueForFixed instead')
  @override
  void writeOptionNested(BincodeEncodable? value) {
    if (value == null) {
      writeU8(0);
      return;
    }
    writeU8(1);
    writeNested(value);
  }

  /// Writes a custom [BincodeEncodable] object [value] prefixed with its U64 length.
  ///
  /// Use this method **only** when serializing a Dart field holding a custom object
  /// (which implements `BincodeEncodable`) that corresponds to a dynamically sized
  /// field type in Rust, such as an element within a `Vec<CustomStruct>`.
  /// This method prepends the byte length before the object's serialized bytes.
  ///
  /// **Do not use** for standard Dart `String` (use `writeString`) or `List`
  /// (use `writeList` or specialized list writers like `writeInt32List`).
  ///
  /// #### Rust Context Example:
  /// This method applies when serializing each `MyItem` element within the `items` Vec:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct Container {
  ///     items: Vec<MyItem>, // Use for each MyItem element
  /// }
  ///
  /// #[derive(Serialize)]
  /// struct MyItem { /* fields */ }
  /// // In Dart: MyItem instance passed must implement BincodeEncodable
  /// ```
  /// **Layout:** `[u64 length][bytes...]` where `bytes` are from `value.toBincode()`.
  void writeNestedValueForCollection(BincodeEncodable value) {
    final bytes = value.toBincode();
    writeU64(bytes.length);
    writeBytes(bytes);
  }

  /// Writes the raw bincode encoding of a custom [BincodeEncodable] object [value] directly,
  /// *without* any length prefix.
  ///
  /// Use this method **only** when serializing a Dart field holding a custom object
  /// (which implements `BincodeEncodable`) that corresponds to a fixed-size Rust
  /// struct field embedded directly within another struct.
  ///
  /// **Do not use** for primitives (use `writeInt32`, etc.), standard `String`
  /// (use `writeString`), or byte arrays (use `writeBytes`).
  ///
  /// #### Rust Context Example:
  /// This method applies when serializing the `inner_data` field:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct Outer {
  ///     inner_data: InnerStruct, // Use for this field
  /// }
  ///
  /// #[derive(Serialize)]
  /// struct InnerStruct { /* fields */ }
  /// // In Dart: InnerStruct instance passed must implement BincodeEncodable
  /// ```
  /// **Layout:** `[bytes...]` where `bytes` are from `value.toBincode()`.
  void writeNestedValueForFixed(BincodeEncodable value) {
    final bytes = value.toBincode();
    writeBytes(bytes);
  }

  /// Writes an optional custom [BincodeEncodable] object [value], suitable for dynamically sized types.
  ///
  /// Writes a 1-byte flag (0 for None, 1 for Some). If Some, it then writes the
  /// U64 length followed by the value's bytes (obtained from `value.toBincode()`).
  /// Use **only** when serializing an optional Dart field holding a custom object (`YourClass?`)
  /// corresponding to Rust `Option<T>` where `T` represents a dynamic type like `Vec<CustomStruct>`.
  ///
  /// **Do not use** for `Option<String>` (use `writeOptionString`) or optional lists
  /// (use `writeList` with an optional element writer or similar).
  ///
  /// #### Rust Context Example:
  /// This method applies when serializing the `maybe_items` field:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct DataHolder {
  ///     maybe_items: Option<Vec<MyItem>>, // Use for this field
  /// }
  ///
  /// #[derive(Serialize)]
  /// struct MyItem { /* fields */ }
  /// // In Dart: MyItem instance passed (if Some) must implement BincodeEncodable
  /// ```
  /// **Layout:** `[0]` if `value` is `null`, `[1][u64 length][bytes...]` otherwise.
  void writeOptionNestedValueForCollection(BincodeEncodable? value) {
    if (value == null) {
      writeU8(0);
    } else {
      writeU8(1);
      writeNestedValueForCollection(value);
    }
  }

  /// Writes an optional custom [BincodeEncodable] object [value], suitable for fixed-size types.
  ///
  /// Writes a 1-byte flag (0 for None, 1 for Some). If Some, it writes the raw
  /// bytes of the value (obtained from `value.toBincode()`) directly, *without* a length prefix.
  /// Use **only** when serializing an optional Dart field holding a custom object (`YourClass?`)
  /// corresponding to Rust `Option<T>` where `T` is a fixed-size struct.
  ///
  /// **Do not use** for optional primitives (use `writeOptionI32`, etc.),
  /// `Option<String>` (use `writeOptionString`), or optional byte arrays
  /// (handle manually with `writeU8` flag + `writeBytes`, or use a specific helper).
  ///
  /// #### Rust Context Example:
  /// This method applies when serializing the `optional_settings` field:
  /// ```rust
  /// #[derive(Serialize)]
  /// struct Config {
  ///     optional_settings: Option<InnerSettings>, // Use for this field
  /// }
  ///
  /// #[derive(Serialize)]
  /// struct InnerSettings { /* fields */ }
  /// // In Dart: InnerSettings instance passed (if Some) must implement BincodeEncodable
  /// ```
  /// **Layout:** `[0]` if `value` is `null`, `[1][bytes...]` otherwise.
  void writeOptionNestedValueForFixed(BincodeEncodable? value) {
    if (value == null) {
      writeU8(0);
    } else {
      writeU8(1);
      writeNestedValueForFixed(value);
    }
  }

  // --- Final Output Methods ---

  /// Returns a [Uint8List] containing a copy of the bytes written to the buffer so far.
  @override
  Uint8List toBytes() {
    return _wrapper.buffer.asUint8List(0, _position);
  }

  /// Asynchronously writes the serialized data to a file at the specified [path].
  /// If the file already exists, it will be overwritten.
  @override
  Future<void> toFile(String path) async {
    final trimmedBuffer = Uint8List.fromList(toBytes());
    await File(path).writeAsBytes(trimmedBuffer, flush: true);
  }
}
