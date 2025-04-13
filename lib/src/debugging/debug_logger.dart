// ============================================================
// Disclaimer: This source code is provided "as is", without any
// warranty of any kind, express or implied, including but not
// limited to the warranties of merchantability or fitness for
// a particular purpose.
// ============================================================

import 'dart:typed_data';

import '../../d_bincode.dart';

/// A debug-enabled implementation of [BincodeWriter].
///
/// This class wraps the standard [BincodeWriter] functionality
/// and mixes in [BincodeWriterDebugLogger] to provide verbose logging
/// during serialization. Every write operation logs the action to
/// the console, making it suitable for tracing and development use.
///
/// Example:
/// ```dart
/// final writer = DebuggableBincodeWriter();
/// writer.writeU32(42); // Logs: [BincodeDebug] writeU32: 42
/// ```
class DebuggableBincodeWriter extends BincodeWriter with BincodeWriterDebugLogger {}


/// A debug-enabled implementation of [BincodeReader].
///
/// This class wraps the standard [BincodeReader] functionality
/// and mixes in [BincodeReaderDebugLogger] to provide detailed logging
/// during deserialization. Every read operation logs its result,
/// enabling better visibility into binary parsing during development.
///
/// Example:
/// ```dart
/// final reader = DebuggableBincodeReader(bytes);
/// final value = reader.readU32(); // Logs: [BincodeDebug - Reader] readU32: 42
/// ```
class DebuggableBincodeReader extends BincodeReader with BincodeReaderDebugLogger {
  /// Creates a [DebuggableBincodeReader] from raw binary data.
  DebuggableBincodeReader(Uint8List bytes) : super(bytes);
}
