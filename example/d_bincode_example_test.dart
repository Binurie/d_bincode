import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:d_bincode/d_bincode.dart';

class NestedData implements BincodeCodable {
  int nestedId = 0;
  String nestedName = "Default Nested";
  NestedData();
  NestedData.create(this.nestedId, this.nestedName);
  @override
  void encode(BincodeWriter w) {
    w.writeI32(nestedId);
    w.writeString(nestedName);
  }

  @override
  void decode(BincodeReader r) {
    nestedId = r.readI32();
    nestedName = r.readString();
  }

  @override
  bool operator ==(Object other) =>
      other is NestedData &&
      nestedId == other.nestedId &&
      nestedName == other.nestedName;
  @override
  int get hashCode => nestedId.hashCode ^ nestedName.hashCode;
  @override
  String toString() => 'NestedData(id: $nestedId, name: "$nestedName")';
}

class FixedStruct implements BincodeCodable {
  int valueA = 0;
  double valueB = 0.0;
  bool flagC = false;
  FixedStruct();
  FixedStruct.create(this.valueA, this.valueB, this.flagC);
  @override
  void encode(BincodeWriter w) {
    w.writeI32(valueA);
    w.writeF64(valueB);
    w.writeBool(flagC);
  }

  @override
  void decode(BincodeReader r) {
    valueA = r.readI32();
    valueB = r.readF64();
    flagC = r.readBool();
  }

  @override
  bool operator ==(Object other) =>
      other is FixedStruct &&
      valueA == other.valueA &&
      valueB == other.valueB &&
      flagC == other.flagC;
  @override
  int get hashCode => valueA.hashCode ^ valueB.hashCode ^ flagC.hashCode;
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
  String myChar = '';

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
  String? myOptionChar;

  String myString = "";
  String myFixedString = "";
  String myCleanFixedString = "";
  String? myOptionString;
  String? myOptionFixedString;
  String? myCleanOptionFixedString;

  List<int> myGenericList = [];
  Map<String, bool> myGenericMap = {};
  List<int> myFixedU16Array = [];
  Set<String> myStringSet = {};

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

  int myEnumDiscriminant = 0;
  int? myOptionEnumDiscriminant;
  Duration myDuration = Duration.zero;
  Duration? myOptionDuration;

  @override
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
    writer.writeChar(myChar);
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
    writer.writeOptionChar(myOptionChar);
    writer.writeString(myString);
    writer.writeFixedString(myFixedString, 32);
    writer.writeFixedString(myCleanFixedString, 16);
    writer.writeOptionString(myOptionString);
    writer.writeOptionFixedString(myOptionFixedString, 20);
    writer.writeOptionFixedString(myCleanOptionFixedString, 24);
    writer.writeList<int>(myGenericList, (v) => writer.writeU32(v));
    writer.writeMap<String, bool>(
        myGenericMap, (k) => writer.writeString(k), (v) => writer.writeBool(v));
    writer.writeFixedArray<int>(myFixedU16Array, 3, writer.writeU16);
    writer.writeSet<String>(myStringSet, writer.writeString);
    writer.writeInt8List(myInt8List);
    writer.writeInt16List(myInt16List);
    writer.writeInt32List(myInt32List);
    writer.writeInt64List(myInt64List);
    writer.writeUint8List(myUint8List);
    writer.writeUint16List(myUint16List);
    writer.writeUint32List(myUint32List);
    writer.writeUint64List(myUint64List);
    writer.writeFloat32List(myFloat32List);
    writer.writeFloat64List(myFloat64List);
    writer.writeNestedValueForCollection(myNestedCollection);
    writer.writeOptionNestedValueForCollection(myOptionalNestedCollection);
    writer.writeNestedValueForFixed(myFixedStructInstance);
    writer.writeOptionNestedValueForFixed(myOptionalFixedStructInstance);
    writer.writeList<FixedStruct>(
        myListOfFixedStructs, (item) => writer.writeNestedValueForFixed(item));
    writer.writeEnumDiscriminant(myEnumDiscriminant);
    writer.writeOptionEnumDiscriminant(myOptionEnumDiscriminant);
    writer.writeDuration(myDuration);
    writer.writeOptionDuration(myOptionDuration);
  }

  @override
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
    myChar = reader.readChar();
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
    myOptionChar = reader.readOptionChar();
    myString = reader.readString();
    myFixedString = reader.readFixedString(32);
    myCleanFixedString = reader.readCleanFixedString(16);
    myOptionString = reader.readOptionString();
    myOptionFixedString = reader.readOptionFixedString(20);
    myCleanOptionFixedString = reader.readCleanOptionFixedString(24);
    myGenericList = reader.readList<int>(() => reader.readU32());
    myGenericMap = reader.readMap<String, bool>(
        () => reader.readString(), () => reader.readBool());
    myFixedU16Array = reader.readFixedArray<int>(3, reader.readU16);
    myStringSet = reader.readSet<String>(reader.readString);
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
    myListOfFixedStructs = reader.readList<FixedStruct>(
        () => reader.readNestedObjectForFixed<FixedStruct>(FixedStruct()));
    myEnumDiscriminant = reader.readEnumDiscriminant();
    myOptionEnumDiscriminant = reader.readOptionEnumDiscriminant();
    myDuration = reader.readDuration();
    myOptionDuration = reader.readOptionDuration();
  }

  @override
  String toString() {
    return """
MyData {
  Primitives: u8=$myU8, u16=$myU16, u32=$myU32, u64=$myU64, i8=$myI8, i16=$myI16, i32=$myI32, i64=$myI64, f32=$myF32, f64=$myF64, bool=$myBool, char='$myChar',
  Optionals: optU8=$myOptionU8, optU16=$myOptionU16, optU32=$myOptionU32, optU64=$myOptionU64, optI8=$myOptionI8, optI16=$myOptionI16, optI32=$myOptionI32, optI64=$myOptionI64, optF32=$myOptionF32, optF64=$myOptionF64, optBool=$myOptionBool, optChar=$myOptionChar,
  Strings: str="$myString", fixedStr="$myFixedString", cleanFixedStr="$myCleanFixedString", optStr=$myOptionString, optFixedStr=$myOptionFixedString, optCleanFixedStr=$myCleanOptionFixedString,
  Collections: genericList=$myGenericList, genericMap=$myGenericMap, fixedU16Array=$myFixedU16Array, stringSet=$myStringSet,
  NumericLists: i8=[${myInt8List.length}], i16=[${myInt16List.length}], i32=[${myInt32List.length}], i64=[${myInt64List.length}], u8=[${myUint8List.length}], u16=[${myUint16List.length}], u32=[${myUint32List.length}], u64=[${myUint64List.length}], f32=[${myFloat32List.length}], f64=[${myFloat64List.length}],
  NestedDynamic: nestedCollection=$myNestedCollection, optNestedCollection=$myOptionalNestedCollection,
  NestedFixed: fixedStructInstance=$myFixedStructInstance, optFixedStructInstance=$myOptionalFixedStructInstance,
  ListOfFixed: [${myListOfFixedStructs.length} items],
  Custom/Enum: enumDiscriminant=$myEnumDiscriminant, optEnumDiscriminant=$myOptionEnumDiscriminant, duration=$myDuration, optDuration=$myOptionDuration
}
""";
  }
}

void main() {
  final listEquality = ListEquality();
  final setEquality = SetEquality();
  final mapEquality = MapEquality();

  final originalData = MyData()
    ..myU8 = 250
    ..myU16 = 65000
    ..myU32 = 4000000000
    ..myU64 = 0xFEDCBA9876543210
    ..myI8 = -100
    ..myI16 = -30000
    ..myI32 = -2000000000
    ..myI64 = -0x7EDCBA9876543210
    ..myF32 = 1.234567e-20
    ..myF64 = -9.87654321e30
    ..myBool = true
    ..myChar = '€'
    ..myOptionU8 = 123
    ..myOptionI16 = null
    ..myOptionF64 = 1.0
    ..myOptionBool = false
    ..myOptionChar = null
    ..myString = "Test String with Unicode 😊"
    ..myFixedString = "Fixed Len"
    ..myCleanFixedString = "Padded\x00\x00"
    ..myOptionString = null
    ..myOptionFixedString = "OptionalFixed"
    ..myCleanOptionFixedString = "Clean\x00Opt\x00Fixed"
    ..myGenericList = [11, 22, 33]
    ..myGenericMap = {"active": true, "ready": false}
    ..myFixedU16Array = [500, 600, 700]
    ..myStringSet = {'apple', 'orange'}
    ..myInt8List = [-10, 0, 10]
    ..myInt32List = Int32List.fromList([-100, 0, 100, 200])
    ..myUint8List = Uint8List.fromList([1, 2, 3, 4, 5])
    ..myFloat64List = [0.1, 0.2, 0.3]
    ..myNestedCollection = NestedData.create(55, "Dynamic Nested Example")
    ..myOptionalNestedCollection = null
    ..myFixedStructInstance = FixedStruct.create(123, -456.789, true)
    ..myOptionalFixedStructInstance = FixedStruct.create(9, 8.0, false)
    ..myListOfFixedStructs = [
      FixedStruct.create(1, 1.0, false),
      FixedStruct.create(2, 2.0, true),
    ]
    ..myEnumDiscriminant = 2
    ..myOptionEnumDiscriminant = 0
    ..myDuration = Duration(minutes: -90, seconds: 15, milliseconds: 500)
    ..myOptionDuration = Duration(days: 1, hours: 1);

  print("Original Data: $originalData");
  final writer = BincodeWriter();
  originalData.encode(writer);
  final raw = writer.toBytes();
  print("\nSerialized ${raw.length} bytes: ${BincodeWriter.toHex(raw)}");

  final reader = BincodeReader(raw);
  final decodedData = MyData()..decode(reader);
  print("\nDecoded Data: $decodedData");

  print("\nRemaining bytes after decode: ${reader.remainingBytes}");
  assert(reader.remainingBytes == 0, "Reader did not consume all bytes!");

  print("\nVerification Start:");

  assert(decodedData.myU8 == originalData.myU8, 'myU8 mismatch');
  assert(decodedData.myU16 == originalData.myU16, 'myU16 mismatch');
  assert(decodedData.myU32 == originalData.myU32, 'myU32 mismatch');
  assert(decodedData.myU64 == originalData.myU64, 'myU64 mismatch');
  assert(decodedData.myI8 == originalData.myI8, 'myI8 mismatch');
  assert(decodedData.myI16 == originalData.myI16, 'myI16 mismatch');
  assert(decodedData.myI32 == originalData.myI32, 'myI32 mismatch');
  assert(decodedData.myI64 == originalData.myI64, 'myI64 mismatch');
  assert(
      (decodedData.myF32 - originalData.myF32).abs() < 1e-25, 'myF32 mismatch');
  assert(
      (decodedData.myF64 - originalData.myF64).abs() < 1e-15, 'myF64 mismatch');
  assert(decodedData.myBool == originalData.myBool, 'myBool mismatch');
  assert(decodedData.myChar == originalData.myChar, 'myChar mismatch');

  assert(
      decodedData.myOptionU8 == originalData.myOptionU8, 'myOptionU8 mismatch');
  assert(decodedData.myOptionI16 == originalData.myOptionI16,
      'myOptionI16 mismatch');
  assert(decodedData.myOptionF64 == originalData.myOptionF64,
      'myOptionF64 mismatch');
  assert(decodedData.myOptionBool == originalData.myOptionBool,
      'myOptionBool mismatch');
  assert(decodedData.myOptionChar == originalData.myOptionChar,
      'myOptionChar mismatch');

  assert(decodedData.myString == originalData.myString, 'myString mismatch');
  assert(decodedData.myFixedString.startsWith("Fixed Len"),
      'myFixedString mismatch');
  assert(decodedData.myCleanFixedString == "Padded",
      'myCleanFixedString mismatch');
  assert(decodedData.myOptionString == originalData.myOptionString,
      'myOptionString mismatch');
  assert(
      decodedData.myOptionFixedString?.replaceAll('\x00', '') ==
          originalData.myOptionFixedString,
      'myOptionFixedString content mismatch');
  assert(decodedData.myCleanOptionFixedString == "CleanOptFixed",
      'myCleanOptionFixedString mismatch');

  assert(
      listEquality.equals(
          decodedData.myGenericList, originalData.myGenericList),
      'myGenericList mismatch');
  assert(
      mapEquality.equals(decodedData.myGenericMap, originalData.myGenericMap),
      'myGenericMap mismatch');
  assert(
      listEquality.equals(
          decodedData.myFixedU16Array, originalData.myFixedU16Array),
      'myFixedU16Array mismatch');
  assert(setEquality.equals(decodedData.myStringSet, originalData.myStringSet),
      'myStringSet mismatch');

  assert(listEquality.equals(decodedData.myInt8List, originalData.myInt8List),
      'myInt8List mismatch');
  assert(listEquality.equals(decodedData.myInt32List, originalData.myInt32List),
      'myInt32List mismatch');
  assert(listEquality.equals(decodedData.myUint8List, originalData.myUint8List),
      'myUint8List mismatch');
  assert(
      listEquality.equals(
          decodedData.myFloat64List, originalData.myFloat64List),
      'myFloat64List mismatch');

  assert(decodedData.myNestedCollection == originalData.myNestedCollection,
      'myNestedCollection mismatch');
  assert(
      decodedData.myOptionalNestedCollection ==
          originalData.myOptionalNestedCollection,
      'myOptionalNestedCollection mismatch');
  assert(
      decodedData.myFixedStructInstance == originalData.myFixedStructInstance,
      'myFixedStructInstance mismatch');
  assert(
      decodedData.myOptionalFixedStructInstance ==
          originalData.myOptionalFixedStructInstance,
      'myOptionalFixedStructInstance mismatch');
  assert(
      listEquality.equals(
          decodedData.myListOfFixedStructs, originalData.myListOfFixedStructs),
      'myListOfFixedStructs mismatch');

  assert(decodedData.myEnumDiscriminant == originalData.myEnumDiscriminant,
      'myEnumDiscriminant mismatch');
  assert(
      decodedData.myOptionEnumDiscriminant ==
          originalData.myOptionEnumDiscriminant,
      'myOptionEnumDiscriminant mismatch');
  assert(
      decodedData.myDuration == originalData.myDuration, 'myDuration mismatch');
  assert(decodedData.myOptionDuration == originalData.myOptionDuration,
      'myOptionDuration mismatch');

  print("\nVerification successful!");
}
