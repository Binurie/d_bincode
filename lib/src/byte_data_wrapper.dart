/*
#################################################################
# Disclaimer: This source code is provided "as is", without any 
# warranty of any kind, express or implied, including but not 
# limited to the warranties of merchantability or fitness for 
# a particular purpose.
#################################################################
*/

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:euc/jis.dart';

/// Supported string encodings for bincode serialization/deserialization.
enum StringEncoding {
  /// UTF‑8 encoding.
  utf8,

  /// UTF‑16 encoding.
  utf16,

  /// Shift-JIS encoding.
  shiftJis,
}

/// A wrapper around [ByteBuffer] which provides convenience methods for reading
/// and writing various types in a binary format. This wrapper supports both reading
/// from and writing to buffers, handling endian‑ness and automatic buffer growth.
///
/// It maintains an internal cursor ([position]) tracking the next byte to be read or written.
///
/// The [ByteDataWrapper] is used internally by the bincode package to implement
/// readers and writers.
base class ByteDataWrapper {
  /// The underlying [ByteBuffer] used for storage.
  final ByteBuffer buffer;

  /// A view for reading and writing numeric types to/from the buffer.
  late final ByteData _data;

  /// The endian‑ness used for reading/writing multibyte values.
  Endian endian;

  /// The offset of this view relative to the parent (if any).
  final int _parentOffset;

  /// The length in bytes of this view.
  final int length;

  int _position = 0;

  /// Creates a [ByteDataWrapper] over the given [buffer].
  ///
  /// [endian] specifies the byte order used for numeric read/write operations.
  /// [parentOffset] and [length] can specify a sub‑range within the buffer.
  ByteDataWrapper(
    this.buffer, {
    this.endian = Endian.little,
    int parentOffset = 0,
    int? length,
  })  : _parentOffset = parentOffset,
        length = length ?? buffer.lengthInBytes - parentOffset {
    _data = buffer.asByteData(0, buffer.lengthInBytes);
    _position = _parentOffset;
  }

  /// Creates a new [ByteDataWrapper] with an allocated buffer of [size] bytes.
  ///
  /// The [endian] specifies the byte order used for numeric operations.
  ByteDataWrapper.allocate(int size, {this.endian = Endian.little})
      : buffer = ByteData(size).buffer,
        _parentOffset = 0,
        length = size,
        _position = 0 {
    _data = buffer.asByteData(0, buffer.lengthInBytes);
  }

  /// Asynchronously creates a [ByteDataWrapper] by reading the entire file at [path].
  ///
  /// If the file is smaller than 2GB, it is loaded in one piece; otherwise,
  /// it is loaded in chunks.
  static Future<ByteDataWrapper> fromFile(String path) async {
    const twoGB = 2 * 1024 * 1024 * 1024;
    var fileSize = await File(path).length();
    if (fileSize < twoGB) {
      var buffer = await File(path).readAsBytes();
      return ByteDataWrapper(buffer.buffer);
    } else {
      print("File is over 2GB, loading in chunks");
      var buffer = Uint8List(fileSize).buffer;
      var file = File(path).openRead();
      int position = 0;
      int i = 0;
      await for (var bytes in file) {
        buffer.asUint8List().setRange(position, position + bytes.length, bytes);
        position += bytes.length;
        if (i % 100 == 0) {
          stdout.write("${(position / fileSize * 100).round()}%\r");
        }
        i++;
      }
      print("Read $position bytes");
      return ByteDataWrapper(buffer);
    }
  }

  /// Saves the buffer content to the file at the given [path].
  Future<void> save(String path) async {
    await File(path).writeAsBytes(buffer.asUint8List());
  }

  // --- Cursor and Position Access ---

  /// Gets the current read/write position within the buffer.
  int get position => _position;

  /// Sets the current read/write position to [value].
  ///
  /// Throws a [RangeError] if [value] is outside the allowable buffer range.
  set position(int value) {
    if (value < 0 || value > length) {
      throw RangeError.range(value, 0, _data.lengthInBytes, "View size");
    }
    if (value > buffer.lengthInBytes) {
      throw RangeError.range(value, 0, buffer.lengthInBytes, "Buffer size");
    }
    _position = value + _parentOffset;
  }

  // --- Reading Methods ---

  /// Reads a 32‑bit floating point number from the current position.
  ///
  /// Advances the position by 4 bytes.
  double readFloat32() {
    var value = _data.getFloat32(_position, endian);
    _position += 4;
    return value;
  }

  /// Reads a 64‑bit floating point number from the current position.
  ///
  /// Advances the position by 8 bytes.
  double readFloat64() {
    var value = _data.getFloat64(_position, endian);
    _position += 8;
    return value;
  }

  /// Reads a signed 8‑bit integer from the current position.
  ///
  /// Advances the position by 1 byte.
  int readInt8() {
    var value = _data.getInt8(_position);
    _position += 1;
    return value;
  }

  /// Reads a signed 16‑bit integer from the current position.
  ///
  /// Advances the position by 2 bytes.
  int readInt16() {
    var value = _data.getInt16(_position, endian);
    _position += 2;
    return value;
  }

  /// Reads a signed 32‑bit integer from the current position.
  ///
  /// Advances the position by 4 bytes.
  int readInt32() {
    var value = _data.getInt32(_position, endian);
    _position += 4;
    return value;
  }

  /// Reads a signed 64‑bit integer from the current position.
  ///
  /// Advances the position by 8 bytes.
  int readInt64() {
    var value = _data.getInt64(_position, endian);
    _position += 8;
    return value;
  }

  /// Reads an unsigned 8‑bit integer from the current position.
  ///
  /// Advances the position by 1 byte.
  int readUint8() {
    var value = _data.getUint8(_position);
    _position += 1;
    return value;
  }

  /// Reads an unsigned 16‑bit integer from the current position.
  ///
  /// Advances the position by 2 bytes.
  int readUint16() {
    var value = _data.getUint16(_position, endian);
    _position += 2;
    return value;
  }

  /// Reads an unsigned 32‑bit integer from the current position.
  ///
  /// Advances the position by 4 bytes.
  int readUint32() {
    var value = _data.getUint32(_position, endian);
    _position += 4;
    return value;
  }

  /// Reads an unsigned 64‑bit integer from the current position.
  ///
  /// Advances the position by 8 bytes.
  int readUint64() {
    var value = _data.getUint64(_position, endian);
    _position += 8;
    return value;
  }

  /// Reads a list of 32‑bit floating point numbers of [length].
  ///
  /// Returns a [List<double>] and advances the position accordingly.
  List<double> readFloat32List(int length) {
    var list = List<double>.generate(length, (_) => readFloat32());
    return list;
  }

  /// Reads a list of 64‑bit floating point numbers of [length].
  ///
  /// Returns a [List<double>] and advances the position accordingly.
  List<double> readFloat64List(int length) {
    var list = List<double>.generate(length, (_) => readFloat64());
    return list;
  }

  /// Reads a list of signed 8‑bit integers of [length].
  ///
  /// Returns a [List<int>] and advances the position accordingly.
  List<int> readInt8List(int length) {
    return List<int>.generate(length, (_) => readInt8());
  }

  /// Reads a list of signed 16‑bit integers of [length].
  ///
  /// Returns a [List<int>] and advances the position accordingly.
  List<int> readInt16List(int length) {
    return List<int>.generate(length, (_) => readInt16());
  }

  /// Reads a list of signed 32‑bit integers of [length].
  ///
  /// Returns a [List<int>] and advances the position accordingly.
  List<int> readInt32List(int length) {
    return List<int>.generate(length, (_) => readInt32());
  }

  /// Reads a list of signed 64‑bit integers of [length].
  ///
  /// Returns a [List<int>] and advances the position accordingly.
  List<int> readInt64List(int length) {
    return List<int>.generate(length, (_) => readInt64());
  }

  /// Reads a list of unsigned 8‑bit integers of [length].
  ///
  /// Returns a [List<int>] and advances the position accordingly.
  List<int> readUint8List(int length) {
    return List<int>.generate(length, (_) => readUint8());
  }

  /// Reads a list of unsigned 16‑bit integers of [length].
  ///
  /// Returns a [List<int>] and advances the position accordingly.
  List<int> readUint16List(int length) {
    return List<int>.generate(length, (_) => readUint16());
  }

  /// Reads a list of unsigned 32‑bit integers of [length].
  ///
  /// Returns a [List<int>] and advances the position accordingly.
  List<int> readUint32List(int length) {
    return List<int>.generate(length, (_) => readUint32());
  }

  /// Reads a list of unsigned 64‑bit integers of [length].
  ///
  /// Returns a [List<int>] and advances the position accordingly.
  List<int> readUint64List(int length) {
    return List<int>.generate(length, (_) => readUint64());
  }

  /// Reads [length] bytes from the current position and returns them as a [Uint8List].
  ///
  /// Advances the position by [length] bytes.
  Uint8List asUint8List(int length) {
    var list = Uint8List.view(buffer, _position, length);
    _position += length;
    return list;
  }

  /// Reads [length] 16‑bit integers from the current position and returns them as a [Uint16List].
  ///
  /// Advances the position by ([length] * 2) bytes.
  Uint16List asUint16List(int length) {
    var list = Uint16List.view(buffer, _position, length);
    _position += length * 2;
    return list;
  }

  /// Reads [length] 32‑bit integers from the current position and returns them as a [Uint32List].
  ///
  /// Advances the position by ([length] * 4) bytes.
  Uint32List asUint32List(int length) {
    var list = Uint32List.view(buffer, _position, length);
    _position += length * 4;
    return list;
  }

  /// Reads [length] 64‑bit integers from the current position and returns them as a [Uint64List].
  ///
  /// Advances the position by ([length] * 8) bytes.
  Uint64List asUint64List(int length) {
    var list = Uint64List.view(buffer, _position, length);
    _position += length * 8;
    return list;
  }

  /// Reads a string of [length] bytes using the specified [encoding] (default is UTF‑8).
  ///
  /// For UTF‑16 encoding, [length] should be the number of bytes, and half
  /// of that will be read as 16‑bit values.
  String readString(int length, {StringEncoding encoding = StringEncoding.utf8}) {
    List<int> bytes;
    if (encoding != StringEncoding.utf16) {
      bytes = readUint8List(length);
    } else {
      bytes = readUint16List(length ~/ 2);
    }
    return decodeString(bytes, encoding);
  }

  /// Reads a zero‑terminated UTF‑16 encoded string.
  ///
  /// Continues reading 16‑bit values until a zero value is encountered.
  /// Returns the decoded string.
  String _readStringZeroTerminatedUtf16() {
    var bytes = <int>[];
    while (true) {
      var value = _data.getUint16(_position, endian);
      _position += 2;
      if (value == 0) break;
      bytes.add(value);
    }
    return decodeString(bytes, StringEncoding.utf16);
  }

  /// Reads a zero‑terminated string using the given [encoding].
  ///
  /// If [encoding] is UTF‑16, uses a dedicated method; otherwise, reads bytes until a zero byte is found.
  /// Optionally, an [errorFallback] string can be provided, which is returned in case of decoding errors.
  String readStringZeroTerminated({StringEncoding encoding = StringEncoding.utf8, String? errorFallback}) {
    if (encoding == StringEncoding.utf16) {
      return _readStringZeroTerminatedUtf16();
    }
    var bytes = <int>[];
    while (true) {
      var byte = _data.getUint8(_position);
      _position += 1;
      if (byte == 0) break;
      bytes.add(byte);
    }
    try {
      return decodeString(bytes, encoding);
    } catch (e) {
      if (errorFallback != null) {
        return errorFallback;
      }
      rethrow;
    }
  }

  /// Creates a sub‑view of this buffer that starts at the current position and spans [length] bytes.
  ///
  /// Returns a new [ByteDataWrapper] that reflects that slice of the original buffer.
  ByteDataWrapper makeSubView(int length) {
    return ByteDataWrapper(buffer, endian: endian, parentOffset: _position, length: length);
  }

  // --- Writing Methods (Direct access) ---

  /// Writes a 32‑bit floating point number [value] at the current position using [endian] ordering.
  ///
  /// Advances the position by 4 bytes.
  void writeFloat32(double value) {
    _data.setFloat32(_position, value, endian);
    _position += 4;
  }

  /// Writes a 64‑bit floating point number [value] at the current position using [endian] ordering.
  ///
  /// Advances the position by 8 bytes.
  void writeFloat64(double value) {
    _data.setFloat64(_position, value, endian);
    _position += 8;
  }

  /// Writes a signed 8‑bit integer [value] at the current position.
  ///
  /// Advances the position by 1 byte.
  void writeInt8(int value) {
    _data.setInt8(_position, value);
    _position += 1;
  }

  /// Writes a signed 16‑bit integer [value] at the current position using [endian] ordering.
  ///
  /// Advances the position by 2 bytes.
  void writeInt16(int value) {
    _data.setInt16(_position, value, endian);
    _position += 2;
  }

  /// Writes a signed 32‑bit integer [value] at the current position using [endian] ordering.
  ///
  /// Advances the position by 4 bytes.
  void writeInt32(int value) {
    _data.setInt32(_position, value, endian);
    _position += 4;
  }

  /// Writes a signed 64‑bit integer [value] at the current position using [endian] ordering.
  ///
  /// Advances the position by 8 bytes.
  void writeInt64(int value) {
    _data.setInt64(_position, value, endian);
    _position += 8;
  }

  /// Writes an unsigned 8‑bit integer [value] at the current position.
  ///
  /// Advances the position by 1 byte.
  void writeUint8(int value) {
    _data.setUint8(_position, value);
    _position += 1;
  }

  /// Writes an unsigned 16‑bit integer [value] at the current position using [endian] ordering.
  ///
  /// Advances the position by 2 bytes.
  void writeUint16(int value) {
    _data.setUint16(_position, value, endian);
    _position += 2;
  }

  /// Writes an unsigned 32‑bit integer [value] at the current position using [endian] ordering.
  ///
  /// Advances the position by 4 bytes.
  void writeUint32(int value) {
    _data.setUint32(_position, value, endian);
    _position += 4;
  }

  /// Writes an unsigned 64‑bit integer [value] at the current position using [endian] ordering.
  ///
  /// Advances the position by 8 bytes.
  void writeUint64(int value) {
    _data.setUint64(_position, value, endian);
    _position += 8;
  }

  /// Writes a string [value] using the specified [encoding] (default is UTF‑8).
  ///
  /// The method encodes the string into bytes, then writes a 64‑bit length prefix
  /// followed by the encoded bytes.
  void writeString(String value, [StringEncoding encoding = StringEncoding.utf8]) {
    var codes = encodeString(value, encoding);
    if (encoding == StringEncoding.utf16) {
      for (var code in codes) {
        _data.setUint16(_position, code, endian);
        _position += 2;
      }
    } else {
      for (var code in codes) {
        _data.setUint8(_position, code);
        _position += 1;
      }
    }
  }

  /// Writes a null‑terminated string.
  ///
  /// Appends a null character to [value] then writes it using the specified [encoding].
  void writeString0P(String value, [StringEncoding encoding = StringEncoding.utf8]) {
    writeString("$value\x00", encoding);
  }

  /// Writes a list of bytes [value] to the buffer.
  ///
  /// Writes each byte in [value] in sequence.
  void writeBytes(List<int> value) {
    for (var byte in value) {
      _data.setUint8(_position, byte);
      _position += 1;
    }
  }
}

/// Decodes a list of integer [codes] into a string using the specified [encoding].
///
/// For UTF‑8, uses [utf8.decode] with malformed sequences allowed.
/// For UTF‑16, converts character codes directly.
/// For Shift‑JIS, uses the [ShiftJIS] decoder from the 'euc' package.
String decodeString(List<int> codes, StringEncoding encoding) {
  switch (encoding) {
    case StringEncoding.utf8:
      return utf8.decode(codes, allowMalformed: true);
    case StringEncoding.utf16:
      return String.fromCharCodes(codes);
    case StringEncoding.shiftJis:
      return ShiftJIS().decode(codes);
  }
}

/// Encodes a string [str] into a list of integers using the specified [encoding].
///
/// For UTF‑8, returns the UTF‑8 encoded bytes.
/// For UTF‑16, returns the character codes.
/// For Shift‑JIS, uses the [ShiftJIS] encoder from the 'euc' package.
List<int> encodeString(String str, StringEncoding encoding) {
  switch (encoding) {
    case StringEncoding.utf8:
      return utf8.encode(str);
    case StringEncoding.utf16:
      return str.codeUnits;
    case StringEncoding.shiftJis:
      return ShiftJIS().encode(str);
  }
}
