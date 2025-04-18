/*
#######################################################################
# DISCLAIMER: This benchmark is for illustrative and comparative use. #
# Results are approximate and depend on runtime conditions such as    #
# device hardware, Dart VM optimizations, system load, and compiler.  #
#                                                                     #
# Do NOT use this as a definitive performance guarantee. Always test  #
# and profile with your own data and environment for accurate results.#
#                                                                     #
# This package can be definitely optiomized much more and this is the # 
# state as is without any warranty.                                   #
#######################################################################
*/

import 'dart:convert';
import 'dart:typed_data';

import 'package:d_bincode/d_bincode.dart';

// --- Running Original Bincode Verification ---

// Original Bincode Serialized 531 bytes

// Original Bincode Verification successful!

// =========================================
// --- Starting Benchmark (Iterations: 500000) ---

// Benchmarking Bincode...
// Bincode Total Serialization Time:   1259.624 ms
// Bincode Average Serialization Time: 2.519 µs
// Bincode Total Deserialization Time: 1945.186 ms
// Bincode Average Deserialization Time:3.890 µs
// Bincode Serialized Size:            531 bytes
// Bincode Verification:               Successful
// Bincode Dummy Check:                255

// Benchmarking JSON...
// JSON Total Serialization Time:      9128.526 ms
// JSON Average Serialization Time:    18.257 µs
// JSON Total Deserialization Time:    6699.181 ms
// JSON Average Deserialization Time:  13.398 µs
// JSON Serialized Size:               1420 bytes
// JSON Verification:                  Successful
// JSON Dummy Check:                   255

// --- Benchmark Summary (Iterations: 500000) ---
// Serialization Speed: Bincode is ~7.25x faster (2.52 µs/op vs 18.26 µs/op)
// Deserialization Speed: Bincode is ~3.44x faster (3.89 µs/op vs 13.40 µs/op)
// Size Comparison:     Bincode is ~2.67x smaller
//    Bincode: 531 bytes
//    JSON:    1420 bytes
// ------------------------------------------

class NestedData implements BincodeCodable {
  int nestedId = 0;
  String nestedName = "Default Nested";

  NestedData();
  NestedData.create(this.nestedId, this.nestedName);

  @override
  Uint8List toBincode({bool unchecked = false, int initialCapacity = 128}) {
    final writer = BincodeWriter();
    writer.writeI32(nestedId);
    writer.writeString(nestedName);
    return writer.toBytes();
  }

  @override
  void fromBincode(Uint8List bytes, {bool unsafe = false}) {
    final reader = BincodeReader(bytes, unsafe: unsafe);
    nestedId = reader.readI32();
    nestedName = reader.readString();
  }

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
}

class FixedStruct implements BincodeCodable {
  int valueA = 0;
  double valueB = 0.0;
  bool flagC = false;

  FixedStruct();
  FixedStruct.create(this.valueA, this.valueB, this.flagC);

  @override
  Uint8List toBincode() {
    final writer = BincodeWriter();
    writer.writeI32(valueA);
    writer.writeF64(valueB);
    writer.writeBool(flagC);
    return writer.toBytes();
  }

  @override
  void fromBincode(Uint8List bytes, {bool unsafe = false}) {
    final reader = BincodeReader(bytes, unsafe: unsafe);
    valueA = reader.readI32();
    valueB = reader.readF64();
    flagC = reader.readBool();
  }

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
  Uint8List toBincode({bool unchecked = false, int initialCapacity = 1024}) {
    final writer =
        BincodeWriter(initialCapacity: initialCapacity, unchecked: unchecked);

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
    writer.writeOptionF32Triple(myOptionF32Triple);
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
    return writer.toBytes();
  }

  @override
  void fromBincode(Uint8List bytes, {bool unsafe = false}) {
    final reader = BincodeReader(bytes, unsafe: unsafe);

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
    myOptionF32Triple = reader.readOptionF32Triple();
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

    if (reader.remainingBytes() > 0 && !unsafe) {
      print(
          "Warning: ${reader.remainingBytes()} bytes remaining after decoding MyData");
    }
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

void runBenchmark({int iterations = 50000}) {
  if (iterations <= 0) {
    print("Iterations must be positive.");
    return;
  }
  print("--- Starting Benchmark (Iterations: $iterations) ---");

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

  Uint8List? bincodeBytes;
  String? jsonString;
  int bincodeSize = 0;
  int jsonSize = 0;
  MyData? dummyBincodeData;
  MyData? dummyJsonData;

  final stopwatch = Stopwatch();

  print("\nBenchmarking Bincode...");

  stopwatch.start();
  for (int i = 0; i < iterations; i++) {
    bincodeBytes = originalData.toBincode(unchecked: true);
  }
  stopwatch.stop();
  final bincodeSerializationTime = stopwatch.elapsedMicroseconds;
  bincodeSize = bincodeBytes?.length ?? 0;
  stopwatch.reset();

  int bincodeDeserializationTime = 0;
  if (bincodeBytes != null) {
    stopwatch.start();
    for (int i = 0; i < iterations; i++) {
      dummyBincodeData = MyData();
      dummyBincodeData.fromBincode(bincodeBytes, unsafe: true);
    }
    stopwatch.stop();
    bincodeDeserializationTime = stopwatch.elapsedMicroseconds;
  } else {
    print("Bincode serialization failed, skipping deserialization benchmark.");
  }
  stopwatch.reset();

  bool bincodeVerified = false;
  if (bincodeBytes != null) {
    final verifyDecoded = MyData();
    verifyDecoded.fromBincode(bincodeBytes, unsafe: true);
    bincodeVerified = originalData.isSemanticallyEqualTo(verifyDecoded);
  }

  final avgBincodeSerTime = bincodeSerializationTime / iterations;
  final avgBincodeDesTime = bincodeDeserializationTime / iterations;

  print(
      "Bincode Total Serialization Time:   ${(bincodeSerializationTime / 1000).toStringAsFixed(3)} ms");
  print(
      "Bincode Average Serialization Time: ${avgBincodeSerTime.toStringAsFixed(3)} µs");
  print(
      "Bincode Total Deserialization Time: ${(bincodeDeserializationTime / 1000).toStringAsFixed(3)} ms");
  print(
      "Bincode Average Deserialization Time:${avgBincodeDesTime.toStringAsFixed(3)} µs");
  print("Bincode Serialized Size:            $bincodeSize bytes");
  print(
      "Bincode Verification:               ${bincodeVerified ? 'Successful' : 'Failed'}");
  print("Bincode Dummy Check:                ${dummyBincodeData?.myU8}");

  print("\nBenchmarking JSON...");
  Map<String, dynamic>? jsonDataMap;

  stopwatch.start();
  for (int i = 0; i < iterations; i++) {
    jsonDataMap = originalData.toJson();
    jsonString = jsonEncode(jsonDataMap);
  }
  stopwatch.stop();
  final jsonSerializationTime = stopwatch.elapsedMicroseconds;
  jsonSize = jsonString != null ? utf8.encode(jsonString).length : 0;
  stopwatch.reset();

  int jsonDeserializationTime = 0;
  if (jsonString != null) {
    stopwatch.start();
    for (int i = 0; i < iterations; i++) {
      final decodedMap = jsonDecode(jsonString) as Map<String, dynamic>;

      dummyJsonData = MyData.fromJson(decodedMap);
    }
    stopwatch.stop();
    jsonDeserializationTime = stopwatch.elapsedMicroseconds;
  } else {
    print("JSON serialization failed, skipping deserialization benchmark.");
  }
  stopwatch.reset();

  bool jsonVerified = false;
  if (jsonString != null) {
    final decodedMap = jsonDecode(jsonString) as Map<String, dynamic>;
    final verifyDecoded = MyData.fromJson(decodedMap);
    jsonVerified = originalData.isSemanticallyEqualTo(verifyDecoded);
  }

  final avgJsonSerTime = jsonSerializationTime / iterations;
  final avgJsonDesTime = jsonDeserializationTime / iterations;

  print(
      "JSON Total Serialization Time:      ${(jsonSerializationTime / 1000).toStringAsFixed(3)} ms");
  print(
      "JSON Average Serialization Time:    ${avgJsonSerTime.toStringAsFixed(3)} µs");
  print(
      "JSON Total Deserialization Time:    ${(jsonDeserializationTime / 1000).toStringAsFixed(3)} ms");
  print(
      "JSON Average Deserialization Time:  ${avgJsonDesTime.toStringAsFixed(3)} µs");
  print("JSON Serialized Size:               $jsonSize bytes");
  print(
      "JSON Verification:                  ${jsonVerified ? 'Successful' : 'Failed'}");
  print("JSON Dummy Check:                   ${dummyJsonData?.myU8}");

  print("\n--- Benchmark Summary (Iterations: $iterations) ---");
  if (bincodeSerializationTime > 0 && jsonSerializationTime > 0) {
    print(
        "Serialization Speed: Bincode is ~${(jsonSerializationTime / bincodeSerializationTime).toStringAsFixed(2)}x faster "
        "(${avgBincodeSerTime.toStringAsFixed(2)} µs/op vs ${avgJsonSerTime.toStringAsFixed(2)} µs/op)");
  }
  if (bincodeDeserializationTime > 0 && jsonDeserializationTime > 0) {
    print(
        "Deserialization Speed: Bincode is ~${(jsonDeserializationTime / bincodeDeserializationTime).toStringAsFixed(2)}x faster "
        "(${avgBincodeDesTime.toStringAsFixed(2)} µs/op vs ${avgJsonDesTime.toStringAsFixed(2)} µs/op)");
  }
  if (bincodeSize > 0 && jsonSize > 0) {
    print(
        "Size Comparison:     Bincode is ~${(jsonSize / bincodeSize).toStringAsFixed(2)}x smaller");
    print("   Bincode: $bincodeSize bytes");
    print("   JSON:    $jsonSize bytes");
  }
  print("------------------------------------------");
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
  Uint8List bincodeBytes = originalData.toBincode();
  print("\nOriginal Bincode Serialized ${bincodeBytes.length} bytes");
  final decodedData = MyData();
  decodedData.fromBincode(bincodeBytes);
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
    assert(decodedData.myOptionF32Triple != null &&
        originalData.myOptionF32Triple != null);
    assert(decodedData.myOptionF32Triple!.length == 3);
    assert(decodedData.myOptionF32Triple![1] == 2.5);
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

  runBenchmark(iterations: 500000);
}

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
