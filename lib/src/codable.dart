// ============================================================
// Disclaimer: This source code is provided "as is", without any
// warranty of any kind, express or implied, including but not
// limited to the warranties of merchantability or fitness for
// a particular purpose.
// ============================================================

import 'dart:typed_data';


/// An interface for types that can be encoded into bincode format.
abstract class BincodeEncodable {
  /// Serializes the object into a bincode-formatted [Uint8List].
  Uint8List toBincode();
}

/// An interface for types that can be decoded (loaded) from bincode format.
abstract class BincodeDecodable {
  /// Populates the object with data from the provided bincode-formatted [bytes].
  ///
  /// Implementations should read the data in the same order as was written.
  void loadFromBytes(Uint8List bytes);
}