// ignore_for_file: unused_local_variable

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

import 'dart:typed_data';

import 'package:d_bincode/d_bincode.dart';
import 'package:d_bincode/src/exception/exception.dart';
import 'package:test/test.dart';

class TestFixedStructTwo implements BincodeCodable {
  int id = 0;
  double value = 0.0;
  bool enabled = false;
  static final int expectedSize = 4 + 8 + 1;
  TestFixedStructTwo();
  TestFixedStructTwo.create(this.id, this.value, this.enabled);
  @override
  void decode(BincodeReader r) {
    id = r.readI32();
    value = r.readF64();
    enabled = r.readBool();
  }

  @override
  void encode(BincodeWriter w) {
    w.writeI32(id);
    w.writeF64(value);
    w.writeBool(enabled);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestFixedStructTwo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          (value - other.value).abs() < 1e-9 &&
          enabled == other.enabled;
  @override
  int get hashCode => id.hashCode ^ value.hashCode ^ enabled.hashCode;
  @override
  String toString() =>
      'TestFixedStructTwo(id: $id, value: $value, enabled: $enabled)';
}

class _TooSmallStruct implements BincodeEncodable {
  @override
  void encode(BincodeWriter w) {
    w.writeI32(1);
  }
}

class _TooLargeStruct implements BincodeEncodable {
  @override
  void encode(BincodeWriter w) {
    w.writeI32(1);
    w.writeI32(2);
    w.writeI32(3);
    w.writeI32(4);
  }
}

void testWriteNestedKnownSizeSuccess() {
  final writer = BincodeWriter();
  final data = TestFixedStructTwo.create(123, 3.14, true);
  final knownSize = TestFixedStructTwo.expectedSize;

  writer.writeNestedObjectWithKnownSize(data, knownSize);

  final expectedBytesWriter = BincodeWriter();
  data.encode(expectedBytesWriter);
  final expectedBytes = expectedBytesWriter.toBytes();

  expect(writer.toBytes(), equals(expectedBytes));
  expect(writer.position, equals(knownSize));
  expect(writer.getBytesWritten(), equals(knownSize));
}

void testWriteNestedKnownSizeMismatchTooSmall() {
  final writer = BincodeWriter();
  final data = _TooSmallStruct();
  final knownSize = 10;

  expect(
    () => writer.writeNestedObjectWithKnownSize(data, knownSize),
    throwsA(isA<BincodeException>().having((e) => e.message, 'message',
        contains('wrote incorrect bytes. Actual: 4'))),
  );

  expect(writer.position, equals(4));
}

void testWriteNestedKnownSizeMismatchTooLarge() {
  final writer = BincodeWriter();
  final data = _TooLargeStruct();
  final knownSize = 10;

  expect(
    () => writer.writeNestedObjectWithKnownSize(data, knownSize),
    throwsA(isA<BincodeException>().having((e) => e.message, 'message',
        contains('wrote incorrect bytes. Actual: 16'))),
  );

  expect(writer.position, equals(16));
}

void testWriteNestedKnownSizeNegative() {
  final writer = BincodeWriter();
  final data = TestFixedStructTwo.create(1, 1.0, true);

  expect(
    () => writer.writeNestedObjectWithKnownSize(data, -1),
    throwsA(isA<BincodeException>().having((e) => e.message, 'message',
        contains('Known size cannot be negative'))),
  );

  expect(writer.position, isZero);
}

void testWriteOptionNestedKnownSizeSomeSuccess() {
  final writer = BincodeWriter();
  final data = TestFixedStructTwo.create(456, -2.7, false);
  final knownSize = TestFixedStructTwo.expectedSize;

  writer.writeOptionNestedObjectWithKnownSize(data, knownSize);

  final expectedBytesWriter = BincodeWriter();
  expectedBytesWriter.writeU8(1);
  data.encode(expectedBytesWriter);
  final expectedBytes = expectedBytesWriter.toBytes();

  expect(writer.toBytes(), equals(expectedBytes));
  expect(writer.position, equals(1 + knownSize));
  expect(writer.getBytesWritten(), equals(1 + knownSize));
}

void testWriteOptionNestedKnownSizeNone() {
  final writer = BincodeWriter();
  final TestFixedStructTwo? data = null;
  final knownSize = TestFixedStructTwo.expectedSize;

  writer.writeOptionNestedObjectWithKnownSize(data, knownSize);

  final expectedBytes = Uint8List.fromList([0]);

  expect(writer.toBytes(), equals(expectedBytes));
  expect(writer.position, equals(1));
  expect(writer.getBytesWritten(), equals(1));
}

void testWriteOptionNestedKnownSizeSomeMismatchTooSmall() {
  final writer = BincodeWriter();
  final data = _TooSmallStruct();
  final knownSize = 10;

  expect(
    () => writer.writeOptionNestedObjectWithKnownSize(data, knownSize),
    throwsA(isA<BincodeException>().having((e) => e.message, 'message',
        contains('wrote incorrect bytes. Actual: 4'))),
  );

  expect(writer.position, equals(5));
}

void testWriteOptionNestedKnownSizeSomeMismatchTooLarge() {
  final writer = BincodeWriter();
  final data = _TooLargeStruct();
  final knownSize = 10;

  expect(
    () => writer.writeOptionNestedObjectWithKnownSize(data, knownSize),
    throwsA(isA<BincodeException>().having((e) => e.message, 'message',
        contains('wrote incorrect bytes. Actual: 16'))),
  );

  expect(writer.position, equals(17));
}

void testWriteOptionNestedKnownSizeNegative() {
  final writer = BincodeWriter();
  final data = TestFixedStructTwo.create(1, 1.0, true);

  expect(
    () => writer.writeOptionNestedObjectWithKnownSize(data, -1),
    throwsA(isA<BincodeException>().having((e) => e.message, 'message',
        contains('Known size cannot be negative'))),
  );

  expect(writer.position, equals(1));
}

void main() {
  print('--- EXECUTING writer_known_size_test.dart main ---');
  group('BincodeWriter Known Size Tests', () {
    group('writeNestedObjectWithKnownSize', () {
      test('Success case', testWriteNestedKnownSizeSuccess);
      test('Error: encode writes fewer bytes than knownSize',
          testWriteNestedKnownSizeMismatchTooSmall);
      test('Error: encode writes more bytes than knownSize',
          testWriteNestedKnownSizeMismatchTooLarge);
      test('Error: negative knownSize', testWriteNestedKnownSizeNegative);
    });

    group('writeOptionNestedObjectWithKnownSize', () {
      test('Success case: Some', testWriteOptionNestedKnownSizeSomeSuccess);
      test('Success case: None', testWriteOptionNestedKnownSizeNone);
      test('Error: Some value encode writes fewer bytes than knownSize',
          testWriteOptionNestedKnownSizeSomeMismatchTooSmall);
      test('Error: Some value encode writes more bytes than knownSize',
          testWriteOptionNestedKnownSizeSomeMismatchTooLarge);
      test('Error: negative knownSize with Some value',
          testWriteOptionNestedKnownSizeNegative);
    });
  });
}
