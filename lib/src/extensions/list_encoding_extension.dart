// ============================================================
// Disclaimer: This source code is provided "as is", without any
// warranty of any kind, express or implied, including but not
// limited to the warranties of merchantability or fitness for
// a particular purpose.
// ============================================================

import '../../d_bincode.dart';

/// Extension providing list serialization methods for [BincodeWriter].
extension BincodeListEncoding on BincodeWriter {
  /// Encodes a `List<int>` using `writeI32` for each value, prefixed with the list length (`u64`).
  void writeI32List(List<int> values) {
    writeU64(values.length);
    for (final v in values) {
      writeI32(v);
    }
  }

  /// Encodes a `List<int>` using `writeU32` for each value, prefixed with the list length (`u64`).
  void writeU32List(List<int> values) {
    writeU64(values.length);
    for (final v in values) {
      writeU32(v);
    }
  }

  /// Encodes a `List<double>` using `writeF32` for each value, prefixed with the list length (`u64`).
  void writeF32List(List<double> values) {
    writeU64(values.length);
    for (final v in values) {
      writeF32(v);
    }
  }

  /// Encodes a `List<String>` where each string is written with fixed length padding (null-padded).
  ///
  /// Useful for fixed-width string arrays commonly used in low-level formats.
  ///
  /// - [fixedLength]: the exact number of bytes each string will occupy
  void writeStringList(List<String> values, int fixedLength) {
    writeU64(values.length);
    for (final str in values) {
      writeFixedString(str, fixedLength);
    }
  }
}

/// Extension providing list deserialization methods for [BincodeReader].
extension BincodeListDecoding on BincodeReader {
  /// Decodes a list of signed 32-bit integers (`i32`) prefixed with a `u64` length.
  List<int> readI32List() {
    final length = readU64();
    return List<int>.generate(length, (_) => readI32());
  }

  /// Decodes a list of unsigned 32-bit integers (`u32`) prefixed with a `u64` length.
  List<int> readU32List() {
    final length = readU64();
    return List<int>.generate(length, (_) => readU32());
  }

  /// Decodes a list of 32-bit floats (`f32`) prefixed with a `u64` length.
  List<double> readF32List() {
    final length = readU64();
    return List<double>.generate(length, (_) => readF32());
  }

  /// Decodes a list of fixed-length strings, each occupying [fixedLength] bytes.
  ///
  /// - [fixedLength]: byte width of each string
  /// - [encoding]: character encoding used, defaults to UTF-8
  List<String> readFixedStringList(int fixedLength,
      {StringEncoding encoding = StringEncoding.utf8}) {
    final length = readU64();
    return List<String>.generate(
        length, (_) => readFixedString(fixedLength, encoding: encoding));
  }
}
