// Copyright (c) 2025 Binurie
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:d_bincode/d_bincode.dart';
import 'package:test/test.dart';

void main() {
  group('Bincode Spec Tests', () {
    test('Class Encoding', classEncodingSpecTest);
    test('Struct Encoding', structEncodingSpecTest);
    test('Option Encoding', optionEncodingSpecTest);
    test('UTF-8 String Encoding', utf8StringSpecTest);
    test('Fixed Array Encoding', arrayEncodingSpecTest);
    test('Enum Variant Encoding', enumEncodingSpecTest);
    test('Empty String Encoding', emptyStringEncodingTest);
    test('Empty Vec Encoding', emptyVecEncodingTest);
    test('Optional Zero Value Encoding', optionalZeroTest);
    test('Float Precision (f32)', floatPrecisionTest);
    test('Map Encoding', mapEncodingTest);
    test('Nested Struct Encoding', nestedStructTest);
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
    test('Crazy 4-Level Deep Nested Struct and List - Map Encoding',
        ultraInsaneCrazyTest);
    test('Deep Complex Test', deepComplexTest);

    group('BincodeWriter Utils', () {
      test('encodeToBytes produces same as manual encode + toBytes', () {
        final pair = SimplePair(0xAB, 0xCDEF);
        final w1 = BincodeWriter();
        w1.reset();
        pair.encode(w1);
        final manual = w1.toBytes();
        print('manual bytes: $manual');

        final auto = w1.encodeToBytes(pair);
        print('auto bytes:   $auto');

        expect(auto, equals(manual),
            reason: 'encodeToBytes should wrap reset+encode+toBytes');
      });

      test('measure returns the exact byte length of encode', () {
        final pair = SimplePair(1, 0x1234);
        final w = BincodeWriter(initialCapacity: 4);
        final measured = w.measure(pair);
        print('measured byte length: $measured');

        w.reset();
        pair.encode(w);
        final actual = w.getBytesWritten();
        print('actual byte length:   $actual');

        expect(measured, equals(actual),
            reason: 'measure() must match getBytesWritten() after encode');
      });

      test('static encode matches encodeToBytes', () {
        final pair = SimplePair(5, 10);
        final fromStatic = BincodeWriter.encode(pair, initialCapacity: 2);
        print('static.encode bytes:   $fromStatic');

        final fromInstance =
            BincodeWriter(initialCapacity: 2).encodeToBytes(pair);
        print('instance.encode bytes: $fromInstance');

        expect(fromStatic, equals(fromInstance),
            reason: 'static encode(...) should be equivalent');
      });

      test('reserve pre‑allocates without losing data', () {
        final w = BincodeWriter(initialCapacity: 2);
        w.writeU8(0x42);
        print('before reserve: ${w.toBytes()}');

        w.reserve(16);

        w.writeU8(0x99);
        final result = w.toBytes();
        print('after reserve+write: $result');

        expect(result, equals(Uint8List.fromList([0x42, 0x99])),
            reason: 'reserve() should not lose or reorder existing bytes');
      });

      test('toHex produces dash‑separated lowercase hex', () {
        final bytes = Uint8List.fromList([0xFF, 0x0A, 0x1B, 0x00]);
        final hex = BincodeWriter.toHex(bytes);
        print('hex dump: $hex');
        expect(hex, equals('ff-0a-1b-00'));
      });

      test('encodeToBase64 wraps encode + Base64', () {
        final codable = BytesOnly(Uint8List.fromList([1, 2, 3]));
        final b64 = BincodeWriter.encodeToBase64(codable);
        print('base64: $b64');
        expect(b64, equals(base64.encode([1, 2, 3])));
      });
      test('encodeToSink writes to IOSink correctly', () async {
        encodeToSinkTest();
      });
    });
    group('Reader Static API', () {
      test('isValidBincode works', isValidBincodeTest);
      test('decodeFixed decodes Vec3 correctly', decodeFixedTest);
      test('decode reads dynamic struct', decodeDynamicTest);
      test('fromBuffer reads buffer view correctly', fromBufferTest);
      test('stripNulls removes null chars', stripNullsTest);
      test(
          'measureListByteSize returns expected size', measureListByteSizeTest);
      test('peekLength reads length prefix from start', peekLengthTest);
    });
    group('Reader Utility API', () {
      test('hasBytes checks available space', hasBytesTest);
      test('isAligned detects proper alignment', isAlignedTest);
      test('align() jumps to next valid offset', alignTest);
      test('skip methods move cursor correctly', skipMethodsTest);
    });
    group('Reader Utility API - Peek and Skip Options', () {
      test('peek methods do not change position', peekMethodsTest);
      test('skipOption skips over optional values', skipOptionTest);
    });
  });
}

class ExampleData implements BincodeCodable {
  int id;
  double value;
  String label;

  ExampleData(this.id, this.value, this.label);

  ExampleData.empty()
      : id = 0,
        value = 0.0,
        label = '';

  @override
  void encode(BincodeWriter w) {
    w
      ..writeU32(id)
      ..writeF32(value)
      ..writeFixedString(label, 8);
  }

  @override
  void decode(BincodeReader r) {
    id = r.readU32();
    value = r.readF32();

    label = r.readFixedString(8).replaceAll('\x00', '');
  }

  @override
  String toString() => 'ExampleData(id: $id, value: $value, label: "$label")';
}

void classEncodingSpecTest() {
  final data = ExampleData(123, 1.5, 'Test');

  final writer = BincodeWriter();
  data.encode(writer);
  final encoded = writer.toBytes();

  final expected = Uint8List.fromList([
    123,
    0,
    0,
    0,
    0,
    0,
    192,
    63,
    84,
    101,
    115,
    116,
    0,
    0,
    0,
    0,
  ]);

  print('ExampleData encoding: $encoded');
  expect(encoded, equals(expected),
      reason: "Encoded bytes don't match expected format");

  final decoded = ExampleData.empty();
  decoded.decode(BincodeReader(encoded));

  print('Decoded: $decoded');
  expect(decoded.id, equals(123), reason: "ID mismatch");
  expect(decoded.value.toStringAsFixed(2), equals('1.50'),
      reason: "Float mismatch");
  expect(decoded.label, equals('Test'), reason: "Label mismatch");
}

void structEncodingSpecTest() {
  final writer = BincodeWriter();
  writer.writeU32(0);
  writer.writeI32(2147483647);

  final encoded = writer.toBytes();

  final expected = Uint8List.fromList([0, 0, 0, 0, 255, 255, 255, 127]);

  print("Struct Encoding: $encoded");
  assert(encoded.join(',') == expected.join(','),
      "Struct encoding failed. Expected: ${expected.join(',')}, got: ${encoded.join(',')}");
}

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

void utf8StringSpecTest() {
  final text = "Hello 🌍";

  final writer = BincodeWriter();
  writer.writeString(text);

  final result = writer.toBytes();
  print("UTF-8 String Encoding (Hello 🌍): $result");

  final expected = [
    10,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    72,
    101,
    108,
    108,
    111,
    32,
    240,
    159,
    140,
    141
  ];

  assert(result.length == expected.length,
      "UTF-8 string encoding length mismatch. Expected length ${expected.length}, got ${result.length}");
  assert(result.join(',') == expected.join(','),
      "UTF-8 string encoding failed. Expected: ${expected.join(',')}, got: ${result.join(',')}");
}

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

void enumEncodingSpecTest() {
  final a = BincodeWriter();
  a.writeU32(0);

  final b = BincodeWriter();
  b.writeU32(1);
  b.writeU32(0);

  final c = BincodeWriter();
  c.writeU32(2);
  c.writeU32(0);

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

void emptyStringEncodingTest() {
  final writer = BincodeWriter();
  writer.writeString("");

  final result = writer.toBytes();
  final expected = Uint8List.fromList(List.filled(8, 0));

  print("Empty String Encoding: $result");
  expect(result, equals(expected));
}

void emptyVecEncodingTest() {
  final writer = BincodeWriter();
  writer.writeU64(0);
  final result = writer.toBytes();
  final expected = Uint8List.fromList(List.filled(8, 0));

  print("Empty Vec Encoding: $result");
  expect(result, equals(expected));
}

void optionalZeroTest() {
  final writer = BincodeWriter();
  writer.writeOptionU32(0);
  final expected = Uint8List.fromList([1, 0, 0, 0, 0]);

  final bytes = writer.toBytes();
  print("Option<U32=0>: $bytes");
  expect(bytes, equals(expected));
}

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

class InnerData implements BincodeCodable {
  int code;
  InnerData(this.code);
  InnerData.empty() : code = 0;

  @override
  void encode(BincodeWriter w) => w.writeU32(code);

  @override
  void decode(BincodeReader r) => code = r.readU32();
}

class OuterData implements BincodeCodable {
  InnerData inner;
  double value;

  OuterData(this.inner, this.value);
  OuterData.empty()
      : inner = InnerData.empty(),
        value = 0.0;

  @override
  void encode(BincodeWriter w) {
    w.writeNestedValueForFixed(inner);
    w.writeF32(value);
  }

  @override
  void decode(BincodeReader r) {
    inner = r.readNestedObjectForFixed(InnerData.empty());
    value = r.readF32();
  }
}

void nestedStructTest() {
  final outer = OuterData(InnerData(777), 3.14);

  final writer = BincodeWriter();
  outer.encode(writer);
  final encoded = writer.toBytes();

  final reader = BincodeReader(encoded);
  final decoded = OuterData.empty();
  decoded.decode(reader);

  print("Nested struct: ${decoded.inner.code}, ${decoded.value}");

  expect(decoded.inner.code, equals(777));
  expect((decoded.value - 3.14).abs() < 1e-6, isTrue);
}

void fixedStringOverflowTest() {
  final writer = BincodeWriter();
  writer.writeFixedString("TOOLONG", 4);
  final result = writer.toBytes();
  final expected = [84, 79, 79, 76];

  print("Fixed string overflow: $result");
  expect(result.sublist(0, 4), equals(expected));

  final reader = BincodeReader(result);
  final raw = reader.readFixedString(4);
  expect(raw, equals("TOOL"));
}

void optionFixedStringTest() {
  final writer = BincodeWriter();
  writer.writeOptionFixedString("Hello", 8);
  final bytes = writer.toBytes();

  final reader1 = BincodeReader(bytes);
  final raw = reader1.readOptionFixedString(8);
  final trimmed = raw?.replaceAll('\x00', '');

  print("Manual cleaned: $trimmed");
  expect(trimmed, equals("Hello"));

  final reader2 = BincodeReader(bytes);
  final cleaned = reader2.readCleanOptionFixedString(8);

  print("Auto cleaned: $cleaned");
  expect(cleaned, equals("Hello"));
}

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
  writer.writeU8(42);
  writer.writeU8(84);
  writer.writeU8(126);
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
  expect(reader.position, equals(3));
}

void cursorSeekWriterTest() {
  final writer = BincodeWriter();
  writer.writeU8(10);
  writer.writeU8(20);
  writer.writeU8(30);

  print("Writer position after initial writes: ${writer.position}");

  writer.seek(-1);
  print("Writer position after seek(-1): ${writer.position}");
  expect(writer.position, equals(2),
      reason: "Writer should be at position 2 after seek(-1)");

  writer.writeU8(99);
  final result = writer.toBytes();
  print("Bytes after overwriting at pos 2: $result");
  expect(result[2], equals(99),
      reason: "Byte at position 2 should be overwritten to 99");

  writer.seek(-2);
  print("Writer position after seek(-2): ${writer.position}");
  expect(writer.position, equals(1), reason: "Writer at pos 1 after seek(-2)");
}

void cursorSeekReaderTest() {
  final writer = BincodeWriter();
  writer.writeU8(100);
  writer.writeU8(101);
  writer.writeU8(102);
  final bytes = writer.toBytes();
  print("Bytes written for reader: $bytes");

  final reader = BincodeReader(bytes);
  print("Initial reader position: ${reader.position}");

  reader.seek(2);
  print("Reader position after seek(2): ${reader.position}");
  expect(reader.position, equals(2), reason: "Reader at pos 2 after seek(2)");

  reader.seek(-1);
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

  expect(reader.readInt8List(), equals(int8List));
  expect(reader.readInt16List(), equals(int16List));
  expect(reader.readInt32List(), equals(int32List));
  expect(reader.readInt64List(), equals(int64List));
  expect(reader.readUint8List(), equals(uint8List));
  expect(reader.readUint16List(), equals(uint16List));
  expect(reader.readUint32List(), equals(uint32List));
  expect(reader.readUint64List(), equals(uint64List));
}

void floatListTests() {
  final f32List = [1.1, -2.2, 3.3];
  final f64List = [3.14159, -123456.789, 0.000001];

  final writer = BincodeWriter();
  writer.writeFloat32List(f32List);
  writer.writeFloat64List(f64List);

  final bytes = writer.toBytes();
  final reader = BincodeReader(bytes);

  final decodedF32 = reader.readFloat32List();
  final decodedF64 = reader.readFloat64List();

  expect(decodedF32.length, equals(f32List.length));
  for (int i = 0; i < f32List.length; i++) {
    expect(decodedF32[i], closeTo(f32List[i], 1e-5),
        reason: 'F32 mismatch at index $i');
  }

  expect(decodedF64.length, equals(f64List.length));
  for (int i = 0; i < f64List.length; i++) {
    expect(decodedF64[i], closeTo(f64List[i], 1e-10),
        reason: 'F64 mismatch at index $i');
  }
}

void completeReadWriteIntegrationTest() {
  final writer = BincodeWriter();

  writer.writeU8(255);
  writer.writeU16(65535);
  writer.writeU32(4294967295);
  writer.writeU64(1234567890123456789);
  writer.writeI8(-128);
  writer.writeI16(-32768);
  writer.writeI32(-2147483648);
  writer.writeI64(-9223372036854775808);
  writer.writeF32(3.14159);
  writer.writeF64(-2.718281828459045);
  writer.writeBool(true);
  writer.writeBool(false);

  writer.writeString("Hello, world!");
  writer.writeFixedString("Dart", 10);
  writer.writeFixedString("Dart", 10);

  writer.writeOptionU8(100);
  writer.writeOptionU8(null);
  writer.writeOptionF64(6.28318);
  writer.writeOptionF64(null);

  writer.writeList<int>([1, 2, 3, 4, 5], (int v) => writer.writeU8(v));
  writer.writeMap<int, String>(
      {1: "one", 2: "two"},
      (int key) => writer.writeU8(key),
      (String value) => writer.writeString(value));

  writer.writeInt16List([-1, -2, -3]);
  writer.writeFloat32List([0.1, 0.2, 0.3]);

  final bytes = writer.toBytes();
  final reader = BincodeReader(bytes);

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

  expect(reader.readString(), equals("Hello, world!"));
  expect(reader.readFixedString(10), equals("Dart${"\x00" * 6}"));
  expect(reader.readCleanFixedString(10), equals("Dart"));

  expect(reader.readOptionU8(), equals(100));
  expect(reader.readOptionU8(), isNull);
  expect(reader.readOptionF64(), closeTo(6.28318, 1e-12));
  expect(reader.readOptionF64(), isNull);

  final listRead = reader.readList(() => reader.readU8());
  expect(listRead, equals([1, 2, 3, 4, 5]));
  final mapRead =
      reader.readMap(() => reader.readU8(), () => reader.readString());
  expect(mapRead, equals({1: "one", 2: "two"}));

  expect(reader.readInt16List(), equals([-1, -2, -3]));
  final floatList = reader.readFloat32List();
  expect(floatList.length, equals(3));
  for (int i = 0; i < floatList.length; i++) {
    expect(floatList[i], closeTo([0.1, 0.2, 0.3][i], 1e-5));
  }
}

class NestedValue implements BincodeCodable {
  int number;
  NestedValue(this.number);
  NestedValue.empty() : number = 0;

  @override
  void encode(BincodeWriter writer) {
    writer.writeU32(number);
  }

  @override
  void decode(BincodeReader reader) {
    number = reader.readU32();
  }
}

class ComplexHolder implements BincodeCodable {
  NestedValue value;
  NestedValue? optional;

  ComplexHolder(this.value, this.optional);
  ComplexHolder.empty()
      : value = NestedValue.empty(),
        optional = null;

  @override
  void encode(BincodeWriter writer) {
    writer.writeNestedValueForFixed(value);

    writer.writeOptionNestedValueForFixed(optional);
  }

  @override
  void decode(BincodeReader reader) {
    value = reader.readNestedObjectForFixed(NestedValue.empty());
    optional = reader.readOptionNestedObjectForFixed(() => NestedValue.empty());
  }
}

void nestedEncodingWithNewMethodsTest() {
  final instance = ComplexHolder(NestedValue(42), NestedValue(99));

  final writer = BincodeWriter();
  instance.encode(writer);
  final bytes = writer.toBytes();

  final decoded = ComplexHolder.empty();
  decoded.decode(BincodeReader(bytes));

  expect(decoded.value.number, equals(42));
  expect(decoded.optional, isNotNull);
  expect(decoded.optional!.number, equals(99));
}

void optionalNestedNoneTest() {
  final instance = ComplexHolder(NestedValue(1234), null);

  final writer = BincodeWriter();
  instance.encode(writer);
  final bytes = writer.toBytes();

  expect(bytes.length, equals(5),
      reason: 'Optional none writes only a tag byte after the fixed nested');

  final decoded = ComplexHolder.empty();
  decoded.decode(BincodeReader(bytes));

  expect(decoded.value.number, equals(1234));
  expect(decoded.optional, isNull);
}

class LoginRequest implements BincodeCodable {
  String username;
  String password;

  LoginRequest(this.username, this.password);
  LoginRequest.empty()
      : username = '',
        password = '';

  @override
  void encode(BincodeWriter writer) {
    writer
      ..writeString(username)
      ..writeString(password);
  }

  @override
  void decode(BincodeReader reader) {
    throw UnimplementedError();
  }
}

class LoginResponse implements BincodeCodable {
  bool success;
  String? token;

  LoginResponse(this.success, this.token);
  LoginResponse.empty()
      : success = false,
        token = null;

  @override
  void encode(BincodeWriter writer) {
    throw UnimplementedError();
  }

  @override
  void decode(BincodeReader reader) {
    success = reader.readBool();
    token = reader.readOptionString();
  }

  @override
  String toString() => 'LoginResponse(success: $success, token: $token)';
}

void loginProtocolRoundtripTest() {
  final request = LoginRequest('admin', 's3cr3t');
  final reqWriter = BincodeWriter();
  request.encode(reqWriter);
  final reqBytes = reqWriter.toBytes();

  final serverReader = BincodeReader(reqBytes);
  final user = serverReader.readString();
  final pass = serverReader.readString();
  expect(user, equals('admin'));
  expect(pass, equals('s3cr3t'));

  final respWriter = BincodeWriter();

  respWriter
    ..writeBool(true)
    ..writeOptionString('auth-token-123');
  final respBytes = respWriter.toBytes();

  final response = LoginResponse.empty();
  response.decode(BincodeReader(respBytes));
  expect(response.success, isTrue);
  expect(response.token, equals('auth-token-123'));
}

class IpcCommand implements BincodeCodable {
  String command;
  Map<String, String> args;

  IpcCommand(this.command, this.args);
  IpcCommand.empty()
      : command = '',
        args = {};

  @override
  void encode(BincodeWriter writer) {
    writer
      ..writeString(command)
      ..writeU64(args.length);
    args.forEach((k, v) {
      writer
        ..writeString(k)
        ..writeString(v);
    });
  }

  @override
  void decode(BincodeReader reader) {
    command = reader.readString();
    final count = reader.readU64();
    args = <String, String>{};
    for (var i = 0; i < count; i++) {
      final k = reader.readString();
      final v = reader.readString();
      args[k] = v;
    }
  }

  @override
  String toString() => 'IpcCommand(command: "$command", args: $args)';
}

class IpcResponse implements BincodeCodable {
  bool success;
  String message;

  IpcResponse(this.success, this.message);
  IpcResponse.empty()
      : success = false,
        message = '';

  @override
  void encode(BincodeWriter writer) {
    writer
      ..writeBool(success)
      ..writeString(message);
  }

  @override
  void decode(BincodeReader reader) {
    success = reader.readBool();
    message = reader.readString();
  }

  @override
  String toString() => 'IpcResponse(success: $success, message: "$message")';
}

void ipcRoundtripTest() {
  final cmdOut = IpcCommand('OpenFile', {
    'path': '/tmp/data.txt',
    'mode': 'read',
  });

  final writer = BincodeWriter();
  cmdOut.encode(writer);
  final encoded = writer.toBytes();

  final reader1 = BincodeReader(encoded);
  final cmdIn = IpcCommand.empty()..decode(reader1);

  expect(cmdIn.command, equals('OpenFile'));
  expect(cmdIn.args['path'], equals('/tmp/data.txt'));
  expect(cmdIn.args['mode'], equals('read'));

  final respOut = IpcResponse(true, 'File opened successfully');
  final respWriter = BincodeWriter();
  respOut.encode(respWriter);
  final responseBytes = respWriter.toBytes();

  final reader2 = BincodeReader(responseBytes);
  final respIn = IpcResponse.empty()..decode(reader2);

  print('IPC Response: $respIn');

  expect(respIn.success, isTrue);
  expect(respIn.message, contains('opened'));
}

class GameEntitySnapshot implements BincodeCodable {
  int id;
  double x, y, rotation;
  String type;

  GameEntitySnapshot(this.id, this.x, this.y, this.rotation, this.type);

  GameEntitySnapshot.empty()
      : id = 0,
        x = 0,
        y = 0,
        rotation = 0,
        type = '';

  @override
  void encode(BincodeWriter w) {
    w
      ..writeU32(id)
      ..writeF32(x)
      ..writeF32(y)
      ..writeF32(rotation)
      ..writeString(type);
  }

  @override
  void decode(BincodeReader r) {
    id = r.readU32();
    x = r.readF32();
    y = r.readF32();
    rotation = r.readF32();
    type = r.readString();
  }

  @override
  String toString() =>
      'Entity(id: $id, pos: ($x, $y), rot: $rotation, type: "$type")';
}

Uint8List processEntityOnServer(Uint8List requestBytes) {
  final reader = BincodeReader(requestBytes);
  final entity = GameEntitySnapshot.empty()..decode(reader);

  final updated = GameEntitySnapshot(
    entity.id,
    entity.x.clamp(0.0, 100.0),
    entity.y.clamp(0.0, 100.0),
    (entity.rotation + 45.0) % 360.0,
    'ServerConfirmed-${entity.type}',
  );

  final writer = BincodeWriter();
  updated.encode(writer);
  return writer.toBytes();
}

void entitySnapshotIpcTest() {
  final message = GameEntitySnapshot(1, 123.0, -20.0, 270.0, 'Player');
  final writer = BincodeWriter();
  message.encode(writer);
  final requestBytes = writer.toBytes();

  final responseBytes = processEntityOnServer(requestBytes);

  final reader = BincodeReader(responseBytes);
  final updatedSnapshot = GameEntitySnapshot.empty()..decode(reader);

  print('Client sent:    $message');
  print('Server replied: $updatedSnapshot');

  expect(updatedSnapshot.id, equals(1));
  expect(updatedSnapshot.x, equals(100.0));
  expect(updatedSnapshot.y, equals(0.0));
  expect(updatedSnapshot.rotation, equals(315.0));
  expect(updatedSnapshot.type, equals('ServerConfirmed-Player'));
}

class Level4 implements BincodeCodable {
  int value;

  Level4(this.value);
  Level4.empty() : value = 0;

  @override
  void encode(BincodeWriter w) {
    w.writeU32(value);
  }

  @override
  void decode(BincodeReader r) {
    value = r.readU32();
  }

  @override
  String toString() => 'Level4(value: $value)';
}

class Level3 implements BincodeCodable {
  Level4 child;

  Level3(this.child);
  Level3.empty() : child = Level4.empty();

  @override
  void encode(BincodeWriter w) {
    w.writeNestedValueForFixed(child);
  }

  @override
  void decode(BincodeReader r) {
    child = r.readNestedObjectForFixed(Level4.empty());
  }

  @override
  String toString() => 'Level3($child)';
}

class Level2 implements BincodeCodable {
  Level3 child;

  Level2(this.child);
  Level2.empty() : child = Level3.empty();

  @override
  void encode(BincodeWriter w) {
    w.writeNestedValueForFixed(child);
  }

  @override
  void decode(BincodeReader r) {
    child = r.readNestedObjectForFixed(Level3.empty());
  }

  @override
  String toString() => 'Level2($child)';
}

class Level1 implements BincodeCodable {
  Level2 child;

  Level1(this.child);
  Level1.empty() : child = Level2.empty();

  @override
  void encode(BincodeWriter w) {
    w.writeNestedValueForFixed(child);
  }

  @override
  void decode(BincodeReader r) {
    child = r.readNestedObjectForFixed(Level2.empty());
  }

  @override
  String toString() => 'Level1($child)';
}

void ultraInsaneCrazyTest() {
  final writer = BincodeWriter();

  writer.writeU8(0xAA);
  writer.writeU16(0x1234);
  writer.writeU32(0xDEADBEEF);
  writer.writeI32(-123456);
  writer.writeF64(2.718281828);
  writer.writeBool(true);

  writer.writeString('Start');
  writer.writeOptionString(null);
  writer.writeOptionString('OptionHere');

  final heterogeneous = <Object>[42, 'Answer', Level4(4242)];
  writer.writeU64(heterogeneous.length);
  for (final element in heterogeneous) {
    if (element is int) {
      writer.writeU8(0);
      writer.writeI32(element);
    } else if (element is String) {
      writer.writeU8(1);
      writer.writeString(element);
    } else if (element is Level4) {
      writer.writeU8(2);
      writer.writeNestedValueForFixed(element);
    }
  }

  final nestedMap = {
    'first': Level1(Level2(Level3(Level4(1)))),
    'second': Level1(Level2(Level3(Level4(2)))),
  };
  writer.writeMap<String, Level1>(
    nestedMap,
    (k) => writer.writeString(k),
    (v) => writer.writeNestedValueForFixed(v),
  );

  writer.writeString('END');

  final bytes = writer.toBytes();
  print('Ultra‑insane bytes: ${bytes.toList()}');

  final reader = BincodeReader(bytes);

  expect(reader.readU8(), equals(0xAA));
  expect(reader.readU16(), equals(0x1234));
  expect(reader.readU32(), equals(0xDEADBEEF));
  expect(reader.readI32(), equals(-123456));
  expect(reader.readF64(), closeTo(2.718281828, 1e-12));
  expect(reader.readBool(), isTrue);

  expect(reader.readString(), equals('Start'));
  expect(reader.readOptionString(), isNull);
  expect(reader.readOptionString(), equals('OptionHere'));

  final listLen = reader.readU64();
  final decodedHetero = <Object>[];
  for (var i = 0; i < listLen; i++) {
    final tag = reader.readU8();
    switch (tag) {
      case 0:
        decodedHetero.add(reader.readI32());
        break;
      case 1:
        decodedHetero.add(reader.readString());
        break;
      case 2:
        decodedHetero.add(reader.readNestedObjectForFixed(Level4.empty()));
        break;
      default:
        fail('Unknown tag $tag');
    }
  }
  expect(decodedHetero[0], equals(42));
  expect(decodedHetero[1], equals('Answer'));
  expect((decodedHetero[2] as Level4).value, equals(4242));

  final mapLen = reader.readU64();
  final decodedMap = <String, Level1>{};
  for (var i = 0; i < mapLen; i++) {
    final key = reader.readString();
    decodedMap[key] = reader.readNestedObjectForFixed(Level1.empty());
  }
  expect(decodedMap['first']!.child.child.child.value, equals(1));
  expect(decodedMap['second']!.child.child.child.value, equals(2));

  expect(reader.readString(), equals('END'));
}

class Level4Ext implements BincodeCodable {
  int value;
  bool active;
  List<double> metrics;
  String name;

  Level4Ext(this.value, this.active, this.metrics, this.name);
  Level4Ext.empty()
      : value = 0,
        active = false,
        metrics = [],
        name = '';

  @override
  void encode(BincodeWriter w) {
    w.writeU32(value);
    w.writeBool(active);
    w.writeList<double>(metrics, (m) => w.writeF64(m));
    w.writeString(name);
  }

  @override
  void decode(BincodeReader r) {
    value = r.readU32();
    active = r.readBool();
    metrics = r.readList(() => r.readF64());
    name = r.readString();
  }

  @override
  String toString() =>
      'Level4Ext(value: $value, active: $active, metrics: $metrics, name: "$name")';
}

class Level3Ext implements BincodeCodable {
  Level4Ext primary;
  Level4Ext? optionalChild;
  Map<String, Level4Ext> lookup;

  Level3Ext(this.primary, this.optionalChild, this.lookup);
  Level3Ext.empty()
      : primary = Level4Ext.empty(),
        optionalChild = null,
        lookup = {};

  @override
  void encode(BincodeWriter w) {
    w.writeNestedValueForCollection(primary);
    w.writeOptionNestedValueForCollection(optionalChild);
    w.writeMap<String, Level4Ext>(
      lookup,
      (k) => w.writeString(k),
      (v) => w.writeNestedValueForCollection(v),
    );
  }

  @override
  void decode(BincodeReader r) {
    primary = r.readNestedObjectForCollection(Level4Ext.empty());
    optionalChild =
        r.readOptionNestedObjectForCollection(() => Level4Ext.empty());
    lookup = r.readMap<String, Level4Ext>(
      () => r.readString(),
      () => r.readNestedObjectForCollection(Level4Ext.empty()),
    );
  }

  @override
  String toString() =>
      'Level3Ext(primary: $primary, optionalChild: $optionalChild, lookup: $lookup)';
}

class Level2Ext implements BincodeCodable {
  Level3Ext main;
  List<Level3Ext> extras;
  Level4Ext extraLeaf;

  Level2Ext(this.main, this.extras, this.extraLeaf);
  Level2Ext.empty()
      : main = Level3Ext.empty(),
        extras = [],
        extraLeaf = Level4Ext.empty();

  @override
  void encode(BincodeWriter w) {
    w.writeNestedValueForCollection(main);
    w.writeList<Level3Ext>(extras, (e) => w.writeNestedValueForCollection(e));
    w.writeNestedValueForCollection(extraLeaf);
  }

  @override
  void decode(BincodeReader r) {
    main = r.readNestedObjectForCollection(Level3Ext.empty());
    extras =
        r.readList(() => r.readNestedObjectForCollection(Level3Ext.empty()));
    extraLeaf = r.readNestedObjectForCollection(Level4Ext.empty());
  }

  @override
  String toString() =>
      'Level2Ext(main: $main, extras: $extras, extraLeaf: $extraLeaf)';
}

class Level1Ext implements BincodeCodable {
  Level2Ext root;
  Map<int, Level2Ext> registry;
  List<String> tags;

  Level1Ext(this.root, this.registry, this.tags);
  Level1Ext.empty()
      : root = Level2Ext.empty(),
        registry = {},
        tags = [];

  @override
  void encode(BincodeWriter w) {
    w.writeNestedValueForCollection(root);
    w.writeMap<int, Level2Ext>(
      registry,
      (k) => w.writeU32(k),
      (v) => w.writeNestedValueForCollection(v),
    );
    w.writeList<String>(tags, (t) => w.writeString(t));
  }

  @override
  void decode(BincodeReader r) {
    root = r.readNestedObjectForCollection(Level2Ext.empty());
    registry = r.readMap<int, Level2Ext>(
      () => r.readU32(),
      () => r.readNestedObjectForCollection(Level2Ext.empty()),
    );
    tags = r.readList(() => r.readString());
  }

  @override
  String toString() =>
      'Level1Ext(root: $root, registry: $registry, tags: $tags)';
}

void deepComplexTest() {
  final l4a = Level4Ext(10, true, [1.1, 2.2], 'A');
  final l4b = Level4Ext(20, false, [3.3], 'B');
  final lookup3 = {
    'x': Level4Ext(30, true, [4.4], 'X')
  };
  final lvl3Main = Level3Ext(l4a, l4b, lookup3);

  final extra1 = Level3Ext(
    Level4Ext(40, true, [], 'E1'),
    null,
    {},
  );
  final extra2Lookup = {
    'foo': Level4Ext(50, false, [5.5], 'Foo')
  };
  final extra2 = Level3Ext(
    Level4Ext(50, false, [5.5], 'Foo'),
    Level4Ext(60, true, [6.6], 'Sixty'),
    extra2Lookup,
  );

  final lvl2Root = Level2Ext(
    lvl3Main,
    [extra1, extra2],
    Level4Ext(70, false, [7.7], 'Leaf'),
  );

  final registry = {
    1: lvl2Root,
    2: Level2Ext.empty(),
  };

  final tags = ['tag1', 'tag2', 'tag3'];
  final lvl1 = Level1Ext(lvl2Root, registry, tags);

  final writer = BincodeWriter();
  lvl1.encode(writer);
  final bytes = writer.toBytes();

  print('Deep Complex Bytes (${bytes.length}): ${bytes.toList()}');

  final decoded = Level1Ext.empty();
  decoded.decode(BincodeReader(bytes));

  print('root.main.primary:     ${decoded.root.main.primary}');
  print('root.main.optionalChild: ${decoded.root.main.optionalChild}');
  print('root.main.lookup:      ${decoded.root.main.lookup}\n');

  print('root.extras[0]:        ${decoded.root.extras[0]}');
  print('root.extras[1]:        ${decoded.root.extras[1]}\n');

  print('root.extraLeaf:        ${decoded.root.extraLeaf}\n');

  print('registry[1]:           ${decoded.registry[1]}');
  print('registry[2]:           ${decoded.registry[2]}\n');

  print('tags:                  ${decoded.tags}\n');

  expect(decoded.root.main.primary.value, equals(10));
  expect(decoded.root.main.primary.active, isTrue);
  expect(decoded.root.main.primary.metrics, equals([1.1, 2.2]));
  expect(decoded.root.main.primary.name, equals('A'));

  expect(decoded.root.main.optionalChild, isNotNull);
  expect(decoded.root.main.lookup['x']!.name, equals('X'));

  expect(decoded.root.extras.length, equals(2));
  expect(decoded.root.extras[0].primary.value, equals(40));
  expect(decoded.root.extras[0].optionalChild, isNull);
  expect(decoded.root.extras[1].primary.value, equals(50));
  expect(decoded.root.extras[1].optionalChild!.value, equals(60));

  expect(decoded.root.extraLeaf.value, equals(70));
  expect(decoded.root.extraLeaf.name, equals('Leaf'));

  expect(decoded.registry.length, equals(2));
  final reg1 = decoded.registry[1]!;
  expect(reg1.main.primary.value, equals(10));
  expect(decoded.registry[2]!.main.primary.value, equals(0));

  expect(decoded.tags, equals(tags));
}

class SimplePair implements BincodeCodable {
  final int a, b;
  SimplePair(this.a, this.b);
  SimplePair.empty()
      : a = 0,
        b = 0;

  @override
  void encode(BincodeWriter w) {
    w
      ..writeU8(a)
      ..writeU16(b);
  }

  @override
  void decode(BincodeReader r) {
    throw UnimplementedError();
  }
}

class BytesOnly implements BincodeCodable {
  final Uint8List payload;
  BytesOnly(this.payload);
  @override
  void encode(BincodeWriter w) => w.writeBytes(payload);
  @override
  void decode(BincodeReader r) => throw UnimplementedError();
}

class DummyData implements BincodeCodable {
  int value;
  DummyData(this.value);
  DummyData.empty() : value = 0;

  @override
  void encode(BincodeWriter w) {
    w.writeU32(value);
  }

  @override
  void decode(BincodeReader r) {
    value = r.readU32();
  }

  @override
  String toString() => 'DummyData($value)';
}

void writeReadNestedCollectionTest() {
  final original = DummyData(999);
  final writer = BincodeWriter();
  writer.writeNestedValueForCollection(original);

  final bytes = writer.toBytes();
  final reader = BincodeReader(bytes);
  final decoded = reader.readNestedObjectForCollection(DummyData.empty());

  expect(decoded.value, equals(999),
      reason: 'readNestedObjectForCollection should correctly decode payload');
}

void writeReadOptionalNestedCollectionTest() {
  final present = DummyData(42);
  final absent = null;

  final writer = BincodeWriter();
  writer.writeOptionNestedValueForCollection(present);
  writer.writeOptionNestedValueForCollection(absent);

  final reader = BincodeReader(writer.toBytes());

  final decodedPresent =
      reader.readOptionNestedObjectForCollection(() => DummyData.empty());
  final decodedAbsent =
      reader.readOptionNestedObjectForCollection(() => DummyData.empty());

  expect(decodedPresent, isNotNull);
  expect(decodedPresent!.value, equals(42));
  expect(decodedAbsent, isNull);
}

void encodeToFileSyncTest() {
  final path = 'test_output.bin';
  final data = DummyData(123456);

  BincodeWriter.encodeToFileSync(data, path);

  final fileBytes = File(path).readAsBytesSync();
  final decoded = DummyData.empty();
  decoded.decode(BincodeReader(fileBytes));

  expect(decoded.value, equals(123456));

  File(path).deleteSync();
}

void encodeToSinkTest() async {
  final data = DummyData(2024);
  final collected = <int>[];

  final controller = StreamController<List<int>>();
  final sink = IOSink(controller.sink);

  controller.stream.listen(collected.addAll);

  final writer = BincodeWriter();
  await writer.encodeToSink(data, sink);
  await sink.close();
  await controller.close();

  final resultBytes = Uint8List.fromList(collected);
  final decoded = DummyData.empty();
  decoded.decode(BincodeReader(resultBytes));

  expect(decoded.value, equals(2024),
      reason: 'encodeToSink should write valid binary data to IOSink');
}

class Vec3 implements BincodeCodable {
  double x, y, z;
  Vec3(this.x, this.y, this.z);
  Vec3.empty()
      : x = 0,
        y = 0,
        z = 0;

  @override
  void encode(BincodeWriter w) {
    w.writeF32(x);
    w.writeF32(y);
    w.writeF32(z);
  }

  @override
  void decode(BincodeReader r) {
    x = r.readF32();
    y = r.readF32();
    z = r.readF32();
  }

  @override
  String toString() => 'Vec3(x: $x, y: $y, z: $z)';
}

void isValidBincodeTest() {
  final goodVec = Vec3(1.0, 2.0, 3.0);
  final writer = BincodeWriter();
  goodVec.encode(writer);
  final goodBytes = writer.toBytes();

  final badBytes = goodBytes.sublist(0, goodBytes.length - 1);

  final result1 = BincodeReader.isValidBincode(goodBytes, Vec3.empty());
  final result2 = BincodeReader.isValidBincode(badBytes, Vec3.empty());

  expect(result1, isTrue, reason: "Should successfully validate Vec3 bytes");
  expect(result2, isFalse, reason: "Truncated Vec3 should fail validation");
}

void decodeFixedTest() {
  final original = Vec3(3.0, -2.0, 5.5);
  final bytes = BincodeWriter.encode(original);

  final decoded = BincodeReader.decodeFixed(bytes, Vec3.empty());

  expect(decoded.x, closeTo(3.0, 1e-6));
  expect(decoded.y, closeTo(-2.0, 1e-6));
  expect(decoded.z, closeTo(5.5, 1e-6));
}

class User implements BincodeCodable {
  String name;
  List<int> scores;

  User(this.name, this.scores);
  User.empty()
      : name = '',
        scores = [];

  @override
  void encode(BincodeWriter w) {
    w.writeString(name);
    w.writeList(scores, (s) => w.writeU32(s));
  }

  @override
  void decode(BincodeReader r) {
    name = r.readString();
    scores = r.readList(() => r.readU32());
  }

  @override
  String toString() => 'User(name: $name, scores: $scores)';
}

void decodeDynamicTest() {
  final original = User("Alice", [10, 20, 30]);
  final bytes = BincodeWriter.encode(original);

  final result = BincodeReader.decode(bytes, User.empty());

  expect(result.name, equals("Alice"));
  expect(result.scores, equals([10, 20, 30]));
}

void fromBufferTest() {
  final writer = BincodeWriter();
  writer.writeU64(123456789);
  final buffer = writer.toBytes().buffer;

  final reader = BincodeReader.fromBuffer(buffer);
  final value = reader.readU64();

  expect(value, equals(123456789));
}

void stripNullsTest() {
  const raw = 'Hello\x00\x00\x00';
  final clean = BincodeReader.stripNulls(raw);

  expect(clean, equals('Hello'));
}

void measureListByteSizeTest() {
  final writer = BincodeWriter();
  writer.writeU64(3);
  writer.writeU32(10);
  writer.writeU32(20);
  writer.writeU32(30);

  final bytes = writer.toBytes();
  final size = BincodeReader.measureListByteSize(bytes, 4);

  expect(size, equals(20));
}

void peekLengthTest() {
  final writer = BincodeWriter();
  writer.writeU64(42);
  final bytes = writer.toBytes();

  final peeked = BincodeReader.peekLength(bytes);
  expect(peeked, equals(42));
}

void hasBytesTest() {
  final writer = BincodeWriter();
  writer.writeU32(0xDEADBEEF);
  final bytes = writer.toBytes();

  final reader = BincodeReader(bytes);
  expect(reader.hasBytes(4), isTrue);
  expect(reader.hasBytes(5), isFalse);

  reader.readU32();
  expect(reader.hasBytes(1), isFalse);
}

void isAlignedTest() {
  final writer = BincodeWriter();
  writer.writeU8(0x01);
  writer.writeU8(0x02);
  writer.writeU8(0x03);
  writer.writeU8(0x04);
  final reader = BincodeReader(writer.toBytes());

  expect(reader.isAligned(1), isTrue);
  expect(reader.isAligned(2), isTrue);
  expect(reader.isAligned(4), isTrue);

  reader.seek(3);
  expect(reader.isAligned(2), isFalse);
  expect(reader.isAligned(4), isFalse);
}

void alignTest() {
  final writer = BincodeWriter();
  writer.writeU8(0x11);
  writer.writeU8(0x22);
  writer.writeU8(0x33);
  writer.writeU8(0x44);
  writer.writeU8(0x55);
  final reader = BincodeReader(writer.toBytes());

  reader.seek(3);
  reader.align(4);
  expect(reader.position, equals(4));

  expect(reader.readU8(), equals(0x55));
}

void skipMethodsTest() {
  final writer = BincodeWriter();
  writer.writeU8(1);
  writer.writeU16(0x0203);
  writer.writeU32(0x04050607);
  writer.writeU64(0x08090A0B0C0D0E0F);
  writer.writeF32(1.23);
  writer.writeF64(6.28);

  final reader = BincodeReader(writer.toBytes());

  reader.skipU8();
  expect(reader.position, equals(1));

  reader.skipU16();
  expect(reader.position, equals(3));

  reader.skipU32();
  expect(reader.position, equals(7));

  reader.skipU64();
  expect(reader.position, equals(15));

  reader.skipF32();
  expect(reader.position, equals(19));

  reader.skipF64();
  expect(reader.position, equals(27));
}

void peekMethodsTest() {
  final writer = BincodeWriter();

  writer.writeU8(0x01);
  writer.writeU16(0x0203);
  writer.writeU32(0x04050607);
  writer.writeU64(0x08090A0B0C0D0E0F);
  writer.writeF32(1.23);
  writer.writeF64(6.28);

  final bytes = writer.toBytes();

  print("Written bytes: ${bytes.toList()}");

  final reader = BincodeReader(bytes);

  final initialPos = reader.position;

  reader.peekSession(() {
    expect(reader.readU8(), equals(0x01));
    expect(reader.readU16(), equals(0x0203));
    expect(reader.readU32(), equals(0x04050607));
    expect(reader.readU64(), equals(0x08090A0B0C0D0E0F));
    expect(reader.readF32(), closeTo(1.23, 1e-6));
    expect(reader.readF64(), equals(6.28));
  });

  expect(reader.position, equals(initialPos));
}

void skipOptionTest() {
  final writer = BincodeWriter();

  writer.writeOptionBool(true);
  writer.writeOptionBool(false);
  writer.writeOptionBool(null);

  final bytes = writer.toBytes();

  final reader = BincodeReader(bytes);

  final initialPos = reader.position;

  reader.skipOption(() {
    expect(reader.readBool(), equals(true));
  });
  expect(reader.position, greaterThan(initialPos));

  reader.skipOption(() {
    expect(reader.readBool(), equals(false));
  });
  expect(reader.position, greaterThan(initialPos));

  reader.skipOption(() {});
  expect(reader.position, greaterThan(initialPos));

  writer.resetWith(128);
  writer.writeOptionU8(10);
  writer.writeOptionU8(null);

  final bytes2 = writer.toBytes();
  final reader2 = BincodeReader(bytes2);

  reader2.skipOption(() {
    expect(reader2.readU8(), equals(10));
  });
  expect(reader2.position, greaterThan(initialPos));

  reader2.skipOption(() {});
  expect(reader2.position, greaterThan(initialPos));

  writer.resetWith(128);
  writer.writeOptionU16(300);
  writer.writeOptionU16(null);

  final bytes3 = writer.toBytes();
  final reader3 = BincodeReader(bytes3);

  reader3.skipOption(() {
    expect(reader3.readU16(), equals(300));
  });
  expect(reader3.position, greaterThan(initialPos));

  reader3.skipOption(() {});
  expect(reader3.position, greaterThan(initialPos));
}
