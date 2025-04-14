
# d_bincode

**d_bincode** is a Dart library for efficient binary serialization. It supports encoding and decoding of primitives, collections, nested structures, enums, and optionals in a compact and deterministic format manually writen.  
Can be used for cross-language communication like with rust [bincode](https://docs.rs/bincode).



## Features

- **Binary Encoding**  
  Supports integers (`u8`, `u16`, `u32`, `u64`, `i8`, `i16`, `i32`, `i64`), floats (`f32`, `f64`), booleans, UTF-8 and fixed-length strings.

- **Optional Values**  
  Encoded using a single tag byte: `0` (null), `1` (value present).

- **Enums**  
  Encoded as `u8` using index position.

- **Nested Structures**  
  Written with length-prefixed byte sections. writeNested,  writeOptionalNested, readNestedObject, readOptionalNestedObject

- **Collections**  
  Supports `List<T>` and `Map<K, V>` with length-prefixing.

- **Manual Encoding**  
  Custom Types must implement `BincodeEncodable` and `BincodeDecodable` for full control and use .



## Getting Started

### Prerequisites

- **Dart SDK:** Version 3.0.0 or later

### Installation

Add `d_bincode` as a dependency in your `pubspec.yaml`:

```yaml
dependencies:
  d_bincode: ^1.0.1
```

Then run:

```sh
dart pub get
```

## Usage


### Examples


```dart
// #### How to use d_bincode example ########

/// Enum representing user roles in the system.
enum UserRole {
  guest,
  user,
  admin,
}

/// A nested class to demonstrate how to serialize/deserialize nested objects.
class Profile implements BincodeEncodable, BincodeDecodable {
  int age;
  double rating;

  Profile(this.age, this.rating);

  @override
  Uint8List toBincode() {
    final writer = BincodeWriter();
    writer.writeU8(age);       // 1-byte unsigned age
    writer.writeF64(rating);   // 8-byte float
    return writer.toBytes();
  }

  @override
  void loadFromBytes(Uint8List bytes) {
    final reader = BincodeReader(bytes);
    age = reader.readU8();     // same order
    rating = reader.readF64();
  }

  @override
  String toString() => 'Profile(age: $age, rating: $rating)';
}

/// Demonstrates how to fully implement custom bincode serialization
/// with enum, optional fields, and nested objects.
class Example implements BincodeEncodable, BincodeDecodable {
  int id;
  String name;
  UserRole role;
  String? nickname;
  Profile profile;

  Example(this.id, this.name, this.role, this.nickname, this.profile);

  @override
  Uint8List toBincode() {
    final writer = BincodeWriter();
    writer.writeU32(id);                      // 4-byte unsigned integer
    writer.writeString(name);                 // UTF-8 with u64 length
    writer.writeU8(role.index);               // enum index (compact: u8)
    writer.writeOptionString(nickname);       // optional UTF-8 string
    writer.writeNested(profile);              // nested Profile
    return writer.toBytes();
  }

  @override
  void loadFromBytes(Uint8List bytes) {
    final reader = BincodeReader(bytes);
    id = reader.readU32();                    // same order
    name = reader.readString();
    role = UserRole.values[reader.readU8()];
    nickname = reader.readOptionString();
    profile = reader.readNestedObject(Profile(0, 0.0));
  }

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

void main() {
  final original = Example(
    123,                       // id
    "Alice",                   // name
    UserRole.admin,            // role
    "Ali",                     // optional nickname
    Profile(30, 4.9),          // nested profile
  );

  final bytes = original.toBincode();
  final decoded = Example(0, "", UserRole.guest, null, Profile(0, 0.0))
    ..loadFromBytes(bytes);

  print("Encoded bytes: $bytes");
  // Breakdown of bytes:
  // [123, 0, 0, 0]                       // u32 id = 123
  // [5, 0, 0, 0, 0, 0, 0, 0]             // u64 string length = 5 (name)
  // [65, 108, 105, 99, 101]              // UTF-8 "Alice"
  // [2]                                  // role.index = 2 (admin)
  // [1]                                  // Option<String> present (nickname)
  // [3, 0, 0, 0, 0, 0, 0, 0]             // u64 string length = 3 (nickname)
  // [65, 108, 105]                       // UTF-8 "Ali"
  // [9, 0, 0, 0, 0, 0, 0, 0]             // u64 length of nested profile = 9 bytes
  // [30]                                 // u8 age = 30
  // [154, 153, 153, 153, 153, 153, 19, 64] // f64 rating = 4.9

  print("Decoded: $decoded");

//   Decoded: Example(
//   id: 123,
//   name: Alice,
//   role: UserRole.admin,
//   nickname: Ali,
//   profile: Profile(age: 30, rating: 4.9)
// )
}

```

## Additional Information

Originally created for a private project, this package wasn't built with every use case in mind. If you want to extend it for your own needs, fork or open a pull request.