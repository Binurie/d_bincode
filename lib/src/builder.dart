// ============================================================
// Disclaimer: This source code is provided "as is", without any
// warranty of any kind, express or implied, including but not
// limited to the warranties of merchantability or fitness for
// a particular purpose.
// ============================================================

import 'dart:typed_data';

import '../d_bincode.dart';

/// Abstract interface for writing bincode‐formatted data.
abstract class BincodeBuilder {

  set position(int value);
  int get position;

  //Utils
  void seek(int offset);
  void seekTo(int absolutePosition);
  void rewind();
  void skipToEnd();

  // Base write methods.
  void writeU8(int value);
  void writeU16(int value);
  void writeU32(int value);
  void writeU64(int value);
  void writeI8(int value);
  void writeI16(int value);
  void writeI32(int value);
  void writeI64(int value);
  void writeF32(double value);
  void writeF64(double value);
  void writeBool(bool value);
  void writeBytes(List<int> bytes);
  void writeString(String value, [StringEncoding encoding = StringEncoding.utf8]);
  void writeFixedString(String value, int length);

  // Optional (helper) write methods.
  void writeOptionBool(bool? value);
  void writeOptionU8(int? value);
  void writeOptionU16(int? value);
  void writeOptionU32(int? value);
  void writeOptionU64(int? value);
  void writeOptionI8(int? value);
  void writeOptionI16(int? value);
  void writeOptionI32(int? value);
  void writeOptionI64(int? value);
  void writeOptionF32(double? value);
  void writeOptionF64(double? value);
  void writeOptionF32Triple(Float32List? vec3);
  void writeOptionString(String? value, [StringEncoding encoding = StringEncoding.utf8]);
  void writeOptionFixedString(String? value, int length);

  // Collection write methods.
  void writeList<T>(List<T> values, void Function(T value) writeElement);
  void writeMap<K, V>(
      Map<K, V> values, void Function(K key) writeKey, void Function(V value) writeValue);

  // Primitive list helper methods:
  void writeInt8List(List<int> values);
  void writeInt16List(List<int> values);
  void writeInt32List(List<int> values);
  void writeInt64List(List<int> values);
  void writeUint8List(List<int> values);
  void writeUint16List(List<int> values);
  void writeUint32List(List<int> values);
  void writeUint64List(List<int> values);
  void writeFloat32List(List<double> values);
  void writeFloat64List(List<double> values);

  Future<void> toFile(String path);

  Uint8List toBytes();
}


/// Abstract interface for reading bincode‐formatted data.
abstract class BincodeReaderBuilder {

  set position(int value);
  int get position;

  //Utils
  void seek(int offset);
  void seekTo(int absolutePosition);
  void rewind();
  void skipToEnd();

  // Base read methods.
  int readU8();
  int readU16();
  int readU32();
  int readU64();
  int readI8();
  int readI16();
  int readI32();
  int readI64();
  double readF32();
  double readF64();
  bool readBool();
  List<int> readBytes(int count);
  String readString([StringEncoding encoding = StringEncoding.utf8]);
  String readFixedString(int length, {StringEncoding encoding});

  // Optional read methods.
  bool? readOptionBool();
  int? readOptionU8();
  int? readOptionU16();
  int? readOptionU32();
  int? readOptionU64();
  int? readOptionI8();
  int? readOptionI16();
  int? readOptionI32();
  int? readOptionI64();
  double? readOptionF32();
  double? readOptionF64();
  Float32List? readOptionF32Triple();
  String? readOptionString([StringEncoding encoding = StringEncoding.utf8]);
  String? readOptionFixedString(int length, {StringEncoding encoding});

  // Collection read methods.
  List<T> readList<T>(T Function() readElement);
  Map<K, V> readMap<K, V>(K Function() readKey, V Function() readValue);

  // Primitive list helper methods:
  List<int> readInt8List(int length);
  List<int> readInt16List(int length);
  List<int> readInt32List(int length);
  List<int> readInt64List(int length);
  List<int> readUint8List(int length);
  List<int> readUint16List(int length);
  List<int> readUint32List(int length);
  List<int> readUint64List(int length);
  List<double> readFloat32List(int length);
  List<double> readFloat64List(int length);

  Uint8List toBytes();
}