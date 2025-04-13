import 'dart:typed_data';

import 'package:d_bincode/d_bincode.dart';
import 'package:test/test.dart';

void main() {
  group('Bincode Spec Tests', () {
    test('Class Encoding', classEncodingSpecTest);
    test('Struct Encoding', structEncodingSpecTest);
    test('Option Encoding', optionEncodingSpecTest);
    test('Collection Encoding', collectionEncodingSpecTest);
    test('UTF-8 String Encoding', utf8StringSpecTest);
    test('Fixed Array Encoding', arrayEncodingSpecTest);
    test('Enum Variant Encoding', enumEncodingSpecTest);
    test('Empty String Encoding', emptyStringEncodingTest);
    test('Empty Vec Encoding', emptyVecEncodingTest);
    test('Optional Zero Value Encoding', optionalZeroTest);
    test('OptionF32Triple null', optionF32TripleNullTest);
    test('Float Precision (f32)', floatPrecisionTest);
    test('Map Encoding', mapEncodingTest);
    test('Nested Struct Encoding', nestedStructTest);
    test('Shift-JIS Encoding Manual', shiftJisEncodingTest);
    test('Fixed-Length String Overflow', fixedStringOverflowTest);
    test('Option FixedString Encoding', optionFixedStringTest);
    test('Large Vec<u8> Stress Test', largeVectorStressTest);
    test('Boolean Encoding', booleanEncodingTest);
    test('Optional Bool Encoding', optionalBoolTest);
    test('Optional U8/U16/U64 Encoding', optionalUnsignedIntegersTest);
    test('Optional F64 Encoding', optionalF64Test);
    test('Optional String Encoding', optionalStringTest);
    test('Cursor Positioning (Writer)', cursorPositioningWriterTest);
    test('Cursor Positioning (Reader)', cursorPositioningReaderTest);
    test('Writer seek(offset) behavior', cursorSeekWriterTest);
    test('Reader seek(offset) behavior', cursorSeekReaderTest);
    test('Read/Write Int & Uint Lists', intAndUintListTests);
    test('Read/Write Float32List & Float64List', floatListTests);
  });
}


/// --- Class Encoding Example ---
/// Simulates the equivalent of this Rust struct:
/// ```rust
/// struct ExampleData {
///     id: u32,
///     value: f32,
///     label: [u8; 8]  // fixed-size string padded to 8 bytes
/// }
/// ```
class ExampleData extends BincodeEncodable {
  final int id;
  final double value;
  final String label; // Will be padded to 8 bytes

  ExampleData(this.id, this.value, this.label);

  @override
  void writeBincode(BincodeBuilder writer) {
    writer.writeU32(id); // 4 bytes
    writer.writeF32(value); // 4 bytes
    writer.writeFixedString(label, 8);
  }

  factory ExampleData.fromBincode(Uint8List bytes) {
    final reader = BincodeReader(bytes);
    final id = reader.readU32();
    final value = reader.readF32();
    final label = reader.readFixedString(8).replaceAll('\x00', '');
    return ExampleData(id, value, label);
  }

  @override
  String toString() => 'ExampleData(id: $id, value: $value, label: "$label")';
}

/// Test that the encoding and decoding of ExampleData conforms to the bincode format.
void classEncodingSpecTest() {
  final data = ExampleData(123, 1.5, 'Test');

  final encoded = data.toBincode();

  // Rust bincode reference output:
  // u32: 123 -> [123, 0, 0, 0]
  // f32: 1.5f32 -> [0, 0, 192, 63]
  // fixed string "Test" padded to 8 bytes -> [84, 101, 115, 116, 0, 0, 0, 0]
  final expected = Uint8List.fromList(
      [123, 0, 0, 0, 0, 0, 192, 63, 84, 101, 115, 116, 0, 0, 0, 0]);

  print("ExampleData encoding: $encoded");
  assert(encoded.join(',') == expected.join(','),
      "Class encoding failed. Expected: ${expected.join(',')}, got: ${encoded.join(',')}");

  final decoded = ExampleData.fromBincode(encoded);
  print("Decoded: $decoded");

  assert(decoded.id == 123,
      "Decoded id mismatch. Expected 123, got ${decoded.id}");
  assert(decoded.value.toStringAsFixed(2) == '1.50',
      "Decoded value mismatch. Expected 1.50, got ${decoded.value}");
  assert(decoded.label == 'Test',
      "Decoded label mismatch. Expected 'Test', got '${decoded.label}'");
}

/// --- 1. Verify Fixint Struct Compatibility (u32 + i32, 8 bytes total) ---
void structEncodingSpecTest() {
  final writer = BincodeWriter();
  writer.writeU32(0); // u32::MIN
  writer.writeI32(2147483647); // i32::MAX

  final encoded = writer.toBytes();

  final expected = Uint8List.fromList([0, 0, 0, 0, 255, 255, 255, 127]);

  print("Struct Encoding: $encoded");
  assert(encoded.join(',') == expected.join(','),
      "Struct encoding failed. Expected: ${expected.join(',')}, got: ${encoded.join(',')}");
}

/// --- 2. Option Encoding (Some/None with 1-byte tag + value) ---
void optionEncodingSpecTest() {
  final someWriter = BincodeWriter();
  someWriter.writeOptionU32(123);

  final noneWriter = BincodeWriter();
  noneWriter.writeOptionU32(null);

  final someExpected = Uint8List.fromList([1, 123, 0, 0, 0]);
  final noneExpected = Uint8List.fromList([0]);

  print("Option::Some(123): ${someWriter.toBytes()}");
  print("Option::None: ${noneWriter.toBytes()}");

  assert(someWriter.toBytes().join(',') == someExpected.join(','),
      "Option Some encoding failed. Expected: ${someExpected.join(',')}, got: ${someWriter.toBytes().join(',')}");
  assert(noneWriter.toBytes().join(',') == noneExpected.join(','),
      "Option None encoding failed. Expected: ${noneExpected.join(',')}, got: ${noneWriter.toBytes().join(',')}");
}

/// --- 3. Collection Encoding (Vec<T> with u64 length prefix) ---
void collectionEncodingSpecTest() {
  // === Part 1: test Vec<u8> encoding ===
  final writer1 = BincodeWriter();
  final list = [0, 1, 2];

  writer1.writeU64(list.length);
  for (final v in list) {
    writer1.writeU8(v);
  }

  final encoded = writer1.toBytes();
  final expected = Uint8List.fromList([3, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2]);

  print("Vec<u8>: $encoded");
  assert(encoded.join(',') == expected.join(','),
      "Collection encoding failed. Expected: ${expected.join(',')}, got: ${encoded.join(',')}");

  // === Part 2: test Option<F32Triple> with Float32List ===
  final writer2 = BincodeWriter();
  final vec = Float32List.fromList([1.0, 2.0, 3.0]);
  writer2.writeOptionF32Triple(vec);

  final bytes = writer2.toBytes();
  final reader = BincodeReader(bytes);
  final result = reader.readOptionF32Triple();

  print("Option<F32Triple>: $result");
  assert(result != null && result.length == 3 && result[0] == 1.0,
      "Expected [1.0, 2.0, 3.0], got: $result");
}

/// --- 4. String UTF-8 Encoding (length-prefixed, per bincode) ---
/// Uses the writeString() API that encodes a string as UTF-8 and prefixes with its u64 length.
void utf8StringSpecTest() {
  final text = "Hello 🌍";

  final writer = BincodeWriter();
  writer.writeString(text); // Uses API for length-prefixed UTF-8 string

  final result = writer.toBytes();
  print("UTF-8 String Encoding (Hello 🌍): $result");

  final expected = [
    10, 0, 0, 0, 0, 0, 0, 0, // u64 length prefix: 10 bytes
    72, 101, 108, 108, 111, 32, // "Hello "
    240, 159, 140, 141 // UTF-8 for "🌍"
  ];

  assert(result.length == expected.length,
      "UTF-8 string encoding length mismatch. Expected length ${expected.length}, got ${result.length}");
  assert(result.join(',') == expected.join(','),
      "UTF-8 string encoding failed. Expected: ${expected.join(',')}, got: ${result.join(',')}");
}

/// --- 5. Fixed-Length Array Encoding ---
void arrayEncodingSpecTest() {
  final arr = [10, 20, 30, 40, 50];
  final writer = BincodeWriter();
  for (final byte in arr) {
    writer.writeU8(byte);
  }

  final encoded = writer.toBytes();
  final expected = Uint8List.fromList(arr);

  print("Fixed Array: $encoded");
  assert(encoded.join(',') == expected.join(','),
      "Fixed array encoding failed. Expected: ${expected.join(',')}, got: ${encoded.join(',')}");
}

/// --- 6. Enum Variant Encoding (manual simulation) ---
/// Simulates: enum MyEnum { A, B(u32), C { value: u32 } }
void enumEncodingSpecTest() {
  final a = BincodeWriter();
  a.writeU32(0); // Variant A: index 0

  final b = BincodeWriter();
  b.writeU32(1); // Variant B: index 1
  b.writeU32(0); // Payload for B

  final c = BincodeWriter();
  c.writeU32(2); // Variant C: index 2
  c.writeU32(0); // Payload for C

  print("Enum::A: ${a.toBytes()}");
  print("Enum::B(0): ${b.toBytes()}");
  print("Enum::C { value: 0 }: ${c.toBytes()}");

  assert(a.toBytes().join(',') == [0, 0, 0, 0].join(','),
      "Enum A encoding failed. Expected: [0, 0, 0, 0], got: ${a.toBytes().join(',')}");
  assert(b.toBytes().join(',') == [1, 0, 0, 0, 0, 0, 0, 0].join(','),
      "Enum B encoding failed. Expected: [1, 0, 0, 0, 0, 0, 0, 0], got: ${b.toBytes().join(',')}");
  assert(c.toBytes().join(',') == [2, 0, 0, 0, 0, 0, 0, 0].join(','),
      "Enum C encoding failed. Expected: [2, 0, 0, 0, 0, 0, 0, 0], got: ${c.toBytes().join(',')}");
}

/// --- 7. Empty String Encoding ---
/// Tests an empty UTF-8 string with correct u64 length prefix.
void emptyStringEncodingTest() {
  final writer = BincodeWriter();
  writer.writeString(""); // Should write length 0 (u64)

  final result = writer.toBytes();
  final expected = Uint8List.fromList(List.filled(8, 0)); // u64: 0

  print("Empty String Encoding: $result");
  expect(result, equals(expected));
}

/// --- 8. Empty List Encoding ---
/// Tests Vec<u8> where the list is empty.
void emptyVecEncodingTest() {
  final writer = BincodeWriter();
  writer.writeU64(0); // length 0
  final result = writer.toBytes();
  final expected = Uint8List.fromList(List.filled(8, 0)); // u64: 0

  print("Empty Vec Encoding: $result");
  expect(result, equals(expected));
}

/// --- 9. Optional Zero Value ---
/// Tests encoding of 0 as an option.
void optionalZeroTest() {
  final writer = BincodeWriter();
  writer.writeOptionU32(0); // flag = 1, value = 0
  final expected = Uint8List.fromList([1, 0, 0, 0, 0]);

  final bytes = writer.toBytes();
  print("Option<U32=0>: $bytes");
  expect(bytes, equals(expected));
}

/// --- 10. Optional None F32Triple ---
/// Tests null vector writing (0 flag, followed by 12 zeroed bytes)
void optionF32TripleNullTest() {
  final writer = BincodeWriter();
  writer.writeOptionF32Triple(null);

  final bytes = writer.toBytes();
  final expected = Uint8List.fromList([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);

  print("OptionF32Triple (null): $bytes");
  expect(bytes, equals(expected));

  final reader = BincodeReader(bytes);
  final result = reader.readOptionF32Triple();
  expect(result, isNull);
}

/// --- 11. Float Precision Test ---
/// Tests if f32 maintains proper precision with 1.0 / 3.0
void floatPrecisionTest() {
  final value = 1.0 / 3.0;

  final writer = BincodeWriter();
  writer.writeF32(value);
  final bytes = writer.toBytes();

  final reader = BincodeReader(bytes);
  final readValue = reader.readF32();

  print("Float Precision - written: $value, read: $readValue");
  expect((readValue - value).abs() < 1e-6, isTrue,
      reason: 'Float32 precision too low');
}

/// --- 12. Map Encoding (Map<u8, u32>) ---
void mapEncodingTest() {
  final writer = BincodeWriter();
  final map = {1: 100, 2: 200};

  writer.writeU64(map.length);
  map.forEach((key, value) {
    writer.writeU8(key);
    writer.writeU32(value);
  });

  final bytes = writer.toBytes();
  final reader = BincodeReader(bytes);
  final result = reader.readMap<int, int>(reader.readU8, reader.readU32);

  print("Map read: $result");
  expect(result.length, equals(2));
  expect(result[1], equals(100));
  expect(result[2], equals(200));
}

/// --- 13. Nested Struct Encoding ---
class InnerData extends BincodeEncodable {
  final int code;
  InnerData(this.code);

  @override
  void writeBincode(BincodeBuilder writer) => writer.writeU32(code);
  factory InnerData.fromReader(BincodeReader reader) =>
      InnerData(reader.readU32());
}

class OuterData extends BincodeEncodable {
  final InnerData inner;
  final double value;

  OuterData(this.inner, this.value);

  @override
  void writeBincode(BincodeBuilder writer) {
    inner.writeBincode(writer);
    writer.writeF32(value);
  }

  factory OuterData.fromBincode(Uint8List bytes) {
    final reader = BincodeReader(bytes);
    final inner = InnerData.fromReader(reader);
    final value = reader.readF32();
    return OuterData(inner, value);
  }
}

void nestedStructTest() {
  final outer = OuterData(InnerData(777), 3.14);
  final encoded = outer.toBincode();
  final decoded = OuterData.fromBincode(encoded);

  print("Nested struct: ${decoded.inner.code}, ${decoded.value}");
  expect(decoded.inner.code, equals(777));
  expect((decoded.value - 3.14).abs() < 1e-6, isTrue);
}

void shiftJisEncodingTest() {
  final text = "こんにちは";

  final writer = BincodeWriter();
  writer.writeString(text, StringEncoding.shiftJis);

  final bytes = writer.toBytes();
  final reader = BincodeReader(bytes);

  final decoded = reader.readString(StringEncoding.shiftJis);
  print("Shift-JIS Decoded: $decoded");

  expect(decoded, equals(text));
}

/// --- 15. Fixed-length String Overflow (should truncate + padding) ---
void fixedStringOverflowTest() {
  final writer = BincodeWriter();
  writer.writeFixedString("TOOLONG", 4); // Truncates to 4 bytes: "TOOL"
  final result = writer.toBytes();
  final expected = [84, 79, 79, 76]; // T O O L

  print("Fixed string overflow: $result");
  expect(result.sublist(0, 4), equals(expected));

  final reader = BincodeReader(result);
  final raw = reader.readFixedString(4); // still returns "TOOL"
  expect(raw, equals("TOOL")); // ✅ already truncated, so no nulls to trim
}

/// --- 16. Option Fixed-Length String (with and without cleaning) ---
void optionFixedStringTest() {
  final writer = BincodeWriter();
  writer.writeOptionFixedString("Hello", 8); // Padded with \x00 to length 8
  final bytes = writer.toBytes();

  // --- Variant 1: Manual trimming ---
  final reader1 = BincodeReader(bytes);
  final raw = reader1.readOptionFixedString(8);
  final trimmed = raw?.replaceAll('\x00', '');

  print("Manual cleaned: $trimmed");
  expect(trimmed, equals("Hello"));

  // --- Variant 2: Using readCleanOptionFixedString() ---
  final reader2 = BincodeReader(bytes);
  final cleaned = reader2.readCleanOptionFixedString(8);

  print("Auto cleaned: $cleaned");
  expect(cleaned, equals("Hello"));
}

/// --- 17. Large Vec Stress Test (1k entries) ---
void largeVectorStressTest() {
  final values = List<int>.generate(1000, (i) => i % 256);
  final writer = BincodeWriter();
  writer.writeU64(values.length);
  for (final v in values) writer.writeU8(v);

  final bytes = writer.toBytes();
  final reader = BincodeReader(bytes);
  final readValues = reader.readList(() => reader.readU8());

  expect(readValues.length, equals(1000));
  expect(readValues[0], equals(0));
  expect(readValues[999], equals(231));
}

/// --- 18. Boolean Encoding Test ---
void booleanEncodingTest() {
  final writer = BincodeWriter();
  writer.writeBool(true);
  writer.writeBool(false);
  final bytes = writer.toBytes();
  print("Boolean Encoding: $bytes");
  final reader = BincodeReader(bytes);
  final b1 = reader.readBool();
  final b2 = reader.readBool();
  expect(b1, isTrue);
  expect(b2, isFalse);
}

/// --- 19. Optional Boolean Encoding ---
void optionalBoolTest() {
  final writer = BincodeWriter();
  writer.writeOptionBool(true);
  writer.writeOptionBool(null);
  writer.writeOptionBool(false);

  final bytes = writer.toBytes();
  print("Option<bool>: $bytes");

  final reader = BincodeReader(bytes);
  final b1 = reader.readOptionBool();
  final b2 = reader.readOptionBool();
  final b3 = reader.readOptionBool();

  expect(b1, isTrue);
  expect(b2, isNull);
  expect(b3, isFalse);
}

/// --- 20. Optional U8/U16/U64 Encoding ---
void optionalUnsignedIntegersTest() {
  final writer = BincodeWriter();
  writer.writeOptionU8(42);
  writer.writeOptionU8(null);
  writer.writeOptionU16(65535);
  writer.writeOptionU16(null);
  writer.writeOptionU64(9999999999);
  writer.writeOptionU64(null);

  final bytes = writer.toBytes();
  print("Option<u8/u16/u64>: $bytes");

  final reader = BincodeReader(bytes);
  expect(reader.readOptionU8(), equals(42));
  expect(reader.readOptionU8(), isNull);
  expect(reader.readOptionU16(), equals(65535));
  expect(reader.readOptionU16(), isNull);
  expect(reader.readOptionU64(), equals(9999999999));
  expect(reader.readOptionU64(), isNull);
}

/// --- 21. Optional f64 Encoding ---
void optionalF64Test() {
  final writer = BincodeWriter();
  writer.writeOptionF64(3.14159);
  writer.writeOptionF64(null);

  final bytes = writer.toBytes();
  print("Option<f64>: $bytes");

  final reader = BincodeReader(bytes);
  final d1 = reader.readOptionF64();
  final d2 = reader.readOptionF64();

  expect((d1! - 3.14159).abs() < 1e-12, isTrue);
  expect(d2, isNull);
}

/// --- 22. Optional String Encoding (UTF-8) ---
void optionalStringTest() {
  final writer = BincodeWriter();
  writer.writeOptionString("optional");
  writer.writeOptionString(null);

  final bytes = writer.toBytes();
  print("Option<String>: $bytes");

  final reader = BincodeReader(bytes);
  expect(reader.readOptionString(), equals("optional"));
  expect(reader.readOptionString(), isNull);
}

void cursorPositioningWriterTest() {
  final writer = BincodeWriter();
  writer.writeU8(1);
  writer.writeU8(2);
  writer.writeU8(3);
  print("Writer position after writes: ${writer.position}");
  expect(writer.position, equals(3), reason: "Writer should be at position 3");

  writer.rewind();
  print("Writer position after rewind(): ${writer.position}");
  expect(writer.position, equals(0), reason: "Writer rewind() should reset to 0");

  writer.seekTo(2);
  print("Writer position after seekTo(2): ${writer.position}");
  expect(writer.position, equals(2), reason: "Writer seekTo(2) should move to 2");

  writer.skipToEnd();
  print("Writer position after skipToEnd(): ${writer.position}");
  expect(writer.position, equals(3), reason: "Writer skipToEnd() should restore to end");
}

void cursorPositioningReaderTest() {
  final writer = BincodeWriter();
  writer.writeU8(42); // pos 0
  writer.writeU8(84); // pos 1
  writer.writeU8(126); // pos 2
  final bytes = writer.toBytes();

  final reader = BincodeReader(bytes);
  print("Reader position initially: ${reader.position}");
  expect(reader.position, equals(0), reason: "Reader starts at 0");

  final first = reader.readU8();
  print("Read first byte: $first");
  print("Reader position after reading one byte: ${reader.position}");
  expect(first, equals(42));
  expect(reader.position, equals(1));

  reader.seekTo(2);
  print("Reader position after seekTo(2): ${reader.position}");
  expect(reader.position, equals(2));

  final third = reader.readU8();
  print("Read third byte: $third");
  expect(third, equals(126));

  reader.rewind();
  print("Reader position after rewind(): ${reader.position}");
  expect(reader.position, equals(0));

  reader.skipToEnd();
  print("Reader position after skipToEnd(): ${reader.position}");
  expect(reader.position, equals(3)); // 3 bytes total
}

void cursorSeekWriterTest() {
  final writer = BincodeWriter();
  writer.writeU8(10); // pos 0
  writer.writeU8(20); // pos 1
  writer.writeU8(30); // pos 2

  print("Writer position after initial writes: ${writer.position}");

  writer.seek(-1); // move back one byte
  print("Writer position after seek(-1): ${writer.position}");
  expect(writer.position, equals(2), reason: "Writer should be at position 2 after seek(-1)");

  writer.writeU8(99); // overwrite last byte
  final result = writer.toBytes();
  print("Bytes after overwriting at pos 2: $result");
  expect(result[2], equals(99), reason: "Byte at position 2 should be overwritten to 99");

  writer.seek(-2); // move to position 1
  print("Writer position after seek(-2): ${writer.position}");
  expect(writer.position, equals(1), reason: "Writer at pos 1 after seek(-2)");
}


void cursorSeekReaderTest() {
  final writer = BincodeWriter();
  writer.writeU8(100); // pos 0
  writer.writeU8(101); // pos 1
  writer.writeU8(102); // pos 2
  final bytes = writer.toBytes();
  print("Bytes written for reader: $bytes");

  final reader = BincodeReader(bytes);
  print("Initial reader position: ${reader.position}");

  reader.seek(2); // move to position 2
  print("Reader position after seek(2): ${reader.position}");
  expect(reader.position, equals(2), reason: "Reader at pos 2 after seek(2)");

  reader.seek(-1); // back to 1
  print("Reader position after seek(-1): ${reader.position}");
  expect(reader.position, equals(1), reason: "Reader at pos 1 after seek(-1)");

  final value = reader.readU8();
  print("Reader read value at pos 1: $value");
  expect(value, equals(101), reason: "Reader should read 101 at pos 1");
}

void intAndUintListTests() {
  final int8List = [-1, 0, 1, 127, -128];
  final int16List = [-32768, 0, 32767];
  final int32List = [-2147483648, 0, 2147483647];
  final int64List = [9223372036854775807, -9223372036854775808];

  final uint8List = [0, 1, 255];
  final uint16List = [0, 65535];
  final uint32List = [0, 4294967295];
  final uint64List = [1, 999999999999];

  final writer = BincodeWriter();

  writer.writeInt8List(int8List);
  writer.writeInt16List(int16List);
  writer.writeInt32List(int32List);
  writer.writeInt64List(int64List);
  writer.writeUint8List(uint8List);
  writer.writeUint16List(uint16List);
  writer.writeUint32List(uint32List);
  writer.writeUint64List(uint64List);

  final bytes = writer.toBytes();
  final reader = BincodeReader(bytes);

  expect(reader.readInt8List(int8List.length), equals(int8List));
  expect(reader.readInt16List(int16List.length), equals(int16List));
  expect(reader.readInt32List(int32List.length), equals(int32List));
  expect(reader.readInt64List(int64List.length), equals(int64List));
  expect(reader.readUint8List(uint8List.length), equals(uint8List));
  expect(reader.readUint16List(uint16List.length), equals(uint16List));
  expect(reader.readUint32List(uint32List.length), equals(uint32List));
  expect(reader.readUint64List(uint64List.length), equals(uint64List));
}

void floatListTests() {
  final f32List = [1.1, -2.2, 3.3];
  final f64List = [3.14159, -123456.789, 0.000001];

  final writer = BincodeWriter();
  writer.writeFloat32List(f32List);
  writer.writeFloat64List(f64List);

  final bytes = writer.toBytes();
  final reader = BincodeReader(bytes);

  final decodedF32 = reader.readFloat32List(f32List.length);
  final decodedF64 = reader.readFloat64List(f64List.length);

  for (int i = 0; i < f32List.length; i++) {
    expect((decodedF32[i] - f32List[i]).abs() < 1e-5, isTrue,
        reason: 'F32 mismatch at index $i');
  }

  for (int i = 0; i < f64List.length; i++) {
    expect((decodedF64[i] - f64List[i]).abs() < 1e-10, isTrue,
        reason: 'F64 mismatch at index $i');
  }
}