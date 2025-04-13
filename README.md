
# d_bincode

**d_bincode** is a Dart library for trying to be binary compatible with the [bincode](https://docs.rs/bincode) specification used in Rust. It provides a high-performance, deterministic, and cross-platform solution for encoding and decoding structured data types, including primitives, collections, nested types, and optionals.

## Features

- **Binary Serialization & Deserialization:**  
  Encode and decode integers (`u8`, `u16`, `u32`, `u64`, `i32`), floats (`f32`, `f64`), booleans, and strings (both UTF‑8 and fixed-length) in a space-efficient, binary format.

- **Optionals Support:**  
  Read and write optional values (using a single tag byte for `Some`/`None` semantics).

- **Collections:**  
  Built-in support for reading and writing collections (lists and maps) with length-prefixing as per the bincode spec.

- **Fluent API:**  
  A chainable, expressive API for building bincode-encoded data (via `BincodeFluentBuilder` and `BincodeFluentReader`).

- **Debugging:**  
  Debuggable writer and reader classes that log read and write operations for easy tracing of the encoding/decoding process.

## Getting Started

### Prerequisites

- **Dart SDK:** Version 3.0.0 or later

### Installation

Add `d_bincode` as a dependency in your `pubspec.yaml`:

```yaml
dependencies:
  d_bincode: ^1.0.0
```

Then run:

```sh
dart pub get
```

## Usage


### Examples


```dart
/// === ENUM: RoleType ===
enum RoleType { guest, user, moderator, admin }

/// === CLASS: Address (Nested Struct) ===
class Address extends BincodeEncodable {
  final String city;
  final String zipCode;

  Address(this.city, this.zipCode);

  @override
  void writeBincode(BincodeWriter writer) {
    writer.writeString(city);
    writer.writeString(zipCode);
  }

  factory Address.fromReader(BincodeReader reader) {
    return Address(reader.readString(), reader.readString());
  }

  @override
  String toString() => 'Address(city: "$city", zipCode: "$zipCode")';
}

/// === CLASS: UserProfile (Complex Struct) ===
class UserProfile extends BincodeEncodable {
  final int id;
  final String name;
  final bool isActive;
  final RoleType role;
  final double balance;
  final Float32List? bonusVector;
  final Address? address;
  final List<int> loginTimestamps;
  final String? nickname;
  final double? rating;

  UserProfile({
    required this.id,
    required this.name,
    required this.isActive,
    required this.role,
    required this.balance,
    this.bonusVector,
    this.address,
    required this.loginTimestamps,
    this.nickname,
    this.rating,
  });

  @override
  void writeBincode(BincodeWriter writer) {
    writer.writeU32(id);
    writer.writeString(name);
    writer.writeBool(isActive);
    writer.writeU32(role.index);
    writer.writeF32(balance);
    writer.writeOptionF32Triple(bonusVector);

    writer.writeU8(address != null ? 1 : 0);
    if (address != null) address!.writeBincode(writer);

    writer.writeU32List(loginTimestamps);
    writer.writeOptionString(nickname);
    writer.writeOptionF32(rating);
  }

  factory UserProfile.fromBincode(Uint8List bytes) {
    final reader = BincodeReader(bytes);
    final id = reader.readU32();
    final name = reader.readString();
    final isActive = reader.readBool();
    final roleIndex = reader.readU32();
    final balance = reader.readF32();
    final bonusVec = reader.readOptionF32Triple();
    Address? address;
    if (reader.readU8() == 1) {
      address = Address.fromReader(reader);
    }
    final timestamps = reader.readU32List();
    final nickname = reader.readOptionString();
    final rating = reader.readOptionF32();

    return UserProfile(
      id: id,
      name: name,
      isActive: isActive,
      role: RoleType.values[roleIndex],
      balance: balance,
      bonusVector: bonusVec,
      address: address,
      loginTimestamps: timestamps,
      nickname: nickname,
      rating: rating,
    );
  }

  @override
  String toString() => '''
UserProfile(
  id: $id,
  name: "$name",
  active: $isActive,
  role: $role,
  balance: $balance,
  bonusVector: $bonusVector,
  address: $address,
  loginTimestamps: $loginTimestamps,
  nickname: "$nickname",
  rating: $rating
)''';
}

/// === CLASS: UserData (Simple Struct) ===
class UserData extends BincodeEncodable {
  final int userId;
  final String username;
  final double balance;
  final List<int> loginTimestamps;

  UserData(this.userId, this.username, this.balance, this.loginTimestamps);

  @override
  void writeBincode(BincodeWriter writer) {
    writer.writeU32(userId);
    writer.writeString(username);
    writer.writeF32(balance);
    writer.writeU32List(loginTimestamps);
  }

  factory UserData.fromBincode(Uint8List bytes) {
    final reader = BincodeReader(bytes);
    return UserData(
      reader.readU32(),
      reader.readString(),
      reader.readF32(),
      reader.readU32List(),
    );
  }

  @override
  String toString() =>
      'UserData(userId: $userId, username: "$username", balance: $balance, loginTimestamps: $loginTimestamps)';
}

void main() {
  /// === 1. Complex UserProfile Encoding/Decoding ===
  final profile = UserProfile(
    id: 101,
    name: "DartVenger",
    isActive: true,
    role: RoleType.admin,
    balance: 420.69,
    bonusVector: Float32List.fromList([1.1, 2.2, 3.3]), // float precision 
    address: Address("Flutterville", "90210"),
    loginTimestamps: [1678880000, 1681234567],
    nickname: "DV",
    rating: 4.8,
  );

  final profileBytes = profile.toBincode();
  final decodedProfile = UserProfile.fromBincode(profileBytes);

  print("=== Complex UserProfile ===");
  print("Encoded: $profileBytes");
  print("Decoded:\n$decodedProfile");

  /// === 2. Simple UserData Example ===
  final user = UserData(42, 'Eve_the_Hacker', 1337.50, [1678900000, 1680001234, 1680999999]);
  final encoded = user.toBincode();
  final decoded = UserData.fromBincode(encoded);

  print("\n=== Simple UserData ===");
  print("Encoded: $encoded");
  print("Decoded: $decoded");

  /// === 3. Fluent API Example ===
  final fluent = BincodeFluentBuilder()
    .u32(7)
    .strFix("FluentGuy", 12)
    .f32(88.88)
    .optF32(12.34)
    .optF32(null)
    .optU32(2024)
    .optU32(null)
    .optBool(true)
    .optBool(null)
    ..writeU32List([10, 20, 30]);

  final fluentBytes = fluent.toBytes();
  print("\n=== Fluent Encoded ===");
  print("Encoded: $fluentBytes");

  BincodeFluentReader(fluentBytes)
    .u32((id) => print("→ ID: $id"))
    .fixedStr(12, (name) => print("→ Name: $name"))
    .f32((bal) => print("→ Balance: $bal"))
    .optF32((bonus) => print("→ Optional Bonus: $bonus"))
    .optF32((none) => print("→ Optional Bonus (null): $none"))
    .optU32((year) => print("→ Optional Year: $year"))
    .optU32((none) => print("→ Optional Year (null): $none"))
    .optBool((flag) => print("→ Optional Active: $flag"))
    .optBool((none) => print("→ Optional Active (null): $none"))
    .u32List((list) => print("→ Login timestamps: $list"));

  /// === 4. Debuggable Writer & Reader ===
  final debugWriter = DebuggableBincodeWriter()
    ..writeU32(9001)
    ..writeFixedString("DebugHero", 16)
    ..writeBool(false)
    ..writeOptionF64(3.14159265)
    ..writeOptionString("optional string")
    ..writeOptionBool(null);

  final debugBytes = debugWriter.toBytes();
  final debugReader = DebuggableBincodeReader(debugBytes);

  print("\n=== Debuggable Output ===");
  print("→ ID: ${debugReader.readU32()}");
  print("→ Name: ${debugReader.readFixedString(16)}");
  print("→ Admin Flag: ${debugReader.readBool()}");
  print("→ Pi Value: ${debugReader.readOptionF64()}");
  print("→ Optional String: ${debugReader.readOptionString()}");
  print("→ Optional Flag: ${debugReader.readOptionBool()}");
}

```

## Additional Information

Originally created for a private project, this package wasn't built with every use case in mind. If you notice anything missing or want to extend it for your own needs, feel free to fork or open a pull request.