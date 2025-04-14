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
    test('write then read everything', completeReadWriteIntegrationTest);
    test('Nested Encoding (writeNested/readNested)',
        nestedEncodingWithNewMethodsTest);
    test('Optional Nested Encoding (writeOptionNested/readOptionNested)',
        optionalNestedNoneTest);
    test('Login Protocol Roundtrip (real-world use)',
        loginProtocolRoundtripTest);
    test(
        'IPC Protocol Roundtrip (realistic message passing)', ipcRoundtripTest);
    test('IPC Entity Snapshot roundtrip (client-server simulation)',
        entitySnapshotIpcTest);
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
class ExampleData implements BincodeEncodable, BincodeDecodable {
  int id;
  double value;
  String label;

  ExampleData(this.id, this.value, this.label);

  ExampleData.empty()
      : id = 0,
        value = 0.0,
        label = '';

  @override
  Uint8List toBincode() {
    final writer = BincodeWriter();
    writer.writeU32(id);
    writer.writeF32(value);
    writer.writeFixedString(label, 8);
    return writer.toBytes();
  }

  @override
  void loadFromBytes(Uint8List bytes) {
    final reader = BincodeReader(bytes);
    id = reader.readU32();
    value = reader.readF32();
    label = reader.readFixedString(8).replaceAll('\x00', '');
  }

  @override
  String toString() => 'ExampleData(id: $id, value: $value, label: "$label")';
}

/// Test that the encoding and decoding of ExampleData conforms to the bincode format.
void classEncodingSpecTest() {
  final data = ExampleData(123, 1.5, 'Test');

  final encoded = data.toBincode();

  // Expected encoding:
  // u32: 123 -> [123, 0, 0, 0]
  // f32: 1.5 -> [0, 0, 192, 63]
  // fixed string "Test" padded to 8 bytes -> [84, 101, 115, 116, 0, 0, 0, 0]
  final expected = Uint8List.fromList(
    [123, 0, 0, 0, 0, 0, 192, 63, 84, 101, 115, 116, 0, 0, 0, 0],
  );

  print("ExampleData encoding: $encoded");

  expect(encoded, equals(expected),
      reason: "Encoded bytes don't match expected format");

  // Decode using the empty constructor + instance method
  final decoded = ExampleData.empty();
  decoded.loadFromBytes(encoded);

  print("Decoded: $decoded");

  expect(decoded.id, equals(123), reason: "ID mismatch");
  expect(decoded.value.toStringAsFixed(2), equals('1.50'),
      reason: "Float mismatch");
  expect(decoded.label, equals('Test'), reason: "Label mismatch");
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

/// --- 13. Nested Struct Encoding ---

class InnerData implements BincodeEncodable, BincodeDecodable {
  int code;

  InnerData(this.code);

  @override
  Uint8List toBincode() {
    final writer = BincodeWriter();
    _writeTo(writer);
    return writer.toBytes();
  }

  @override
  void loadFromBytes(Uint8List bytes) {
    final reader = BincodeReader(bytes);
    _readFrom(reader);
  }

  void _writeTo(BincodeWriter writer) {
    writer.writeU32(code);
  }

  void _readFrom(BincodeReader reader) {
    code = reader.readU32();
  }
}

class OuterData implements BincodeEncodable, BincodeDecodable {
  InnerData inner;
  double value;

  OuterData(this.inner, this.value);

  @override
  Uint8List toBincode() {
    final writer = BincodeWriter();
    inner._writeTo(writer);
    writer.writeF32(value);
    return writer.toBytes();
  }

  @override
  void loadFromBytes(Uint8List bytes) {
    final reader = BincodeReader(bytes);
    inner = InnerData(0);
    inner._readFrom(reader);
    value = reader.readF32();
  }
}

void nestedStructTest() {
  final outer = OuterData(InnerData(777), 3.14);
  final encoded = outer.toBincode();

  final decoded = OuterData(InnerData(0), 0.0)..loadFromBytes(encoded);

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
  for (final v in values) {
    writer.writeU8(v);
  }

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
  expect(writer.position, equals(0),
      reason: "Writer rewind() should reset to 0");

  writer.seekTo(2);
  print("Writer position after seekTo(2): ${writer.position}");
  expect(writer.position, equals(2),
      reason: "Writer seekTo(2) should move to 2");

  writer.skipToEnd();
  print("Writer position after skipToEnd(): ${writer.position}");
  expect(writer.position, equals(3),
      reason: "Writer skipToEnd() should restore to end");
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
  expect(writer.position, equals(2),
      reason: "Writer should be at position 2 after seek(-1)");

  writer.writeU8(99); // overwrite last byte
  final result = writer.toBytes();
  print("Bytes after overwriting at pos 2: $result");
  expect(result[2], equals(99),
      reason: "Byte at position 2 should be overwritten to 99");

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

void completeReadWriteIntegrationTest() {
  final writer = BincodeWriter();

  // --- Write Primitive Values ---
  writer.writeU8(255); // max u8
  writer.writeU16(65535); // max u16
  writer.writeU32(4294967295); // max u32
  writer.writeU64(1234567890123456789);
  writer.writeI8(-128);
  writer.writeI16(-32768);
  writer.writeI32(-2147483648);
  writer.writeI64(-9223372036854775808);
  writer.writeF32(3.14159);
  writer.writeF64(-2.718281828459045);
  writer.writeBool(true);
  writer.writeBool(false);

  // --- Write Strings ---
  writer.writeString("Hello, world!"); // length-prefixed UTF-8 string
  writer.writeFixedString("Dart", 10); // fixed-length; "Dart" padded with zeros
  writer.writeFixedString("Dart", 10); // fixed-length; "Dart" padded with zeros

  // --- Write Optionals ---
  writer.writeOptionU8(100); // Option: Some(100)
  writer.writeOptionU8(null); // Option: None
  writer.writeOptionF64(6.28318); // Option: Some(6.28318)
  writer.writeOptionF64(null); // Option: None

  // Option F32 Triple (Some)
  writer.writeOptionF32Triple(Float32List.fromList([1.0, 2.0, 3.0]));
  // Option F32 Triple (None)
  writer.writeOptionF32Triple(null);

  // --- Write Collections ---
  // Write a List<int> (using u8 for each element)
  writer.writeList<int>([1, 2, 3, 4, 5], (int v) => writer.writeU8(v));
  // Write a Map<int, String> (key: u8 and value: string)
  writer.writeMap<int, String>(
      {1: "one", 2: "two"},
      (int key) => writer.writeU8(key),
      (String value) => writer.writeString(value));

  // --- Write Numeric Lists ---
  writer.writeInt16List([-1, -2, -3]);
  writer.writeFloat32List([0.1, 0.2, 0.3]);

  final bytes = writer.toBytes();

  final reader = BincodeReader(bytes);

  // Verify primitives.
  expect(reader.readU8(), equals(255));
  expect(reader.readU16(), equals(65535));
  expect(reader.readU32(), equals(4294967295));
  expect(reader.readU64(), equals(1234567890123456789));
  expect(reader.readI8(), equals(-128));
  expect(reader.readI16(), equals(-32768));
  expect(reader.readI32(), equals(-2147483648));
  expect(reader.readI64(), equals(-9223372036854775808));
  expect(reader.readF32(), closeTo(3.14159, 1e-5));
  expect(reader.readF64(), closeTo(-2.718281828459045, 1e-12));
  expect(reader.readBool(), isTrue);
  expect(reader.readBool(), isFalse);

  // Verify strings.
  expect(reader.readString(), equals("Hello, world!"));

  expect(reader.readFixedString(10), equals("Dart${"\x00" * 6}"));
  expect(reader.readCleanFixedString(10), equals("Dart"));

  // Verify optionals.
  expect(reader.readOptionU8(), equals(100));
  expect(reader.readOptionU8(), isNull);
  expect(reader.readOptionF64(), closeTo(6.28318, 1e-12));
  expect(reader.readOptionF64(), isNull);

  // Verify Option F32 Triple.
  final triple = reader.readOptionF32Triple();
  expect(triple, isNotNull);
  expect(triple!.toList(), equals([1.0, 2.0, 3.0]));
  expect(reader.readOptionF32Triple(), isNull);

  // Verify collections.
  final listRead = reader.readList(() => reader.readU8());
  expect(listRead, equals([1, 2, 3, 4, 5]));

  final mapRead =
      reader.readMap(() => reader.readU8(), () => reader.readString());
  expect(mapRead, equals({1: "one", 2: "two"}));

  // Verify numeric lists.
  expect(reader.readInt16List(3), equals([-1, -2, -3]));
  final floatList = reader.readFloat32List(3);
  for (int i = 0; i < floatList.length; i++) {
    expect(floatList[i], closeTo([0.1, 0.2, 0.3][i], 1e-5));
  }

  // verify that the complete byte buffer length matches the writer output.
  expect(bytes.length, greaterThan(0));
}

class NestedValue implements BincodeEncodable, BincodeDecodable {
  int number;

  NestedValue(this.number);

  @override
  Uint8List toBincode() {
    final writer = BincodeWriter();
    writer.writeU32(number);
    return writer.toBytes();
  }

  @override
  void loadFromBytes(Uint8List bytes) {
    final reader = BincodeReader(bytes);
    number = reader.readU32();
  }
}

class ComplexHolder implements BincodeEncodable, BincodeDecodable {
  NestedValue value;
  NestedValue? optional;

  ComplexHolder(this.value, this.optional);

  ComplexHolder.empty()
      : value = NestedValue(0),
        optional = null;

  @override
  Uint8List toBincode() {
    final writer = BincodeWriter();
    writer.writeNested(value);
    writer.writeOptionNested(optional);
    return writer.toBytes();
  }

  @override
  void loadFromBytes(Uint8List bytes) {
    final reader = BincodeReader(bytes);
    value = reader.readNestedObject(NestedValue(0));
    optional = reader.readOptionNestedObject(() => NestedValue(0));
  }
}

void nestedEncodingWithNewMethodsTest() {
  final instance = ComplexHolder(NestedValue(42), NestedValue(99));
  final encoded = instance.toBincode();

  print("Encoded ComplexHolder bytes: $encoded");

  final decoded = ComplexHolder(NestedValue(0), null)..loadFromBytes(encoded);

  expect(decoded.value.number, equals(42));
  expect(decoded.optional, isNotNull);
  expect(decoded.optional!.number, equals(99));
}

void optionalNestedNoneTest() {
  final instance = ComplexHolder(NestedValue(1234), null);
  final encoded = instance.toBincode();

  final decoded = ComplexHolder(NestedValue(0), null)..loadFromBytes(encoded);

  expect(decoded.value.number, equals(1234));
  expect(decoded.optional, isNull);
}

class LoginRequest implements BincodeEncodable {
  String username;
  String password;

  LoginRequest(this.username, this.password);

  @override
  Uint8List toBincode() {
    final writer = BincodeWriter();
    writer.writeString(username);
    writer.writeString(password);
    return writer.toBytes();
  }
}

class LoginResponse implements BincodeDecodable {
  bool success;
  String? token;

  LoginResponse(this.success, this.token);

  LoginResponse.empty()
      : success = false,
        token = null;

  @override
  void loadFromBytes(Uint8List bytes) {
    final reader = BincodeReader(bytes);
    success = reader.readBool();
    token = reader.readOptionString();
  }

  @override
  String toString() => 'LoginResponse(success: $success, token: $token)';
}

void loginProtocolRoundtripTest() {
  // CLIENT: Encode request to send to server
  final request = LoginRequest("admin", "s3cr3t");
  final sentBytes = request.toBincode();

  // SERVER: Decode request on Rust-side (simulated in Dart here)
  final reader = BincodeReader(sentBytes);
  final receivedUsername = reader.readString();
  final receivedPassword = reader.readString();

  expect(receivedUsername, equals("admin"));
  expect(receivedPassword, equals("s3cr3t"));

  // SERVER: Create a LoginResponse
  final responseWriter = BincodeWriter();
  responseWriter.writeBool(true);
  responseWriter.writeOptionString("auth-token-123");
  final responseBytes = responseWriter.toBytes();

  // CLIENT: Decode response
  final response = LoginResponse.empty();
  response.loadFromBytes(responseBytes);

  print("Decoded LoginResponse: $response");

  expect(response.success, isTrue);
  expect(response.token, equals("auth-token-123"));
}

class IpcCommand implements BincodeEncodable, BincodeDecodable {
  String command;
  Map<String, String> args;

  IpcCommand(this.command, this.args);

  IpcCommand.empty()
      : command = "",
        args = {};

  @override
  Uint8List toBincode() {
    final writer = BincodeWriter();
    _writeTo(writer);
    return writer.toBytes();
  }

  @override
  void loadFromBytes(Uint8List bytes) {
    final reader = BincodeReader(bytes);
    _readFrom(reader);
  }

  void _writeTo(BincodeWriter writer) {
    writer.writeString(command);
    writer.writeU64(args.length);
    args.forEach((key, value) {
      writer.writeString(key);
      writer.writeString(value);
    });
  }

  void _readFrom(BincodeReader reader) {
    command = reader.readString();
    final count = reader.readU64();
    args = {};
    for (int i = 0; i < count; i++) {
      final key = reader.readString();
      final val = reader.readString();
      args[key] = val;
    }
  }
}

class IpcResponse implements BincodeEncodable, BincodeDecodable {
  bool success;
  String message;

  IpcResponse(this.success, this.message);

  IpcResponse.empty()
      : success = false,
        message = "";

  @override
  Uint8List toBincode() {
    final writer = BincodeWriter();
    writer.writeBool(success);
    writer.writeString(message);
    return writer.toBytes();
  }

  @override
  void loadFromBytes(Uint8List bytes) {
    final reader = BincodeReader(bytes);
    success = reader.readBool();
    message = reader.readString();
  }

  @override
  String toString() => 'IpcResponse(success: $success, message: "$message")';
}

void ipcRoundtripTest() {
  final ipc = IpcCommand("OpenFile", {
    "path": "/tmp/data.txt",
    "mode": "read",
  });

  final encoded = ipc.toBincode();

  // SERVER SIDE: simulate handling the command
  final reader = BincodeReader(encoded);
  final cmd = reader.readString();
  final argCount = reader.readU64();

  final args = <String, String>{};
  for (int i = 0; i < argCount; i++) {
    final k = reader.readString();
    final v = reader.readString();
    args[k] = v;
  }

  expect(cmd, equals("OpenFile"));
  expect(args["path"], equals("/tmp/data.txt"));
  expect(args["mode"], equals("read"));

  // SERVER RESPONDS
  final responseWriter = BincodeWriter();
  responseWriter.writeBool(true);
  responseWriter.writeString("File opened successfully");

  final responseBytes = responseWriter.toBytes();

  // CLIENT SIDE
  final response = IpcResponse.empty();
  response.loadFromBytes(responseBytes);

  print("IPC Response: $response");

  expect(response.success, isTrue);
  expect(response.message, contains("opened"));
}

class GameEntitySnapshot implements BincodeEncodable, BincodeDecodable {
  int id;
  double x;
  double y;
  double rotation;
  String type;

  GameEntitySnapshot(this.id, this.x, this.y, this.rotation, this.type);

  @override
  Uint8List toBincode() {
    final writer = BincodeWriter();
    _writeTo(writer);
    return writer.toBytes();
  }

  @override
  void loadFromBytes(Uint8List bytes) {
    final reader = BincodeReader(bytes);
    _readFrom(reader);
  }

  void _writeTo(BincodeWriter writer) {
    writer.writeU32(id);
    writer.writeF32(x);
    writer.writeF32(y);
    writer.writeF32(rotation);
    writer.writeString(type);
  }

  void _readFrom(BincodeReader reader) {
    id = reader.readU32();
    x = reader.readF32();
    y = reader.readF32();
    rotation = reader.readF32();
    type = reader.readString();
  }

  @override
  String toString() =>
      'Entity(id: $id, pos: ($x, $y), rot: $rotation, type: "$type")';
}

Uint8List processEntityOnServer(Uint8List requestBytes) {
  final entity = GameEntitySnapshot(0, 0.0, 0.0, 0.0, "");
  entity.loadFromBytes(requestBytes);

  final updated = GameEntitySnapshot(
    entity.id,
    entity.x.clamp(0.0, 100.0),
    entity.y.clamp(0.0, 100.0),
    (entity.rotation + 45.0) % 360.0,
    "ServerConfirmed-${entity.type}",
  );

  return updated.toBincode();
}

void entitySnapshotIpcTest() {
  final clientSnapshot = GameEntitySnapshot(1, 123.0, -20.0, 270.0, "Player");
  final requestBytes = clientSnapshot.toBincode();

  final responseBytes = processEntityOnServer(requestBytes);
  final updatedSnapshot = GameEntitySnapshot(0, 0.0, 0.0, 0.0, "");
  updatedSnapshot.loadFromBytes(responseBytes);

  print("Client sent: $clientSnapshot");
  print("Server replied: $updatedSnapshot");

  expect(updatedSnapshot.id, equals(1));
  expect(updatedSnapshot.x, equals(100.0));
  expect(updatedSnapshot.y, equals(0.0));
  expect(updatedSnapshot.rotation, equals(315.0));
  expect(updatedSnapshot.type, equals("ServerConfirmed-Player"));
}
