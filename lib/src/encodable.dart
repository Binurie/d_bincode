// ============================================================
// Disclaimer: This source code is provided "as is", without any
// warranty of any kind, express or implied, including but not
// limited to the warranties of merchantability or fitness for
// a particular purpose.
// ============================================================

import 'dart:typed_data';

import '../d_bincode.dart';


/// A contract for types that support binary serialization using the bincode format.
///
/// Classes implementing this should define how they serialize their internal state
/// using a [BincodeWriter]. This enables them to be converted to compact, efficient
/// binary representations suitable for I/O, file storage, or interprocess communication.
///
/// Example:
/// ```dart
/// class MyData extends BincodeEncodable {
///   final int id;
///   final double score;
///
///   MyData(this.id, this.score);
///
///   @override
///   void writeBincode(BincodeWriter writer) {
///     writer.writeU32(id);
///     writer.writeF64(score);
///   }
/// }
/// ```
abstract class BincodeEncodable {
  /// Writes the object's internal state into the given [writer] using bincode encoding.
  ///
  /// Implementers should use the provided writer to serialize all necessary fields.
  void writeBincode(BincodeWriter writer);

  /// Serializes the instance into a compact bincode-formatted [Uint8List].
  ///
  /// This is a convenience method that creates a [BincodeWriter], invokes [writeBincode],
  /// and returns the resulting byte output.
  Uint8List toBincode() {
    final writer = BincodeWriter();
    writeBincode(writer);
    return writer.toBytes();
  }
}
