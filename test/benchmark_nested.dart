// ignore_for_file: unused_local_variable

/*
#######################################################################
# DISCLAIMER: This benchmark is for illustrative and comparative use. #
# Results are approximate and depend on runtime conditions such as    #
# device hardware, Dart VM optimizations, system load, and compiler.  #
#                                                                     #
# Do NOT use this as a definitive performance guarantee. Always test #
# and profile with your own data and environment for accurate results.#
#######################################################################
*/

import 'dart:convert';
import 'dart:typed_data';

import 'package:d_bincode/d_bincode.dart';

/// Enum representing user roles.
enum UserRole { guest, user, admin }

/// A nested class demonstrating bincode (de)serialization.
class Profile implements BincodeEncodable, BincodeDecodable {
  int age;
  double rating;

  Profile(this.age, this.rating);

  @override
  Uint8List toBincode() {
    final writer = BincodeWriter();
    writer.writeU8(age);       // Write 1-byte age.
    writer.writeF64(rating);   // Write 8-byte float (rating).
    return writer.toBytes();
  }

  @override
  void loadFromBytes(Uint8List bytes) {
    final reader = BincodeReader(bytes);
    age = reader.readU8();     // Read 1-byte age.
    rating = reader.readF64(); // Read 8-byte float (rating).
  }

  /// Converts this object into a JSON-compatible map.
  Map<String, dynamic> toJson() => {"age": age, "rating": rating};

  @override
  String toString() => 'Profile(age: $age, rating: $rating)';
}

/// demonstrates custom bincode serialization with an enum,
/// an optional field, and a nested object.

class Example implements BincodeEncodable, BincodeDecodable {
  int id;
  String name;
  UserRole role;
  String? nickname;
  Profile profile;

  Example(this.id, this.name, this.role, this.nickname, this.profile);

  /// Converts this object into a binary representation.
  /// Writes:
  /// - A 4-byte unsigned int for [id].
  /// - A UTF-8 string (prefixed by a 8-byte length) for [name].
  /// - A 1-byte unsigned int for [role]'s index.
  /// - An optional string for [nickname] (with 1-byte tag + length + content).
  /// - A nested [Profile] (with a 8-byte length prefix).
  @override
  Uint8List toBincode() {
    final writer = BincodeWriter();
    writer.writeU32(id);                   // 4 bytes for id.
    writer.writeString(name);              // UTF-8: 8-byte length + content.
    writer.writeU8(role.index);            // 1 byte for role index.
    writer.writeOptionString(nickname);    // 1-byte tag + string if present.
    writer.writeNested(profile);           // u64 length + Profile bytes.
    return writer.toBytes();
  }

  @override
  void loadFromBytes(Uint8List bytes) {
    final reader = BincodeReader(bytes);
    id = reader.readU32();
    name = reader.readString();
    role = UserRole.values[reader.readU8()];
    nickname = reader.readOptionString();
    profile = reader.readNestedObject(Profile(0, 0.0));
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "role": role.toString().split('.').last,
        "nickname": nickname,
        "profile": profile.toJson(),
      };

  @override
  String toString() => '''
Example(
  id: $id,
  name: $name,
  role: $role,
  nickname: $nickname,
  profile: $profile
)''';
}

/// Benchmark that compares Bincode and JSON serialization/deserialization times
/// along with size comparisons.
void main() {
  const iterations = 10000000;

  final example = Example(123, "Alice", UserRole.admin, "Ali", Profile(30, 4.9));

  // Serialize once to get byte sizes.
  final bincodeBytes = example.toBincode();
  final jsonString = json.encode(example.toJson());
  final jsonBytes = utf8.encode(jsonString);

  // --- Benchmark Bincode ---
  final bincodeStart = DateTime.now().microsecondsSinceEpoch;
  for (int i = 0; i < iterations; i++) {
    final bytes = example.toBincode();
    final decoded = Example(0, "", UserRole.guest, null, Profile(0, 0.0))
      ..loadFromBytes(bytes);
  }
  final bincodeEnd = DateTime.now().microsecondsSinceEpoch;
  final bincodeMs = (bincodeEnd - bincodeStart) / 1000.0;

  // --- Benchmark JSON ---
  final jsonStart = DateTime.now().microsecondsSinceEpoch;
  for (int i = 0; i < iterations; i++) {
    final encoded = json.encode(example.toJson());
    final decoded = json.decode(encoded);
  }
  final jsonEnd = DateTime.now().microsecondsSinceEpoch;
  final jsonMs = (jsonEnd - jsonStart) / 1000.0;

  // --- Output Results ---
  print('--- Benchmark (x$iterations iterations) ---');
  print('Bincode total time: ${bincodeMs.toStringAsFixed(2)} ms');
  print('JSON total time:    ${jsonMs.toStringAsFixed(2)} ms');

  print('\n--- Size Comparison ---');
  final bincodeSize = bincodeBytes.length;
  final jsonSize = jsonBytes.length;
  final sizeDiff = jsonSize - bincodeSize;
  final percentSaved = ((sizeDiff / jsonSize) * 100).toStringAsFixed(2);

  print('Single Bincode size: $bincodeSize bytes');
  print('Single JSON size:    $jsonSize bytes');
  print('Saved per item:      $sizeDiff bytes (~$percentSaved%)');

  final totalSavedBytes = sizeDiff * iterations;
  final totalSavedKB = (totalSavedBytes / 1024).toStringAsFixed(2);
  final totalSavedMB = (totalSavedBytes / (1024 * 1024)).toStringAsFixed(2);

  print('\n--- Total Saved Over $iterations Items ---');
  print('Bytes saved:         $totalSavedBytes bytes');
  print('Kilobytes saved:     $totalSavedKB KB');
  print('Megabytes saved:     $totalSavedMB MB');

  print('\n--- Average Parsing Speed per Iteration ---');
  print('Bincode: ${(bincodeMs / iterations).toStringAsFixed(6)} ms');
  print('JSON:    ${(jsonMs / iterations).toStringAsFixed(6)} ms');

  //   --- Benchmark (x10000000 iterations) ---
  // Bincode total time: 20125.13 ms

  // Exited.
  // JSON total time:    24246.06 ms

  // --- Size Comparison ---
  // Single Bincode size: 47 bytes
  // Single JSON size:    91 bytes
  // Saved per item:      44 bytes (~48.35%)

  // --- Total Saved Over 10000000 Items ---
  // Bytes saved:         440000000 bytes
  // Kilobytes saved:     429687.50 KB
  // Megabytes saved:     419.62 MB

  // --- Average Parsing Speed per Iteration ---
  // Bincode: 0.002013 ms
  // JSON:    0.002425 ms
}