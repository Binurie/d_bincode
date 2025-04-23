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

import 'dart:convert';
import 'dart:typed_data';

import 'package:d_bincode/d_bincode.dart';

/// Benchmark Performance Disclaimer: The provided benchmark figures reflect
/// performance under specific, controlled test conditions. Actual results
/// in deployment may differ substantially due to variations in hardware
/// specifications, operating system, Dart runtime version, input data
/// characteristics, concurrency levels, and overall system load. These
/// benchmarks are intended for comparative insight and do not represent a
/// performance guarantee for any particular application. Users are advised
/// to conduct their own benchmarks relevant to their specific operational
/// context and requirements.

// ======================================
//  Serialization Benchmark (×5,000,000)
// ======================================

// >>> Bincode
// Serialize                Total: 6949.34ms   Avg:    1.39µs
// Deserialize              Total: 8864.11ms   Avg:    1.77µs
//   Size: 518 bytes

// >>> JSON
// Round‑trip               Total: 145482.86ms   Avg:   29.10µs
//   Size: 1,420 bytes

// >>> Speedups & Savings
//   Serialize speedup:     20.93×
//   Deserialize speedup:   16.41×
//   Size ratio (JSON/B):   2.74×
//   Saved bytes:           902 (63.5% smaller)
// --------------------------------------

class NestedData implements BincodeCodable {
  int nestedId = 0;
  String nestedName = "Default Nested";

  NestedData();
  NestedData.create(this.nestedId, this.nestedName);

  Map<String, dynamic> toJson() => {
        'nestedId': nestedId,
        'nestedName': nestedName,
      };

  factory NestedData.fromJson(Map<String, dynamic> json) {
    return NestedData.create(
      json['nestedId'] as int,
      json['nestedName'] as String,
    );
  }

  @override
  String toString() {
    return 'NestedData(id: $nestedId, name: "$nestedName")';
  }

  @override
  @pragma('vm:prefer-inline')
  void decode(BincodeReader r) {
    nestedId = r.readI32();
    nestedName = r.readString();
  }

  @override
  @pragma('vm:prefer-inline')
  void encode(BincodeWriter w) {
    w.writeI32(nestedId);
    w.writeString(nestedName);
  }
}

class FixedStruct implements BincodeCodable {
  int valueA = 0;
  double valueB = 0.0;
  bool flagC = false;

  FixedStruct();
  FixedStruct.create(this.valueA, this.valueB, this.flagC);

  Map<String, dynamic> toJson() => {
        'valueA': valueA,
        'valueB': valueB,
        'flagC': flagC,
      };

  factory FixedStruct.fromJson(Map<String, dynamic> json) {
    return FixedStruct.create(
      json['valueA'] as int,
      (json['valueB'] as num).toDouble(),
      json['flagC'] as bool,
    );
  }

  @override
  String toString() => 'Fixed(A:$valueA, B:$valueB, C:$flagC)';

  @override
  @pragma('vm:prefer-inline')
  void decode(BincodeReader r) {
    valueA = r.readI32();
    valueB = r.readF64();
    flagC = r.readBool();
  }

  @override
  @pragma('vm:prefer-inline')
  void encode(BincodeWriter w) {
    w.writeI32(valueA);
    w.writeF64(valueB);
    w.writeBool(flagC);
  }
}

class MyData implements BincodeCodable {
  int myU8 = 0;
  int myU16 = 0;
  int myU32 = 0;
  int myU64 = 0;
  int myI8 = 0;
  int myI16 = 0;
  int myI32 = 0;
  int myI64 = 0;
  double myF32 = 0.0;
  double myF64 = 0.0;
  bool myBool = false;
  int? myOptionU8;
  int? myOptionU16;
  int? myOptionU32;
  int? myOptionU64;
  int? myOptionI8;
  int? myOptionI16;
  int? myOptionI32;
  int? myOptionI64;
  double? myOptionF32;
  double? myOptionF64;
  bool? myOptionBool;
  String myString = "";
  String myFixedString = "";
  String myCleanFixedString = "";
  String? myOptionString;
  String? myOptionFixedString;
  String? myCleanOptionFixedString;
  Float32List? myOptionF32Triple;
  List<int> myGenericList = [];
  Map<String, bool> myGenericMap = {};
  List<int> myInt8List = [];
  List<int> myInt16List = [];
  List<int> myInt32List = [];
  List<int> myInt64List = [];
  List<int> myUint8List = [];
  List<int> myUint16List = [];
  List<int> myUint32List = [];
  List<int> myUint64List = [];
  List<double> myFloat32List = [];
  List<double> myFloat64List = [];
  NestedData myNestedCollection = NestedData();
  NestedData? myOptionalNestedCollection;
  FixedStruct myFixedStructInstance = FixedStruct();
  FixedStruct? myOptionalFixedStructInstance;
  List<FixedStruct> myListOfFixedStructs = [];

  MyData();
  @override
  @pragma('vm:prefer-inline')
  void encode(BincodeWriter writer) {
    writer.writeU8(myU8);
    writer.writeU16(myU16);
    writer.writeU32(myU32);
    writer.writeU64(myU64);
    writer.writeI8(myI8);
    writer.writeI16(myI16);
    writer.writeI32(myI32);
    writer.writeI64(myI64);
    writer.writeF32(myF32);
    writer.writeF64(myF64);
    writer.writeBool(myBool);
    writer.writeOptionU8(myOptionU8);
    writer.writeOptionU16(myOptionU16);
    writer.writeOptionU32(myOptionU32);
    writer.writeOptionU64(myOptionU64);
    writer.writeOptionI8(myOptionI8);
    writer.writeOptionI16(myOptionI16);
    writer.writeOptionI32(myOptionI32);
    writer.writeOptionI64(myOptionI64);
    writer.writeOptionF32(myOptionF32);
    writer.writeOptionF64(myOptionF64);
    writer.writeOptionBool(myOptionBool);
    writer.writeString(myString);
    writer.writeFixedString(myFixedString, 32);
    writer.writeFixedString(myCleanFixedString, 16);
    writer.writeOptionString(myOptionString);
    writer.writeOptionFixedString(myOptionFixedString, 20);
    writer.writeOptionFixedString(myCleanOptionFixedString, 24);
    writer.writeList<int>(myGenericList, (value) => writer.writeU32(value));
    writer.writeMap<String, bool>(myGenericMap,
        (key) => writer.writeString(key), (value) => writer.writeBool(value));
    writer.writeInt8List(myInt8List);
    writer.writeInt16List(myInt16List);
    writer.writeInt32List(myInt32List);
    writer.writeInt64List(myInt64List);
    writer.writeUint8List(myUint8List is Uint8List
        ? myUint8List as Uint8List
        : Uint8List.fromList(myUint8List));
    writer.writeUint16List(myUint16List);
    writer.writeUint32List(myUint32List);
    writer.writeUint64List(myUint64List);
    writer.writeFloat32List(myFloat32List is Float32List
        ? myFloat32List as Float32List
        : Float32List.fromList(myFloat32List));
    writer.writeFloat64List(myFloat64List is Float64List
        ? myFloat64List as Float64List
        : Float64List.fromList(myFloat64List));
    writer.writeNestedValueForCollection(myNestedCollection);
    writer.writeOptionNestedValueForCollection(myOptionalNestedCollection);
    writer.writeNestedValueForFixed(myFixedStructInstance);
    writer.writeOptionNestedValueForFixed(myOptionalFixedStructInstance);
    writer.writeList<FixedStruct>(myListOfFixedStructs, (item) {
      writer.writeNestedValueForFixed(item);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  void decode(BincodeReader reader) {
    myU8 = reader.readU8();
    myU16 = reader.readU16();
    myU32 = reader.readU32();
    myU64 = reader.readU64();
    myI8 = reader.readI8();
    myI16 = reader.readI16();
    myI32 = reader.readI32();
    myI64 = reader.readI64();
    myF32 = reader.readF32();
    myF64 = reader.readF64();
    myBool = reader.readBool();
    myOptionU8 = reader.readOptionU8();
    myOptionU16 = reader.readOptionU16();
    myOptionU32 = reader.readOptionU32();
    myOptionU64 = reader.readOptionU64();
    myOptionI8 = reader.readOptionI8();
    myOptionI16 = reader.readOptionI16();
    myOptionI32 = reader.readOptionI32();
    myOptionI64 = reader.readOptionI64();
    myOptionF32 = reader.readOptionF32();
    myOptionF64 = reader.readOptionF64();
    myOptionBool = reader.readOptionBool();
    myString = reader.readString();
    myFixedString = reader.readFixedString(32);
    myCleanFixedString = reader.readCleanFixedString(16);
    myOptionString = reader.readOptionString();
    myOptionFixedString = reader.readOptionFixedString(20);
    myCleanOptionFixedString = reader.readCleanOptionFixedString(24);
    myGenericList = reader.readList<int>(() => reader.readU32());
    myGenericMap = reader.readMap<String, bool>(
        () => reader.readString(), () => reader.readBool());
    myInt8List = reader.readInt8List();
    myInt16List = reader.readInt16List();
    myInt32List = reader.readInt32List();
    myInt64List = reader.readInt64List();
    myUint8List = reader.readUint8List();
    myUint16List = reader.readUint16List();
    myUint32List = reader.readUint32List();
    myUint64List = reader.readUint64List();
    myFloat32List = reader.readFloat32List();
    myFloat64List = reader.readFloat64List();
    myNestedCollection =
        reader.readNestedObjectForCollection<NestedData>(NestedData());
    myOptionalNestedCollection = reader
        .readOptionNestedObjectForCollection<NestedData>(() => NestedData());
    myFixedStructInstance =
        reader.readNestedObjectForFixed<FixedStruct>(FixedStruct());
    myOptionalFixedStructInstance =
        reader.readOptionNestedObjectForFixed<FixedStruct>(() => FixedStruct());
    myListOfFixedStructs = reader.readList<FixedStruct>(() {
      return reader.readNestedObjectForFixed<FixedStruct>(FixedStruct());
    });
  }

  Map<String, dynamic> toJson() {
    return {
      'myU8': myU8,
      'myU16': myU16,
      'myU32': myU32,
      'myU64': myU64,
      'myI8': myI8,
      'myI16': myI16,
      'myI32': myI32,
      'myI64': myI64,
      'myF32': myF32,
      'myF64': myF64,
      'myBool': myBool,
      'myOptionU8': myOptionU8,
      'myOptionU16': myOptionU16,
      'myOptionU32': myOptionU32,
      'myOptionU64': myOptionU64,
      'myOptionI8': myOptionI8,
      'myOptionI16': myOptionI16,
      'myOptionI32': myOptionI32,
      'myOptionI64': myOptionI64,
      'myOptionF32': myOptionF32,
      'myOptionF64': myOptionF64,
      'myOptionBool': myOptionBool,
      'myString': myString,
      'myFixedString': myFixedString,
      'myCleanFixedString': myCleanFixedString,
      'myOptionString': myOptionString,
      'myOptionFixedString': myOptionFixedString,
      'myCleanOptionFixedString': myCleanOptionFixedString,
      'myOptionF32Triple': myOptionF32Triple?.toList(),
      'myGenericList': myGenericList,
      'myGenericMap': myGenericMap,
      'myInt8List': myInt8List,
      'myInt16List': myInt16List,
      'myInt32List': myInt32List,
      'myInt64List': myInt64List,
      'myUint8List': myUint8List.toList(),
      'myUint16List': myUint16List,
      'myUint32List': myUint32List,
      'myUint64List': myUint64List,
      'myFloat32List': myFloat32List.toList(),
      'myFloat64List': myFloat64List.toList(),
      'myNestedCollection': myNestedCollection.toJson(),
      'myOptionalNestedCollection': myOptionalNestedCollection?.toJson(),
      'myFixedStructInstance': myFixedStructInstance.toJson(),
      'myOptionalFixedStructInstance': myOptionalFixedStructInstance?.toJson(),
      'myListOfFixedStructs':
          myListOfFixedStructs.map((e) => e.toJson()).toList(),
    };
  }

  factory MyData.fromJson(Map<String, dynamic> json) {
    final data = MyData();

    data.myU8 = json['myU8'] as int;
    data.myU16 = json['myU16'] as int;
    data.myU32 = json['myU32'] as int;
    data.myU64 = json['myU64'] as int;
    data.myI8 = json['myI8'] as int;
    data.myI16 = json['myI16'] as int;
    data.myI32 = json['myI32'] as int;
    data.myI64 = json['myI64'] as int;
    data.myF32 = (json['myF32'] as num).toDouble();
    data.myF64 = (json['myF64'] as num).toDouble();
    data.myBool = json['myBool'] as bool;
    data.myOptionU8 = json['myOptionU8'] as int?;
    data.myOptionU16 = json['myOptionU16'] as int?;
    data.myOptionU32 = json['myOptionU32'] as int?;
    data.myOptionU64 = json['myOptionU64'] as int?;
    data.myOptionI8 = json['myOptionI8'] as int?;
    data.myOptionI16 = json['myOptionI16'] as int?;
    data.myOptionI32 = json['myOptionI32'] as int?;
    data.myOptionI64 = json['myOptionI64'] as int?;
    data.myOptionF32 = (json['myOptionF32'] as num?)?.toDouble();
    data.myOptionF64 = (json['myOptionF64'] as num?)?.toDouble();
    data.myOptionBool = json['myOptionBool'] as bool?;
    data.myString = json['myString'] as String;
    data.myFixedString = json['myFixedString'] as String;
    data.myCleanFixedString = json['myCleanFixedString'] as String;
    data.myOptionString = json['myOptionString'] as String?;
    data.myOptionFixedString = json['myOptionFixedString'] as String?;
    data.myCleanOptionFixedString = json['myCleanOptionFixedString'] as String?;
    final f32TripleList = _convertTypedList<double>(json['myOptionF32Triple']);
    data.myOptionF32Triple =
        f32TripleList != null ? Float32List.fromList(f32TripleList) : null;
    data.myGenericList = _convertTypedList<int>(json['myGenericList']) ?? [];
    data.myGenericMap = (json['myGenericMap'] as Map<String, dynamic>?)
            ?.map((key, value) => MapEntry(key, value as bool)) ??
        {};
    data.myInt8List = _convertTypedList<int>(json['myInt8List']) ?? [];
    data.myInt16List = _convertTypedList<int>(json['myInt16List']) ?? [];
    data.myInt32List = _convertTypedList<int>(json['myInt32List']) ?? [];
    data.myInt64List = _convertTypedList<int>(json['myInt64List']) ?? [];
    data.myUint8List =
        Uint8List.fromList(_convertTypedList<int>(json['myUint8List']) ?? []);
    data.myUint16List = _convertTypedList<int>(json['myUint16List']) ?? [];
    data.myUint32List = _convertTypedList<int>(json['myUint32List']) ?? [];
    data.myUint64List = _convertTypedList<int>(json['myUint64List']) ?? [];
    data.myFloat32List = Float32List.fromList(
        _convertTypedList<double>(json['myFloat32List']) ?? []);
    data.myFloat64List = Float64List.fromList(
        _convertTypedList<double>(json['myFloat64List']) ?? []);
    if (json['myNestedCollection'] != null) {
      data.myNestedCollection = NestedData.fromJson(
          json['myNestedCollection'] as Map<String, dynamic>);
    }
    if (json['myOptionalNestedCollection'] != null) {
      data.myOptionalNestedCollection = NestedData.fromJson(
          json['myOptionalNestedCollection'] as Map<String, dynamic>);
    }
    if (json['myFixedStructInstance'] != null) {
      data.myFixedStructInstance = FixedStruct.fromJson(
          json['myFixedStructInstance'] as Map<String, dynamic>);
    }
    if (json['myOptionalFixedStructInstance'] != null) {
      data.myOptionalFixedStructInstance = FixedStruct.fromJson(
          json['myOptionalFixedStructInstance'] as Map<String, dynamic>);
    }
    if (json['myListOfFixedStructs'] != null) {
      data.myListOfFixedStructs = (json['myListOfFixedStructs'] as List)
          .map((item) => FixedStruct.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return data;
  }

  void reset() {
    myU8 = 0;
    myU16 = 0;
    myU32 = 0;
    myU64 = 0;
    myI8 = 0;
    myI16 = 0;
    myI32 = 0;
    myI64 = 0;
    myF32 = 0.0;
    myF64 = 0.0;
    myBool = false;
    myOptionU8 = null;
    myOptionI16 = null;
    myOptionF64 = null;
    myOptionBool = null;
    myString = '';
    myFixedString = '';
    myCleanFixedString = '';
    myOptionString = null;
    myOptionFixedString = null;
    myCleanOptionFixedString = null;
    myOptionF32Triple = null;
    myGenericList = const [];
    myGenericMap = const {};
    myInt8List = const [];
    myInt32List = Int32List(0);
    myUint8List = Uint8List(0);
    myFloat64List = const [];
    myNestedCollection = NestedData.create(0, '');
    myOptionalNestedCollection = null;
    myFixedStructInstance = FixedStruct.create(0, 0.0, false);
    myOptionalFixedStructInstance = null;
    myListOfFixedStructs = const [];
  }

  @override
  String toString() {
    return """
MyData { ... }""";
  }

  bool isSemanticallyEqualTo(MyData other) {
    bool basicMatch = myU8 == other.myU8 &&
        myU16 == other.myU16 &&
        myU32 == other.myU32 &&
        myU64 == other.myU64 &&
        myI8 == other.myI8 &&
        myI16 == other.myI16 &&
        myI32 == other.myI32 &&
        myI64 == other.myI64 &&
        (myF32 - other.myF32).abs() < 1e-6 &&
        (myF64 - other.myF64).abs() < 1e-9 &&
        myBool == other.myBool &&
        myOptionU8 == other.myOptionU8 &&
        myOptionI16 == other.myOptionI16 &&
        myOptionF64 == other.myOptionF64 &&
        myOptionBool == other.myOptionBool &&
        myString == other.myString &&
        myOptionString == other.myOptionString &&
        myOptionFixedString == other.myOptionFixedString;
    bool collectionMatch = myGenericList.length == other.myGenericList.length &&
        (myGenericList.isEmpty || myGenericList[0] == other.myGenericList[0]) &&
        myGenericMap.length == other.myGenericMap.length &&
        (myGenericMap.isEmpty ||
            myGenericMap['enabled'] == other.myGenericMap['enabled']) &&
        myUint8List.length == other.myUint8List.length &&
        (myUint8List.isEmpty || myUint8List[0] == other.myUint8List[0]) &&
        myNestedCollection.nestedId == other.myNestedCollection.nestedId &&
        myNestedCollection.nestedName == other.myNestedCollection.nestedName &&
        myFixedStructInstance.valueA == other.myFixedStructInstance.valueA &&
        myListOfFixedStructs.length == other.myListOfFixedStructs.length &&
        (myListOfFixedStructs.isEmpty ||
            myListOfFixedStructs[0].valueA ==
                other.myListOfFixedStructs[0].valueA);
    return basicMatch && collectionMatch;
  }
}

String _fmtInt(int n) => n
    .toString()
    .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

void runBenchmark({int iterations = 50000}) {
  if (iterations <= 0) {
    print("Iterations must be positive.");
    return;
  }

  final title = ' Serialization Benchmark (×${_fmtInt(iterations)}) ';
  print('\n${'=' * title.length}');
  print(title);
  print('${'=' * title.length}\n');

  final original = MyData()
    ..myU8 = 255
    ..myU16 = 65535
    ..myU32 = 0xFFFFFFFF
    ..myU64 = 0xFFFFFFFFFFFFFFFF
    ..myI8 = -128
    ..myI16 = -32768
    ..myI32 = -123456
    ..myI64 = -0x8000000000000000
    ..myF32 = -1.2345e-10
    ..myF64 = 3.1415926535
    ..myBool = true
    ..myOptionU8 = 100
    ..myOptionI16 = -30000
    ..myOptionF64 = null
    ..myOptionBool = false
    ..myString = "Hello Bincode!"
    ..myFixedString = "This will be truncated or padded"
    ..myCleanFixedString = "Nulls\x00Padded\x00"
    ..myOptionString = "I might be here"
    ..myOptionFixedString = null
    ..myCleanOptionFixedString = "Clean\x00Optional\x00Fixed"
    ..myOptionF32Triple = Float32List.fromList([1.0, 2.5, -3.0])
    ..myGenericList = [10, 20, 30]
    ..myGenericMap = {"enabled": true, "visible": false}
    ..myInt8List = [-1, 0, 1]
    ..myInt32List = Int32List.fromList([-1, 0, 1, 1000])
    ..myUint8List = Uint8List.fromList([0xCA, 0xFE, 0xBA, 0xBE])
    ..myFloat64List = [1.1, 2.2, 3.3]
    ..myNestedCollection = NestedData.create(101, "Dynamic Nested")
    ..myOptionalNestedCollection =
        NestedData.create(102, "Optional Dynamic Present")
    ..myFixedStructInstance = FixedStruct.create(999, 1.618, true)
    ..myOptionalFixedStructInstance = FixedStruct.create(-1, -2.718, false)
    ..myListOfFixedStructs = [
      FixedStruct.create(201, 20.1, false),
      FixedStruct.create(202, 20.2, true),
      FixedStruct.create(203, 20.3, false),
    ];

  // — One‑shot encoding for size & buffer setup —
  final bincodeBytes = BincodeWriter.encode(original);
  final bincodeSize = bincodeBytes.length;
  final jsonString = jsonEncode(original.toJson());
  final jsonSize = utf8.encode(jsonString).length;

  // — Prepare writer/reader and pre‑reserve exact capacity —
  final writer = BincodeWriter(initialCapacity: bincodeSize);
  final measured = writer.measure(original);
  writer.reserve(measured);
  writer.reset();

  final reader = BincodeReader(Uint8List(bincodeSize));
  Uint8List buffer = Uint8List(bincodeSize);

  // ── Benchmark Bincode Serialization ─────────────────────────────
  final swBincodeSer = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    writer.reset();
    original.encode(writer);
  }
  swBincodeSer.stop();
  buffer = writer.toBytes();

  // ── Benchmark Bincode Deserialization ──────────────────────────
  final swBincodeDes = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    reader.copyFrom(buffer);
    MyData().decode(reader);
  }
  swBincodeDes.stop();

  // ── Benchmark JSON round‑trip ─────────────────────────────────
  final swJson = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    final tmp = jsonEncode(original.toJson());
    MyData.fromJson(jsonDecode(tmp) as Map<String, dynamic>);
  }
  swJson.stop();

  // ── Compute stats ─────────────────────────────────────────────
  final bSerUs = swBincodeSer.elapsedMicroseconds.toDouble();
  final bDesUs = swBincodeDes.elapsedMicroseconds.toDouble();
  final jTotalUs = swJson.elapsedMicroseconds.toDouble();

  final avgBSerUs = bSerUs / iterations;
  final avgBDesUs = bDesUs / iterations;
  final avgJUs = jTotalUs / iterations;

  final speedupSer = jTotalUs / bSerUs;
  final speedupDes = jTotalUs / bDesUs;
  final sizeRatio = jsonSize / bincodeSize;
  final savedPct = (1 - bincodeSize / jsonSize) * 100;

  void line(String label, double totalUs, double avgUs) {
    print('${label.padRight(25)}'
        'Total: ${(totalUs / 1000).toStringAsFixed(2).padLeft(7)}ms   '
        'Avg: ${avgUs.toStringAsFixed(2).padLeft(7)}µs');
  }

  print('>>> Bincode');
  line('Serialize', bSerUs, avgBSerUs);
  line('Deserialize', bDesUs, avgBDesUs);
  print('  Size: ${_fmtInt(bincodeSize)} bytes');

  print('\n>>> JSON');
  line('Round‑trip', jTotalUs, avgJUs);
  print('  Size: ${_fmtInt(jsonSize)} bytes');

  print('\n>>> Speedups & Savings');
  print('  Serialize speedup:     ${speedupSer.toStringAsFixed(2)}×');
  print('  Deserialize speedup:   ${speedupDes.toStringAsFixed(2)}×');
  print('  Size ratio (JSON/B):   ${sizeRatio.toStringAsFixed(2)}×');
  print('  Saved bytes:           ${_fmtInt(jsonSize - bincodeSize)} '
      '(${savedPct.toStringAsFixed(1)}% smaller)');

  print('-' * title.length);
}

void main() async {
  print("--- Running Original Bincode Verification ---");

  final originalData = MyData()
    ..myU8 = 255
    ..myU16 = 65535
    ..myU32 = 0xFFFFFFFF
    ..myU64 = 0xFFFFFFFFFFFFFFFF
    ..myI8 = -128
    ..myI16 = -32768
    ..myI32 = -123456
    ..myI64 = -0x8000000000000000
    ..myF32 = -1.2345e-10
    ..myF64 = 3.1415926535
    ..myBool = true
    ..myOptionU8 = 100
    ..myOptionI16 = -30000
    ..myOptionF64 = null
    ..myOptionBool = false
    ..myString = "Hello Bincode!"
    ..myFixedString = "This will be truncated or padded"
    ..myCleanFixedString = "Nulls\x00Padded\x00"
    ..myOptionString = "I might be here"
    ..myOptionFixedString = null
    ..myCleanOptionFixedString = "Clean\x00Optional\x00Fixed"
    ..myOptionF32Triple = Float32List.fromList([1.0, 2.5, -3.0])
    ..myGenericList = [10, 20, 30]
    ..myGenericMap = {"enabled": true, "visible": false}
    ..myInt8List = [-1, 0, 1]
    ..myInt32List = Int32List.fromList([-1, 0, 1, 1000])
    ..myUint8List = Uint8List.fromList([0xCA, 0xFE, 0xBA, 0xBE])
    ..myFloat64List = [1.1, 2.2, 3.3]
    ..myNestedCollection = NestedData.create(101, "Dynamic Nested")
    ..myOptionalNestedCollection =
        NestedData.create(102, "Optional Dynamic Present")
    ..myFixedStructInstance = FixedStruct.create(999, 1.618, true)
    ..myOptionalFixedStructInstance = FixedStruct.create(-1, -2.718, false)
    ..myListOfFixedStructs = [
      FixedStruct.create(201, 20.1, false),
      FixedStruct.create(202, 20.2, true),
      FixedStruct.create(203, 20.3, false),
    ];

  final writer = BincodeWriter();
  originalData.encode(writer);
  final Uint8List bincodeBytes = writer.toBytes();
  print("\nOriginal Bincode Serialized ${bincodeBytes.length} bytes");

  final reader = BincodeReader(bincodeBytes);
  final decodedData = MyData()..decode(reader);

  try {
    assert(decodedData.myU8 == originalData.myU8);
    assert(decodedData.myU16 == originalData.myU16);
    assert(decodedData.myU32 == originalData.myU32);
    assert(decodedData.myU64 == originalData.myU64);
    assert(decodedData.myI8 == originalData.myI8);
    assert(decodedData.myI16 == originalData.myI16);
    assert(decodedData.myI32 == originalData.myI32);
    assert(decodedData.myI64 == originalData.myI64);
    assert((decodedData.myF32 - originalData.myF32).abs() < 1e-15);
    assert((decodedData.myF64 - originalData.myF64).abs() < 1e-9);
    assert(decodedData.myBool == originalData.myBool);
    assert(decodedData.myOptionU8 == originalData.myOptionU8);
    assert(decodedData.myOptionI16 == originalData.myOptionI16);
    assert(decodedData.myOptionF64 == originalData.myOptionF64);
    assert(decodedData.myOptionBool == originalData.myOptionBool);
    assert(decodedData.myString == originalData.myString);
    assert(decodedData.myFixedString
        .startsWith("This will be truncated or padded"));
    assert(decodedData.myCleanFixedString == "NullsPadded");
    assert(decodedData.myOptionString == originalData.myOptionString);
    assert(decodedData.myOptionFixedString == originalData.myOptionFixedString);
    assert(decodedData.myCleanOptionFixedString == "CleanOptionalFixed");
    assert(decodedData.myGenericList.length == 3 &&
        decodedData.myGenericList[1] == 20);
    assert(decodedData.myGenericMap["enabled"] == true &&
        decodedData.myGenericMap["visible"] == false);
    assert(
        decodedData.myInt8List.length == 3 && decodedData.myInt8List[0] == -1);
    assert(decodedData.myInt32List.length == 4 &&
        decodedData.myInt32List[3] == 1000);
    assert(decodedData.myUint8List.length == 4 &&
        decodedData.myUint8List[1] == 0xFE);
    assert(decodedData.myFloat64List.length == 3 &&
        (decodedData.myFloat64List[1] - 2.2).abs() < 1e-9);
    assert(decodedData.myNestedCollection.nestedId == 101 &&
        decodedData.myNestedCollection.nestedName == "Dynamic Nested");
    assert(decodedData.myOptionalNestedCollection != null);
    assert(decodedData.myOptionalNestedCollection!.nestedId == 102 &&
        decodedData.myOptionalNestedCollection!.nestedName ==
            "Optional Dynamic Present");
    assert(decodedData.myFixedStructInstance.valueA == 999);
    assert(decodedData.myFixedStructInstance.valueB == 1.618);
    assert(decodedData.myFixedStructInstance.flagC == true);
    assert(decodedData.myOptionalFixedStructInstance != null);
    assert(decodedData.myOptionalFixedStructInstance!.valueA == -1);
    assert(decodedData.myOptionalFixedStructInstance!.valueB == -2.718);
    assert(decodedData.myOptionalFixedStructInstance!.flagC == false);
    assert(decodedData.myListOfFixedStructs.length == 3);
    assert(decodedData.myListOfFixedStructs[0].valueA == 201 &&
        decodedData.myListOfFixedStructs[0].flagC == false);
    assert(decodedData.myListOfFixedStructs[1].valueA == 202 &&
        decodedData.myListOfFixedStructs[1].flagC == true);
    assert(decodedData.myListOfFixedStructs[2].valueA == 203 &&
        decodedData.myListOfFixedStructs[2].flagC == false);
    print("\nOriginal Bincode Verification successful!");
  } catch (e, s) {
    print("\nOriginal Bincode Verification FAILED: $e\n$s");
  }

  print("\n=========================================");

  runBenchmark(iterations: 5000000);
}

// Helper as Json is not so powerful :)
List<T>? _convertTypedList<T>(dynamic list) {
  if (list == null) return null;
  if (list is List<T>) return list;
  if (list is List) {
    try {
      if (T == double) {
        return list.map((e) => (e as num).toDouble()).toList() as List<T>;
      } else if (T == int) {
        return list.map((e) => (e as num).toInt()).toList() as List<T>;
      } else {
        return List<T>.from(list.map((e) => e as T));
      }
    } catch (e) {
      print("Warning: Failed to convert list element during JSON parsing: $e");
      return null;
    }
  }
  return null;
}
