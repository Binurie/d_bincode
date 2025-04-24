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

import 'package:d_bincode/d_bincode.dart';
import 'package:test/test.dart';

void testBitMaskDefaultConstructor() {
  final mask = BitMask();
  expect(mask.value, equals(0));
}

void testBitMaskValidValueConstructor() {
  final mask = BitMask(42);
  expect(mask.value, equals(42));
}

void testBitMaskInvalidValueConstructor() {
  expect(() => BitMask(-1), throwsArgumentError);
  expect(() => BitMask(256), throwsArgumentError);
}

void testBitMaskFromList() {
  expect(BitMask.fromList([]).value, equals(0));
  expect(BitMask.fromList([true]).value, equals(1));
  expect(BitMask.fromList([false, true]).value, equals(2));
  expect(BitMask.fromList([true, false, true]).value, equals(5));
  expect(
      BitMask.fromList([true, true, true, true, true, true, true, true]).value,
      equals(255));
  expect(
      BitMask.fromList([false, false, false, false, false, false, false, true])
          .value,
      equals(128));
}

void testBitMaskFromListShort() {
  final mask = BitMask.fromList([true, false, true]);
  expect(mask.value, equals(5));
  expect(mask.toList(),
      equals([true, false, true, false, false, false, false, false]));
}

void testBitMaskFromListTooLong() {
  expect(() => BitMask.fromList(List.filled(9, false)), throwsArgumentError);
}

void testBitMaskFromNamed() {
  expect(BitMask.fromNamed().value, equals(0));
  expect(BitMask.fromNamed(bit0: true).value, equals(1));
  expect(BitMask.fromNamed(bit7: true).value, equals(128));
  expect(BitMask.fromNamed(bit1: true, bit3: true).value, equals(10));
  expect(
      BitMask.fromNamed(
              bit0: true,
              bit1: true,
              bit2: true,
              bit3: true,
              bit4: true,
              bit5: true,
              bit6: true,
              bit7: true)
          .value,
      equals(255));
  expect(BitMask.fromNamed(bit2: true, bit5: true).value, equals(36));
}

void testBitMaskValueGetter() {
  final mask = BitMask(170);
  expect(mask.value, equals(170));
}

void testBitMaskValueSetter() {
  final mask = BitMask();
  mask.value = 85;
  expect(mask.value, equals(85));
}

void testBitMaskValueSetterInvalid() {
  final mask = BitMask();
  expect(() => mask.value = -1, throwsArgumentError);
  expect(() => mask.value = 256, throwsArgumentError);
}

void testBitMaskSetBit() {
  final mask = BitMask();
  mask.setBit(0, true);
  expect(mask.value, equals(1));
  mask.setBit(7, true);
  expect(mask.value, equals(129));
  mask.setBit(3, true);
  expect(mask.value, equals(137));
}

void testBitMaskClearBit() {
  final mask = BitMask(255);
  mask.setBit(0, false);
  expect(mask.value, equals(254));
  mask.setBit(7, false);
  expect(mask.value, equals(126));
  mask.setBit(3, false);
  expect(mask.value, equals(118));
}

void testBitMaskSetBitIdempotent() {
  final mask = BitMask(10);
  mask.setBit(1, true);
  expect(mask.value, equals(10));
  mask.setBit(0, false);
  expect(mask.value, equals(10));
  mask.setBit(1, false);
  expect(mask.value, equals(8));
  mask.setBit(0, true);
  expect(mask.value, equals(9));
}

void testBitMaskGetBit() {
  final mask = BitMask(42);
  expect(mask.getBit(0), isFalse);
  expect(mask.getBit(1), isTrue);
  expect(mask.getBit(2), isFalse);
  expect(mask.getBit(3), isTrue);
  expect(mask.getBit(4), isFalse);
  expect(mask.getBit(5), isTrue);
  expect(mask.getBit(6), isFalse);
  expect(mask.getBit(7), isFalse);
}

void testBitMaskSetBitRangeError() {
  final mask = BitMask();
  expect(() => mask.setBit(-1, true), throwsRangeError);
  expect(() => mask.setBit(8, true), throwsRangeError);
}

void testBitMaskGetBitRangeError() {
  final mask = BitMask();
  expect(() => mask.getBit(-1), throwsRangeError);
  expect(() => mask.getBit(8), throwsRangeError);
}

void testBitMaskToList() {
  expect(BitMask(0).toList(), equals(List.filled(8, false)));
  expect(BitMask(255).toList(), equals(List.filled(8, true)));
  expect(BitMask(42).toList(),
      equals([false, true, false, true, false, true, false, false]));
  expect(BitMask(137).toList(),
      equals([true, false, false, true, false, false, false, true]));
}

void testBitMaskToString() {
  expect(BitMask(0).toString(), equals('BitMask(value: 0, bits: 0b00000000)'));
  expect(
      BitMask(42).toString(), equals('BitMask(value: 42, bits: 0b00101010)'));
  expect(
      BitMask(255).toString(), equals('BitMask(value: 255, bits: 0b11111111)'));
}

void testBitMaskEquality() {
  final mask1a = BitMask(42);
  final mask1b = BitMask(42);
  final mask2 = BitMask(85);
  expect(mask1a == mask1b, isTrue);
  expect(mask1a == mask2, isFalse);
  expect(mask1a == mask1a, isTrue);
  expect(mask1a == Object(), isFalse);
}

void testBitMaskHashCode() {
  final mask1a = BitMask(42);
  final mask1b = BitMask(42);
  final mask2 = BitMask(85);
  expect(mask1a.hashCode, equals(mask1b.hashCode));
  expect(mask1a.hashCode, isNot(equals(mask2.hashCode)));
}

void main() {
  print('--- EXECUTING bit_mask_test.dart main ---');
  group('BitMask Tests', () {
    test('Default constructor', testBitMaskDefaultConstructor);
    test('Constructor with valid value', testBitMaskValidValueConstructor);
    test('Constructor with invalid value', testBitMaskInvalidValueConstructor);
    test('fromList', testBitMaskFromList);
    test('fromList handles short list', testBitMaskFromListShort);
    test('fromList throws on long list', testBitMaskFromListTooLong);
    test('fromNamed', testBitMaskFromNamed);
    test('value getter', testBitMaskValueGetter);
    test('value setter', testBitMaskValueSetter);
    test('value setter invalid', testBitMaskValueSetterInvalid);
    test('setBit', testBitMaskSetBit);
    test('clearBit', testBitMaskClearBit);
    test('setBit idempotent', testBitMaskSetBitIdempotent);
    test('getBit', testBitMaskGetBit);
    test('setBit range error', testBitMaskSetBitRangeError);
    test('getBit range error', testBitMaskGetBitRangeError);
    test('toList', testBitMaskToList);
    test('toString', testBitMaskToString);
    test('Equality', testBitMaskEquality);
    test('hashCode', testBitMaskHashCode);
  });
}
