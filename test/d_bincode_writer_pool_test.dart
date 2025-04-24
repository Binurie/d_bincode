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

import 'dart:async';
import 'dart:typed_data';

import 'package:d_bincode/d_bincode.dart';
import 'package:test/test.dart';

Uint8List getExpectedStringBytes(String value) {
  final tempWriter = BincodeWriter();
  tempWriter.writeString(value);
  return tempWriter.toBytes();
}

void testPoolDefaultConstructor() {
  final pool = BincodeWriterPool();
  expect(pool.maximumSize, equals(16));
  expect(pool.createdCount, equals(4));
  expect(pool.available, equals(4));
}

void testPoolCustomSizeConstructor() {
  final pool = BincodeWriterPool(initialSize: 2, maxSize: 5);
  expect(pool.maximumSize, equals(5));
  expect(pool.createdCount, equals(2));
  expect(pool.available, equals(2));
}

void testPoolZeroInitialSizeConstructor() {
  final pool = BincodeWriterPool(initialSize: 0, maxSize: 5);
  expect(pool.maximumSize, equals(5));
  expect(pool.createdCount, equals(0));
  expect(pool.available, equals(0));
}

void testPoolInvalidSizeConstructors() {
  expect(() => BincodeWriterPool(initialSize: -1), throwsArgumentError);
  expect(() => BincodeWriterPool(maxSize: 0), throwsArgumentError);
  expect(() => BincodeWriterPool(maxSize: -1), throwsArgumentError);
  expect(
      () => BincodeWriterPool(initialSize: 5, maxSize: 4), throwsArgumentError);
}

void testPoolUseAcquireReleaseFromInitial() {
  final pool = BincodeWriterPool(initialSize: 1, maxSize: 1);
  expect(pool.available, equals(1));
  expect(pool.createdCount, equals(1));
  final result = pool.use((writer) {
    expect(pool.available, equals(0));
    expect(pool.createdCount, equals(1));
    writer.writeI32(123);
    return 42;
  });
  expect(result, equals(42));
  expect(pool.available, equals(1));
  expect(pool.createdCount, equals(1));
}

void testPoolUseCreatesNewWriter() {
  final pool = BincodeWriterPool(initialSize: 0, maxSize: 1);
  expect(pool.available, equals(0));
  expect(pool.createdCount, equals(0));
  final result = pool.use((writer) {
    expect(pool.available, equals(0));
    expect(pool.createdCount, equals(1));
    writer.writeString('new');
    return 'ok';
  });
  expect(result, equals('ok'));
  expect(pool.available, equals(1));
  expect(pool.createdCount, equals(1));
}

void testPoolUseThrowsStateErrorAtMax() {
  final pool = BincodeWriterPool(initialSize: 1, maxSize: 1);
  pool.use((w) {
    expect(pool.available, equals(0));
    expect(
      () => pool.use((writer) => 0),
      throwsA(isA<StateError>().having(
          (e) => e.message, 'message', contains('reached maximum size'))),
    );
    expect(pool.available, equals(0));
    expect(pool.createdCount, equals(1));
  });
  expect(pool.available, equals(1));
  expect(pool.createdCount, equals(1));
}

void testPoolUseReleasesOnException() {
  final pool = BincodeWriterPool(initialSize: 1, maxSize: 1);
  expect(pool.available, equals(1));
  try {
    pool.use((writer) {
      expect(pool.available, equals(0));
      writer.writeI32(1);
      throw Exception('Test Error');
    });
  } catch (e) {
    expect(e, isA<Exception>());
  }
  expect(pool.available, equals(1));
  expect(pool.createdCount, equals(1));
}

void testPoolUseResetsState() {
  final pool = BincodeWriterPool(initialSize: 1, maxSize: 1);
  Uint8List? bytes1;
  Uint8List? bytes2;

  final expectedBytes1 = getExpectedStringBytes("InitialData");
  final expectedBytes2 = getExpectedStringBytes("SecondData");

  pool.use((writer) {
    writer.writeString("InitialData");
    bytes1 = writer.toBytes();
  });

  expect(bytes1, isNotNull);
  expect(bytes1, equals(expectedBytes1));
  expect(pool.available, equals(1));

  pool.use((writer) {
    writer.writeString("SecondData");
    bytes2 = writer.toBytes();
  });

  expect(bytes2, isNotNull);
  expect(bytes2, equals(expectedBytes2));
  expect(pool.available, equals(1));
}

void testPoolUseAsyncAcquireRelease() async {
  final pool = BincodeWriterPool(initialSize: 1, maxSize: 1);
  expect(pool.available, equals(1));
  final result = await pool.useAsync((writer) async {
    expect(pool.available, equals(0));
    await Future.delayed(Duration(milliseconds: 5));
    writer.writeString('async test');
    return 99;
  });
  expect(result, equals(99));
  expect(pool.available, equals(1));
  expect(pool.createdCount, equals(1));
}

void testPoolUseAsyncCreatesNewWriter() async {
  final pool = BincodeWriterPool(initialSize: 0, maxSize: 1);
  expect(pool.available, equals(0));
  expect(pool.createdCount, equals(0));
  final result = await pool.useAsync((writer) async {
    expect(pool.available, equals(0));
    expect(pool.createdCount, equals(1));
    writer.writeI32(1);
    await Future.delayed(Duration.zero);
    return 'async ok';
  });
  expect(result, equals('async ok'));
  expect(pool.available, equals(1));
  expect(pool.createdCount, equals(1));
}

void testPoolUseAsyncReleasesOnException() async {
  final pool = BincodeWriterPool(initialSize: 1, maxSize: 1);
  expect(pool.available, equals(1));
  try {
    await pool.useAsync((writer) async {
      expect(pool.available, equals(0));
      writer.writeI32(1);
      await Future.delayed(Duration.zero);
      throw Exception('Async Test Error');
    });
  } catch (e) {
    expect(e, isA<Exception>());
  }
  expect(pool.available, equals(1));
  expect(pool.createdCount, equals(1));
}

void testPoolUseAsyncThrowsStateErrorAtMax() async {
  final pool = BincodeWriterPool(initialSize: 1, maxSize: 1);
  final completer = Completer<void>();
  final future1 = pool.useAsync((w) async {
    await completer.future;
    return w;
  });

  await Future.delayed(Duration.zero);
  expect(pool.available, equals(0));

  await expectLater(
    () => pool.useAsync((writer) async => 0),
    throwsA(isA<StateError>()
        .having((e) => e.message, 'message', contains('reached maximum size'))),
  );
  completer.complete();
  await future1;
  expect(pool.available, equals(1));
  expect(pool.createdCount, equals(1));
}

void testPoolUseAsyncResetsState() async {
  final pool = BincodeWriterPool(initialSize: 1, maxSize: 1);
  Uint8List? bytes1;
  Uint8List? bytes2;

  final expectedBytes1 = getExpectedStringBytes("AsyncInitial");
  final expectedBytes2 = getExpectedStringBytes("AsyncSecond");

  await pool.useAsync((writer) async {
    writer.writeString("AsyncInitial");
    await Future.delayed(Duration.zero);
    bytes1 = writer.toBytes();
  });

  expect(bytes1, isNotNull);
  expect(bytes1, equals(expectedBytes1));
  expect(pool.available, equals(1));

  await pool.useAsync((writer) async {
    writer.writeString("AsyncSecond");
    await Future.delayed(Duration.zero);
    bytes2 = writer.toBytes();
  });

  expect(bytes2, isNotNull);
  expect(bytes2, equals(expectedBytes2));
  expect(pool.available, equals(1));
}

void testPoolPropertiesDuringMultipleUses() {
  final pool = BincodeWriterPool(initialSize: 2, maxSize: 3);
  expect(pool.available, equals(2));
  expect(pool.createdCount, equals(2));
  expect(pool.maximumSize, equals(3));
  int counter = 0;
  pool.use((w1) {
    counter++;
    expect(pool.available, equals(1));
    expect(pool.createdCount, equals(2));
    pool.use((w2) {
      counter++;
      expect(pool.available, equals(0));
      expect(pool.createdCount, equals(2));
      pool.use((w3) {
        counter++;
        expect(pool.available, equals(0));
        expect(pool.createdCount, equals(3));
      });
      expect(pool.available, equals(1));
      expect(pool.createdCount, equals(3));
    });
    expect(pool.available, equals(2));
    expect(pool.createdCount, equals(3));
  });
  expect(pool.available, equals(3));
  expect(pool.createdCount, equals(3));
  expect(counter, equals(3));
}

void testPoolCreatedCountDoesNotExceedMax() async {
  final pool = BincodeWriterPool(initialSize: 1, maxSize: 2);
  List<Completer<void>> completers = [];
  List<Future<void>> futures = [];

  for (int i = 0; i < pool.maximumSize; i++) {
    final completer = Completer<void>();
    completers.add(completer);
    futures.add(pool.useAsync((w) async {
      await completer.future;
    }));

    await Future.delayed(Duration.zero);
    expect(pool.createdCount, equals(i + 1),
        reason: "Count after acquiring ${i + 1}");
  }

  expect(pool.available, equals(0), reason: "Pool should be empty");
  expect(pool.createdCount, equals(pool.maximumSize),
      reason: "Count should be max");

  await expectLater(
      () => pool.useAsync((writer) async => 0), throwsA(isA<StateError>()),
      reason: "Acquiring beyond max should fail");

  expect(pool.createdCount, equals(pool.maximumSize),
      reason: "Count should still be max");

  for (var completer in completers) {
    completer.complete();
  }
  await Future.wait(futures);
  expect(pool.available, equals(pool.maximumSize));
  expect(pool.createdCount, equals(pool.maximumSize));
}

void main() {
  print('--- EXECUTING d_bincode_writer_pool_test.dart main ---');
  group('BincodeWriterPool Tests', () {
    test('Default constructor', testPoolDefaultConstructor);
    test('Custom size constructor', testPoolCustomSizeConstructor);
    test('Zero initial size constructor', testPoolZeroInitialSizeConstructor);
    test('Invalid size constructors', testPoolInvalidSizeConstructors);
    test('use acquires/releases from initial',
        testPoolUseAcquireReleaseFromInitial);
    test('use creates new writer', testPoolUseCreatesNewWriter);
    test('use throws StateError at max', testPoolUseThrowsStateErrorAtMax);
    test('use releases on exception', testPoolUseReleasesOnException);
    test('use resets state (indirect)', testPoolUseResetsState);
    test('useAsync acquires/releases', testPoolUseAsyncAcquireRelease);
    test('useAsync creates new writer', testPoolUseAsyncCreatesNewWriter);
    test('useAsync releases on exception', testPoolUseAsyncReleasesOnException);
    test('useAsync throws StateError at max',
        testPoolUseAsyncThrowsStateErrorAtMax);
    test('useAsync resets state (indirect)', testPoolUseAsyncResetsState);
    test('Properties reflect state during multiple uses',
        testPoolPropertiesDuringMultipleUses);
    test('createdCount does not exceed max size',
        testPoolCreatedCountDoesNotExceedMax);
  });
}
