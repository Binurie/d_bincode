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

class NestedData implements BincodeCodable {
  int nestedId = 0;
  String nestedName = "Default Nested";

  NestedData();
  NestedData.create(this.nestedId, this.nestedName);

  @override
  String toString() {
    return 'NestedData(id: $nestedId, name: "$nestedName")';
  }

  @override
  void decode(BincodeReader r) {
    nestedId = r.readI32();
    nestedName = r.readString();
  }

  @override
  void encode(BincodeWriter w) {
    w.writeI32(nestedId); // i32
    w.writeString(nestedName); // String (variable length!)
  }
}

class FixedStruct implements BincodeCodable {
  int valueA = 0; // Example: i32 (4 bytes)
  double valueB = 0.0; // Example: f64 (8 bytes)
  bool flagC = false; // Example: bool (1 byte)

  FixedStruct();
  FixedStruct.create(this.valueA, this.valueB, this.flagC);

  @override
  String toString() => 'Fixed(A:$valueA, B:$valueB, C:$flagC)';

  @override
  void decode(BincodeReader reader) {
    valueA = reader.readI32();
    valueB = reader.readF64();
    flagC = reader.readBool();
  }

  @override
  void encode(BincodeWriter writer) {
    writer.writeI32(valueA);
    writer.writeF64(valueB);
    writer.writeBool(flagC);
  }
}

// --- Main Data Class (Comprehensive Example) ---
class MyData implements BincodeCodable {
  // --- Primitives ---
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

  // --- Optional Primitives ---
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

  // --- Strings ---
  String myString = "";
  String myFixedString = "";
  String myCleanFixedString = "";
  String? myOptionString;
  String? myOptionFixedString;
  String? myCleanOptionFixedString;

  // --- Specific Optional Structures ---
  Float32List? myOptionF32Triple;

  // --- Generic Collections ---
  List<int> myGenericList = [];
  Map<String, bool> myGenericMap = {};

  // --- Specialized Numeric Lists ---
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

  // --- Nested Objects ---
  // Example using ForCollection (variable size due to NestedData's string)
  NestedData myNestedCollection = NestedData();
  NestedData? myOptionalNestedCollection;

  // Example using ForFixed (FixedStruct has a truly fixed size: 13 bytes, no length will be added)
  FixedStruct myFixedStructInstance = FixedStruct();
  FixedStruct? myOptionalFixedStructInstance;

  // Example: List of fixed-size objects
  List<FixedStruct> myListOfFixedStructs = [];

  // --- BincodeCodable Implementation ---

  @override
  void encode(BincodeWriter writer) {
    // --- Write Primitives ---
    writer.writeU8(myU8); // u8
    writer.writeU16(myU16); // u16
    writer.writeU32(myU32); // u32
    writer.writeU64(myU64); // u64
    writer.writeI8(myI8); // i8
    writer.writeI16(myI16); // i16
    writer.writeI32(myI32); // i32
    writer.writeI64(myI64); // i64
    writer.writeF32(myF32); // f32
    writer.writeF64(myF64); // f64
    writer.writeBool(myBool); // bool

    // --- Write Optional Primitives ---
    writer.writeOptionU8(myOptionU8); // Option<u8>
    writer.writeOptionU16(myOptionU16); // Option<u16>
    writer.writeOptionU32(myOptionU32); // Option<u32>
    writer.writeOptionU64(myOptionU64); // Option<u64>
    writer.writeOptionI8(myOptionI8); // Option<i8>
    writer.writeOptionI16(myOptionI16); // Option<i16>
    writer.writeOptionI32(myOptionI32); // Option<i32>
    writer.writeOptionI64(myOptionI64); // Option<i64>
    writer.writeOptionF32(myOptionF32); // Option<f32>
    writer.writeOptionF64(myOptionF64); // Option<f64>
    writer.writeOptionBool(myOptionBool); // Option<bool>

    // --- Write Strings ---
    writer.writeString(myString); // String
    writer.writeFixedString(myFixedString, 32); // [u8; 32]
    writer.writeFixedString(myCleanFixedString, 16); // [u8; 16]
    writer.writeOptionString(myOptionString); // Option<String>
    writer.writeOptionFixedString(myOptionFixedString, 20); // Option<[u8; 20]>
    writer.writeOptionFixedString(
        myCleanOptionFixedString, 24); // Option<[u8; 24]>

    // --- Write Generic Collections ---
    writer.writeList<int>(
        myGenericList, (value) => writer.writeU32(value)); // Vec<T>
    writer.writeMap<String, bool>(
        // HashMap<T, E>
        myGenericMap,
        (key) => writer.writeString(key),
        (value) => writer.writeBool(value));

    // --- Write Specialized Numeric Lists ---
    writer.writeInt8List(myInt8List); // Vec<i8>
    writer.writeInt16List(myInt16List); // Vec<i16>
    writer.writeInt32List(myInt32List); // Vec<i32>
    writer.writeInt64List(myInt64List); // Vec<i64>
    writer.writeUint8List(myUint8List); // Vec<u8>
    writer.writeUint16List(myUint16List); // Vec<u16>
    writer.writeUint32List(myUint32List); // Vec<u32>
    writer.writeUint64List(myUint64List); // Vec<u64>
    writer.writeFloat32List(myFloat32List); // Vec<f32>
    writer.writeFloat64List(myFloat64List); // Vec<f64>

    // --- Write Nested Objects ---

    // Use ForCollection for NestedData (variable size)
    writer.writeNestedValueForCollection(
        myNestedCollection); // NestedData - Vec<T>
    writer.writeOptionNestedValueForCollection(
        myOptionalNestedCollection); // Option<NestedData> - Option<Vec<T>>

    // Use ForFixed for FixedStruct
    writer.writeNestedValueForFixed(myFixedStructInstance); // FixedStruct - T
    writer.writeOptionNestedValueForFixed(
        myOptionalFixedStructInstance); // Option<FixedStruct> - Option<T>

    // List of Fixed: Writes list length, then for each element write raw element_bytes
    writer.writeList<FixedStruct>(myListOfFixedStructs, (item) {
      // u64 length before
      writer.writeNestedValueForFixed(item); // T element
    });
  }

  @override
  void decode(BincodeReader reader) {
    // --- Read Primitives ---
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

    // --- Read Optional Primitives ---
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

    // --- Read Strings ---
    myString = reader.readString();
    myFixedString = reader.readFixedString(32);
    myCleanFixedString = reader.readCleanFixedString(16);
    myOptionString = reader.readOptionString();
    myOptionFixedString = reader.readOptionFixedString(20);
    myCleanOptionFixedString = reader.readCleanOptionFixedString(24);

    // --- Read Generic Collections ---
    myGenericList = reader.readList<int>(() => reader.readU32());
    myGenericMap = reader.readMap<String, bool>(
        () => reader.readString(), () => reader.readBool());

    // --- Read Specialized Numeric Lists ---
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

    // --- Read Nested Objects ---
    // Use ForCollection for NestedData (variable size)
    myNestedCollection =
        reader.readNestedObjectForCollection<NestedData>(NestedData());
    myOptionalNestedCollection = reader
        .readOptionNestedObjectForCollection<NestedData>(() => NestedData());

    // Use ForFixed for FixedStruct (fixed size)
    myFixedStructInstance =
        reader.readNestedObjectForFixed<FixedStruct>(FixedStruct());
    myOptionalFixedStructInstance =
        reader.readOptionNestedObjectForFixed<FixedStruct>(() => FixedStruct());

    // List of Fixed: Read list length, then loop, reading fixed raw bytes for each element
    myListOfFixedStructs = reader.readList<FixedStruct>(() {
      // Use ForFixed to read raw bytes (size calculated from FixedStruct())
      return reader.readNestedObjectForFixed<FixedStruct>(FixedStruct());
    });
  }

  @override
  String toString() {
    return """
MyData {
  Primitives: u8=$myU8, u16=$myU16, u32=$myU32, u64=$myU64, i8=$myI8, i16=$myI16, i32=$myI32, i64=$myI64, f32=$myF32, f64=$myF64, bool=$myBool,
  Optionals: optU8=$myOptionU8, optU16=$myOptionU16, optU32=$myOptionU32, optU64=$myOptionU64, optI8=$myOptionI8, optI16=$myOptionI16, optI32=$myOptionI32, optI64=$myOptionI64, optF32=$myOptionF32, optF64=$myOptionF64, optBool=$myOptionBool,
  Strings: str="$myString", fixedStr="$myFixedString", cleanFixedStr="$myCleanFixedString", optStr=$myOptionString, optFixedStr=$myOptionFixedString, optCleanFixedStr=$myCleanOptionFixedString,
  Specific: optF32Triple=$myOptionF32Triple,
  Generic: genericList=[${myGenericList.length} items], genericMap={${myGenericMap.length} entries},
  NumericLists: i8=[${myInt8List.length}], i16=[${myInt16List.length}], i32=[${myInt32List.length}], i64=[${myInt64List.length}], u8=[${myUint8List.length}], u16=[${myUint16List.length}], u32=[${myUint32List.length}], u64=[${myUint64List.length}], f32=[${myFloat32List.length}], f64=[${myFloat64List.length}],
  NestedDynamic: nestedCollection=$myNestedCollection, optNestedCollection=$myOptionalNestedCollection,
  NestedFixed: fixedStructInstance=$myFixedStructInstance, optFixedStructInstance=$myOptionalFixedStructInstance,
  ListOfFixed: [${myListOfFixedStructs.length} items] ${myListOfFixedStructs.isNotEmpty ? myListOfFixedStructs[0] : ''}...
}
""";
  }
}

// --- Example Usage ---
void main() async {
  // 1. Create
  final originalData = MyData()
    // Primitives
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
    // Optionals (Some set, None null)
    ..myOptionU8 = 100
    ..myOptionI16 = -30000
    ..myOptionF64 = null
    ..myOptionBool = false
    // Strings
    ..myString = "Hello Bincode!"
    ..myFixedString = "This will be truncated or padded"
    ..myCleanFixedString = "Nulls\x00Padded\x00"
    ..myOptionString = "I might be here"
    ..myOptionFixedString = null
    ..myCleanOptionFixedString = "Clean\x00Optional\x00Fixed"
    // Specific
    ..myOptionF32Triple = Float32List.fromList([1.0, 2.5, -3.0])
    // Generic
    ..myGenericList = [10, 20, 30]
    ..myGenericMap = {"enabled": true, "visible": false}
    // Specialized Lists
    ..myInt8List = [-1, 0, 1]
    ..myInt32List = Int32List.fromList([-1, 0, 1, 1000])
    ..myUint8List = Uint8List.fromList([0xCA, 0xFE, 0xBA, 0xBE])
    ..myFloat64List = [1.1, 2.2, 3.3]
    // Dynamic nested data
    ..myNestedCollection = NestedData.create(101, "Dynamic Nested")
    ..myOptionalNestedCollection =
        NestedData.create(102, "Optional Dynamic Present")
    // Fixed nested data
    ..myFixedStructInstance = FixedStruct.create(999, 1.618, true)
    ..myOptionalFixedStructInstance = FixedStruct.create(-1, -2.718, false)
    // List of fixed structs
    ..myListOfFixedStructs = [
      FixedStruct.create(201, 20.1, false),
      FixedStruct.create(202, 20.2, true),
      FixedStruct.create(203, 20.3, false),
    ];

  // 2. Serialize the data to bytes
  print("Original Data: $originalData");
  final writer = BincodeWriter();
  originalData.encode(writer);
  final raw = writer.toBytes();
  print("\nSerialized ${raw.length} bytes: $raw");

  print("\nGoing to Rust, Dart or anyother other language.....");

  // 3. Deserialize the bytes back into a new instance
  final reader = BincodeReader(raw);
  final decodedData = MyData()..decode(reader);
  print("\nDecoded Data: $decodedData");

  // 4. Verify

  // Primitives
  assert(decodedData.myU8 == originalData.myU8);
  assert(decodedData.myU16 == originalData.myU16);
  assert(decodedData.myU32 == originalData.myU32);
  assert(decodedData.myU64 == originalData.myU64);
  assert(decodedData.myI8 == originalData.myI8);
  assert(decodedData.myI16 == originalData.myI16);
  assert(decodedData.myI32 == originalData.myI32);
  assert(decodedData.myI64 == originalData.myI64);
  assert((decodedData.myF32 - originalData.myF32).abs() <
      1e-15); // floating point range
  assert((decodedData.myF64 - originalData.myF64).abs() <
      1e-9); // floating point range
  assert(decodedData.myBool == originalData.myBool);
  // Optionals
  assert(decodedData.myOptionU8 == originalData.myOptionU8);
  assert(decodedData.myOptionI16 == originalData.myOptionI16);
  assert(decodedData.myOptionF64 == originalData.myOptionF64);
  assert(decodedData.myOptionBool == originalData.myOptionBool);
  // Strings
  assert(decodedData.myString == originalData.myString);
  assert(
      decodedData.myFixedString.startsWith("This will be truncated or padded"));
  assert(decodedData.myCleanFixedString == "NullsPadded");
  assert(decodedData.myOptionString == originalData.myOptionString);
  assert(decodedData.myOptionFixedString == originalData.myOptionFixedString);
  assert(decodedData.myCleanOptionFixedString == "CleanOptionalFixed");
  // Generic Collections
  assert(decodedData.myGenericList.length == 3 &&
      decodedData.myGenericList[1] == 20);
  assert(decodedData.myGenericMap["enabled"] == true &&
      decodedData.myGenericMap["visible"] == false);
  // Specialized Lists
  assert(decodedData.myInt8List.length == 3 && decodedData.myInt8List[0] == -1);
  assert(decodedData.myInt32List.length == 4 &&
      decodedData.myInt32List[3] == 1000);
  assert(decodedData.myUint8List.length == 4 &&
      decodedData.myUint8List[1] == 0xFE);
  assert(decodedData.myFloat64List.length == 3 &&
      (decodedData.myFloat64List[1] - 2.2).abs() < 1e-9);
  // Verify dynamic nested
  assert(decodedData.myNestedCollection.nestedId == 101 &&
      decodedData.myNestedCollection.nestedName == "Dynamic Nested");
  assert(decodedData.myOptionalNestedCollection != null);
  assert(decodedData.myOptionalNestedCollection!.nestedId == 102 &&
      decodedData.myOptionalNestedCollection!.nestedName ==
          "Optional Dynamic Present");
  // Verify fixed nested
  assert(decodedData.myFixedStructInstance.valueA == 999);
  assert(decodedData.myFixedStructInstance.valueB == 1.618);
  assert(decodedData.myFixedStructInstance.flagC == true);
  assert(decodedData.myOptionalFixedStructInstance != null);
  assert(decodedData.myOptionalFixedStructInstance!.valueA == -1);
  assert(decodedData.myOptionalFixedStructInstance!.valueB == -2.718);
  assert(decodedData.myOptionalFixedStructInstance!.flagC == false);
  // Verify list of fixed
  assert(decodedData.myListOfFixedStructs.length == 3);
  assert(decodedData.myListOfFixedStructs[0].valueA == 201 &&
      decodedData.myListOfFixedStructs[0].flagC == false);
  assert(decodedData.myListOfFixedStructs[1].valueA == 202 &&
      decodedData.myListOfFixedStructs[1].flagC == true);
  assert(decodedData.myListOfFixedStructs[2].valueA == 203 &&
      decodedData.myListOfFixedStructs[2].flagC == false);

  print("\nVerification successful!");
}
