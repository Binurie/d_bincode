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

void testReadNestedKnownSizeSuccess() {
  final original = TestFixedStructTwo.create(987, 2.718, true);
  final writer = BincodeWriter();
  original.encode(writer);
  final bytes = writer.toBytes();
  final reader = BincodeReader(bytes);
  final decodedInstance = TestFixedStructTwo();
  final result = reader.readNestedObjectWithKnownSize<TestFixedStructTwo>(
      decodedInstance, TestFixedStructTwo.expectedSize);
  expect(result, equals(original));
  expect(identical(result, decodedInstance), isTrue);
  expect(reader.position, equals(TestFixedStructTwo.expectedSize));
  expect(reader.remainingBytes, isZero);
}

void testReadNestedKnownSizeTooSmall() {
  final original = TestFixedStructTwo.create(111, 1.0, false);
  final writer = BincodeWriter();
  original.encode(writer);
  final bytes = writer.toBytes();
  final reader = BincodeReader(bytes);
  final decodedInstance = TestFixedStructTwo();
  final knownSizeTooSmall = TestFixedStructTwo.expectedSize - 1;
  expect(
    () => reader.readNestedObjectWithKnownSize<TestFixedStructTwo>(
        decodedInstance, knownSizeTooSmall),
    throwsA(isA<RangeError>()),
  );
  expect(reader.position, equals(12));
}

void testReadNestedKnownSizeTooLarge() {
  final original = TestFixedStructTwo.create(222, 2.0, true);
  final writer = BincodeWriter();
  original.encode(writer);
  final bytes = writer.toBytes();
  final reader = BincodeReader(bytes);
  final decodedInstance = TestFixedStructTwo();
  final knownSizeTooLarge = TestFixedStructTwo.expectedSize + 1;
  expect(
    () => reader.readNestedObjectWithKnownSize<TestFixedStructTwo>(
        decodedInstance, knownSizeTooLarge),
    throwsA(isA<RangeError>()),
  );
  expect(reader.position, isZero);
}

void testReadNestedKnownSizeExceedsBuffer() {
  final original = TestFixedStructTwo.create(333, 3.0, false);
  final writer = BincodeWriter();
  original.encode(writer);
  final bytes = writer.toBytes();
  final reader = BincodeReader(bytes);
  final decodedInstance = TestFixedStructTwo();
  final knownSizeExceeds = bytes.length + 1;
  expect(
    () => reader.readNestedObjectWithKnownSize<TestFixedStructTwo>(
        decodedInstance, knownSizeExceeds),
    throwsA(isA<RangeError>()),
  );
  expect(reader.position, isZero);
}

void testReadNestedKnownSizeNegative() {
  final reader = BincodeReader(Uint8List(10));
  final decodedInstance = TestFixedStructTwo();
  expect(
    () => reader.readNestedObjectWithKnownSize<TestFixedStructTwo>(
        decodedInstance, -1),
    throwsA(isA<BincodeException>().having((e) => e.message, 'message',
        contains('Known size cannot be negative'))),
  );
}

void testReadNestedKnownSizeZero() {
  final reader = BincodeReader(Uint8List(10));
  final decodedInstance = TestFixedStructTwo();
  expect(
    () => reader.readNestedObjectWithKnownSize<TestFixedStructTwo>(
        decodedInstance, 0),
    throwsA(isA<RangeError>()),
  );
  expect(reader.position, isZero);
}

void testReadOptionNestedKnownSizeSome() {
  final original = TestFixedStructTwo.create(456, -2.718, false);
  final writer = BincodeWriter();
  writer.writeU8(1);
  original.encode(writer);
  final bytes = writer.toBytes();
  final reader = BincodeReader(bytes);
  final result = reader.readOptionNestedObjectWithKnownSize<TestFixedStructTwo>(
      () => TestFixedStructTwo(), TestFixedStructTwo.expectedSize);
  expect(result, isNotNull);
  expect(result, equals(original));
  expect(reader.position, equals(1 + TestFixedStructTwo.expectedSize));
  expect(reader.remainingBytes, isZero);
}

void testReadOptionNestedKnownSizeNone() {
  final writer = BincodeWriter();
  writer.writeU8(0);
  final bytes = writer.toBytes();
  final reader = BincodeReader(bytes);
  final result = reader.readOptionNestedObjectWithKnownSize<TestFixedStructTwo>(
      () => TestFixedStructTwo(), TestFixedStructTwo.expectedSize);
  expect(result, isNull);
  expect(reader.position, equals(1));
  expect(reader.remainingBytes, isZero);
}

void testReadOptionNestedKnownSizeInvalidTag() {
  final writer = BincodeWriter();
  writer.writeU8(2);
  writer.writeI32(99);
  final bytes = writer.toBytes();
  final reader = BincodeReader(bytes);
  expect(
    () => reader.readOptionNestedObjectWithKnownSize<TestFixedStructTwo>(
        () => TestFixedStructTwo(), TestFixedStructTwo.expectedSize),
    throwsA(isA<InvalidOptionTagException>()),
  );
  expect(reader.position, equals(1));
}

void testReadOptionNestedKnownSizeInsufficientData() {
  final writer = BincodeWriter();
  writer.writeU8(1);
  writer.writeI32(123);
  final bytes = writer.toBytes();
  final reader = BincodeReader(bytes);
  expect(
    () => reader.readOptionNestedObjectWithKnownSize<TestFixedStructTwo>(
        () => TestFixedStructTwo(), TestFixedStructTwo.expectedSize),
    throwsA(isA<RangeError>()),
  );
}

void testReadOptionNestedKnownSizeIncorrectKnownSize() {
  final original = TestFixedStructTwo.create(789, 1.618, true);
  final writer = BincodeWriter();
  writer.writeU8(1);
  original.encode(writer);
  final bytes = writer.toBytes();
  final reader = BincodeReader(bytes);
  final knownSizeTooSmall = TestFixedStructTwo.expectedSize - 1;
  expect(
    () => reader.readOptionNestedObjectWithKnownSize<TestFixedStructTwo>(
        () => TestFixedStructTwo(), knownSizeTooSmall),
    throwsA(isA<RangeError>()),
  );
  expect(reader.position, equals(1 + 12));
}

void testReadOptionNestedKnownSizeNegativeKnownSize() {
  final original = TestFixedStructTwo.create(101, 0.0, false);
  final writer = BincodeWriter();
  writer.writeU8(1);
  original.encode(writer);
  final bytes = writer.toBytes();
  final reader = BincodeReader(bytes);
  expect(
    () => reader.readOptionNestedObjectWithKnownSize<TestFixedStructTwo>(
        () => TestFixedStructTwo(), -5),
    throwsA(isA<BincodeException>().having((e) => e.message, 'message',
        contains('Known size cannot be negative'))),
  );
  expect(reader.position, equals(1));
}

void main() {
  print('--- EXECUTING reader_known_size_test.dart main ---');
  group('BincodeReader Known Size Tests', () {
    group('readNestedObjectWithKnownSize<TestFixedStructTwo>', () {
      test('Success case', testReadNestedKnownSizeSuccess);
      test('Error: knownSize too small throws RangeError',
          testReadNestedKnownSizeTooSmall);
      test('Error: knownSize too large (exceeds buffer) throws RangeError',
          testReadNestedKnownSizeTooLarge);
      test('Error: knownSize exceeds buffer throws RangeError',
          testReadNestedKnownSizeExceedsBuffer);
      test('Error: negative knownSize throws BincodeException',
          testReadNestedKnownSizeNegative);
      test('Error: knownSize zero throws RangeError',
          testReadNestedKnownSizeZero);
    });
    group('readOptionNestedObjectWithKnownSize<TestFixedStructTwo>', () {
      test('Success case: Some', testReadOptionNestedKnownSizeSome);
      test('Success case: None', testReadOptionNestedKnownSizeNone);
      test('Error: Invalid tag', testReadOptionNestedKnownSizeInvalidTag);
      test('Error: Insufficient data after tag=1 throws RangeError',
          testReadOptionNestedKnownSizeInsufficientData);
      test('Error: Incorrect knownSize (too small) throws RangeError',
          testReadOptionNestedKnownSizeIncorrectKnownSize);
      test('Error: Negative knownSize throws BincodeException',
          testReadOptionNestedKnownSizeNegativeKnownSize);
    });
  });
}
