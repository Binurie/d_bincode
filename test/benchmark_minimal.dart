// ignore_for_file: unused_local_variable

/*
#######################################################################
# DISCLAIMER: This benchmark is for illustrative and comparative use. #
# Results are approximate and depend on runtime conditions such as    #
# device hardware, Dart VM optimizations, system load, and compiler.  #
#                                                                     #
# Do NOT use this as a definitive performance guarantee. Always test  #
# and profile with your own data and environment for accurate results.#
#                                                                     #
# This package can be definitely optiomized much more and this is the # 
# state as is without any warranty.                                   #
#######################################################################
*/

import 'dart:convert';
import 'dart:typed_data';

import 'package:d_bincode/d_bincode.dart';

/// A minimal message that only contains an unsigned 32-bit integer.
class TinyMessage implements BincodeCodable {
  int number;

  TinyMessage(this.number);

  @override
  Uint8List toBincode({bool unchecked = false, int initialCapacity = 128}) {
    final writer = BincodeWriter();
    writer.writeU32(number); // 4-byte unsigned integer
    return writer.toBytes();
  }

  @override
  void fromBincode(Uint8List bytes, {bool unsafe = false}) {
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

  for (int i = 0; i < 1000; i++) {
    message.toBincode();
    TinyMessage(0).fromBincode(encodedBincode);
    json.encode(message.toJson());
    json.decode(encodedJson);
  }

  // --- Bincode Benchmark ---
  final bincodeStopwatch = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    final bytes = message.toBincode();
    TinyMessage(0).fromBincode(bytes);
  }
  bincodeStopwatch.stop();
  final bincodeTime = bincodeStopwatch.elapsedMilliseconds;

  // --- JSON Benchmark ---
  final jsonStopwatch = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    final enc = json.encode(message.toJson());
    json.decode(enc);
  }
  jsonStopwatch.stop();
  final jsonTime = jsonStopwatch.elapsedMilliseconds;

  print('\n${'-' * 40}');
  print(' Minimal Payload Benchmark (x$iterations) ');
  print('-' * 40);
  print('Bincode: ${bincodeTime.toString().padLeft(5)} ms');
  print('JSON:    ${jsonTime.toString().padLeft(5)} ms');

  if (jsonTime > 0) {
    final speedFactor = jsonTime / bincodeTime;
    final percentageFaster = ((speedFactor - 1) * 100).toStringAsFixed(1);
    print(
        'Bincode is ${speedFactor.toStringAsFixed(2)}x faster ($percentageFaster%)');
  } else {
    print('JSON time is zero, cannot calculate speed difference.');
  }
  print('${'-' * 40}\n');

  print('-' * 40);
  print(' Size Comparison ');
  print('-' * 40);
  print('Bincode size: ${encodedBincode.length.toString().padLeft(5)} bytes');
  print('JSON size:    ${jsonBytes.length.toString().padLeft(5)} bytes');

  if (jsonBytes.isNotEmpty) {
    final sizeDifference = jsonBytes.length - encodedBincode.length;
    final percentageSmaller =
        ((sizeDifference / jsonBytes.length) * 100).toStringAsFixed(1);
    print('Bincode is $percentageSmaller% smaller');
  } else if (encodedBincode.isNotEmpty) {
    print('JSON size is zero, Bincode is infinitely smaller.');
  } else {
    print('Both Bincode and JSON sizes are zero.');
  }
  print('${'-' * 40}\n');

  final savedBytes = jsonBytes.length - encodedBincode.length;
  final totalSaved = savedBytes * iterations;
  final savedKB = totalSaved / 1024;
  final savedMB = savedKB / 1024;

  print('-' * 40);
  print(' Total Saved Over $iterations Items ');
  print('-' * 40);
  print('Saved:    ${totalSaved.toString().padLeft(10)} bytes');
  print('         ${savedKB.toStringAsFixed(2).padLeft(10)} KB');
  print('         ${savedMB.toStringAsFixed(2).padLeft(10)} MB');
  print('${'-' * 40}\n');

// ----------------------------------------
//  Minimal Payload Benchmark (x10000000) UNSAFE
// ----------------------------------------
// Bincode:   623 ms
// JSON:     5106 ms
// Bincode is 8.20x faster (719.6%)
// ----------------------------------------

// ----------------------------------------
//  Size Comparison
// ----------------------------------------
// Bincode size:     4 bytes
// JSON size:       15 bytes
// Bincode is 73.3% smaller
// ----------------------------------------

// ----------------------------------------
//  Total Saved Over 10000000 Items
// ----------------------------------------
// Saved:     110000000 bytes
//           107421.88 KB
//              104.90 MB
// ----------------------------------------

// ----------------------------------------
//  Minimal Payload Benchmark (x10000000) SAFE
// ----------------------------------------
// Bincode:   752 ms
// JSON:     5123 ms
// Bincode is 6.81x faster (581.3%)
// ----------------------------------------

// ----------------------------------------
//  Size Comparison
// ----------------------------------------
// Bincode size:     4 bytes
// JSON size:       15 bytes
// Bincode is 73.3% smaller
// ----------------------------------------

// ----------------------------------------
//  Total Saved Over 10000000 Items
// ----------------------------------------
// Saved:     110000000 bytes
//           107421.88 KB
//              104.90 MB
// ----------------------------------------
}
