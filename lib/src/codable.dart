// ============================================================
// Disclaimer: This source code is provided "as is", without any
// warranty of any kind, express or implied, including but not
// limited to the warranties of merchantability or fitness for
// a particular purpose.
// ============================================================

import 'dart:typed_data';

/// A interface combining [BincodeEncodable] and [BincodeDecodable].
///
/// Implement this interface for types requiring full round-trip serialization
/// and deserialization using the Bincode standard format.
abstract class BincodeCodable implements BincodeEncodable, BincodeDecodable {}

/// Defines the contract for types that can be serialized into the Bincode standard format.
abstract class BincodeEncodable {
  /// Serializes the current state of the object into a bincode-formatted [Uint8List].
  /// Implementations **must** use a [BincodeWriter] and write data fields
  /// in the **exact same sequence and type** as reading by the corresponding
  /// [BincodeDecodable.fromBincode] method or Object send from other cross platform languages.
  Uint8List toBincode();
}

/// Defines the contract for types whose state can be populated by deserializing
/// data from the Bincode standard format.
abstract class BincodeDecodable {
  /// Populates the object's state from the provided bincode-formatted standard [bytes].
  ///
  /// Implementations **must** use a [BincodeReader] and read data fields
  /// in the **exact same sequence and type** as written by the corresponding
  /// [BincodeEncodable.toBincode] method or Object send from other cross platform languages.
  void fromBincode(Uint8List bytes);
}
