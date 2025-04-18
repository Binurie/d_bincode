
# d_bincode

**d_bincode** is a Dart library for efficient binary serialization. It supports encoding and decoding of primitives, collections, nested structures, enums, and optionals in a compact and deterministic format manually writen.  
Can be used for cross-language communication like with rust [bincode](https://docs.rs/bincode).



## Features

- **Binary Encoding:** Supports integers (`u8`-`u64`, `i8`-`i64`), floats (`f32`, `f64`), booleans, and strings (UTF-8, fixed-length).
- **Optional Values:** Encodes `Option<T>` types using a 1-byte tag (0=None, 1=Some) followed by the value if Some.
- **Enums:** Encoded as `u8` based on their index.
- **Nested Objects (Variable Size):** Handles objects requiring a length prefix (e.g., in `Vec<T>`). Uses `*ForCollection`.
- **Nested Objects (Fixed Size):** Handles objects with a known fixed size without a per-object length prefix (e.g., embedded structs). Uses `*ForFixed`.
- **Collections:** Supports `List<T>` and `Map<K, V>` with standard Bincode length-prefixing.
- **Custom Types:** Require implementing `BincodeEncodable` (->), `BincodeDecodable` (<-), or `BincodeCodable` (<->).


## Getting Started

### Prerequisites

- **Dart SDK:** Version 3.0.0 or later

### Installation

Add `d_bincode` as a dependency in your `pubspec.yaml`:

```yaml
dependencies:
  d_bincode: ^2.0.0
```

Then run:

```sh
dart pub get
```

## Usage


### Examples


```dart
/// Example data structure implementing BincodeCodable.

// For full encode decode you need to impl BincodeCodable. 
class UserProfile implements BincodeCodable {
  int userId = 0;
  String username = '';
  int? points;
  List<String> tags = [];

  UserProfile();
  UserProfile.create(this.userId, this.username, this.points, this.tags);

 // Create the impl for toBincode. The struct MUST match
 // the other side's exact order and types definition
  @override
  Uint8List toBincode() {
    final writer = BincodeWriter(); // default writer settings
    writer.writeU32(userId);
    writer.writeString(username);
    writer.writeOptionI32(points);
    writer.writeList<String>(tags, (tag) => writer.writeString(tag));
    return writer.toBytes();
  }

  // Create the impl for fromBincode. The struct MUST match
  // the other side's exact order and types definition
  @override
  void fromBincode(Uint8List bytes) {
    final reader = BincodeReader(bytes); // default reader setting
    userId = reader.readU32();
    username = reader.readString();
    points = reader.readOptionI32();
    tags = reader.readList<String>(() => reader.readString());
  }

   @override String toString() => 'User(id:$userId, name:"$username", pts:$points, tags:$tags)';
}


// --- Example Usage ---

void main() {

  // 1. Create an instance
  final profile = UserProfile.create(
    101,
    'BincoderDev',
    2500,
    ['dart', 'bincode'],
  );
  print('Original: $profile');

  // 2. Serialize
  Uint8List encodedBytes;
  encodedBytes = profile.toBincode();
  print('Serialized: ${encodedBytes} bytes');

  // --- Breakdown of Bytes ---
  // [101, 0, 0, 0]                                       // U32 userId = 101
  // [11, 0, 0, 0, 0, 0, 0, 0]                            // U64 username Length = 11
  // [66, 105, 110, 99, 111, 100, 101, 114, 68, 101, 118] // "BincoderDev" (UTF-8 bytes)
  // [1]                                                  // Option<i32> points = Some(1)
  // [196, 9, 0, 0]                                       // I32 points Value = 2500 (Little Endian)
  // [2, 0, 0, 0, 0, 0, 0, 0]                             // U64 tags list Length = 2
  // [4, 0, 0, 0, 0, 0, 0, 0]                             // U64 tags[0] ("dart") Length = 4
  // [100, 97, 114, 116]                                  // "dart" (UTF-8 bytes)
  // [7, 0, 0, 0, 0, 0, 0, 0]                             // U64 tags[1] ("bincode") Length = 7
  // [98, 105, 110, 99, 111, 100, 101]                    // "bincode" (UTF-8 bytes)

  // (encodedBytes can now be used, e.g., saved or sent like with encodedBytes.toFile)

  // 3. Deserialize
  final decodedProfile = UserProfile();
  decodedProfile.fromBincode(encodedBytes);
  print('Decoded:  $decodedProfile');

  // Decoded:  User(id:101, name:"BincoderDev", pts:2500, tags:[dart, bincode])
}


```

## Additional Information

Originally created for a private project, this package wasn't built with every use case in mind. If you want to extend it for your own needs, fork or open a pull request.