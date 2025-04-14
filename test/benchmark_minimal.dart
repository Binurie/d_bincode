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

/// A minimal message that only contains an unsigned 32-bit integer.
class TinyMessage implements BincodeEncodable, BincodeDecodable {
  int number;

  TinyMessage(this.number);

  @override
  Uint8List toBincode() {
    final writer = BincodeWriter();
    writer.writeU32(number); // 4-byte unsigned integer
    return writer.toBytes();
  }

  @override
  void loadFromBytes(Uint8List bytes) {
    final reader = BincodeReader(bytes);
    number = reader.readU32();
  }

  Map<String, dynamic> toJson() => {"number": number};
}

void main() {
  const iterations = 10000000;

  final message = TinyMessage(1337);

  final encodedBincode = message.toBincode();
  final encodedJson = json.encode(message.toJson());
  final jsonBytes = utf8.encode(encodedJson);

  // --- Bincode Benchmark ---
  final bincodeStart = DateTime.now().microsecondsSinceEpoch;
  for (int i = 0; i < iterations; i++) {
    final bytes = message.toBincode();
    final msg = TinyMessage(0)..loadFromBytes(bytes);
  }
  final bincodeEnd = DateTime.now().microsecondsSinceEpoch;
  final bincodeMs = (bincodeEnd - bincodeStart) / 1000.0;

  // --- JSON Benchmark ---
  final jsonStart = DateTime.now().microsecondsSinceEpoch;
  for (int i = 0; i < iterations; i++) {
    final encoded = json.encode(message.toJson());
    final decoded = json.decode(encoded);
  }
  final jsonEnd = DateTime.now().microsecondsSinceEpoch;
  final jsonMs = (jsonEnd - jsonStart) / 1000.0;

  // --- Result Summary ---
  print('--- Minimal Payload Benchmark (x$iterations) ---');
  print('Bincode total time: ${bincodeMs.toStringAsFixed(2)} ms');
  print('JSON total time:    ${jsonMs.toStringAsFixed(2)} ms');

  print('\n--- Size Comparison ---');
  print('Bincode size: ${encodedBincode.length} bytes'); // Should be 4
  print('JSON size:    ${jsonBytes.length} bytes');      // Usually > 10

  final saved = jsonBytes.length - encodedBincode.length;
  final percentSaved = ((saved / jsonBytes.length) * 100).toStringAsFixed(2);
  final totalSavedBytes = saved * iterations;
  final totalSavedKB = (totalSavedBytes / 1024).toStringAsFixed(2);
  final totalSavedMB = (totalSavedBytes / (1024 * 1024)).toStringAsFixed(2);

  print('\n--- Total Saved Over $iterations Items ---');
  print('Saved bytes:         $totalSavedBytes bytes');
  print('Saved kilobytes:     $totalSavedKB KB');
  print('Saved megabytes:     $totalSavedMB MB');

  // --- Minimal Payload Benchmark (x10000000) ---
  // Bincode total time: 598.91 ms
  // JSON total time:    5522.50 ms

  // --- Size Comparison ---
  // Bincode size: 4 bytes
  // JSON size:    15 bytes

  // --- Total Saved Over 10000000 Items ---
  // Saved bytes:         110000000 bytes
  // Saved kilobytes:     107421.88 KB
  // Saved megabytes:     104.90 MB
}
