// Copyright (c) 2025 Binurie
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import 'dart:convert';
import 'dart:typed_data';

import 'package:d_bincode/d_bincode.dart';

/// Benchmark Performance Disclaimer: The provided benchmark figures reflect
/// performance under specific, controlled test conditions. Actual results
/// in deployment may differ substantially due to variations in hardware
/// specifications, operating system, Dart runtime version, input data
/// characteristics, concurrency levels, and overall system load. These
/// benchmarks are intended for comparative insight and do not represent a
/// performance guarantee for any particular application. Users are advised
/// to conduct their own benchmarks relevant to their specific operational
/// context and requirements.

// ==========================================
//  Minimal Payload Benchmark (×100,000,000) 
// ==========================================

// Bincode Encode     | Total:   371.6ms | Avg:   0.004µs
// Bincode Decode     | Total:   889.2ms | Avg:   0.009µs
// JSON round‑trip    | Total: 50865.3ms | Avg:   0.509µs
// --------------------------------------------------
// Round‑trips        | Total:  1260.8ms | Avg:   0.013µs

// Speed‑ups vs JSON:
//   • Encode faster:      136.90×
//   • Decode faster:      57.20×
//   • Round‑trip faster:  40.34×

// Size Comparison:
//   • Bincode: 4 bytes
//   • JSON:    15 bytes
//   • JSON is 3.75× larger
//   • Bincode saves 73.3%

// Total Saved Over All Items:
//   • Bytes: 1,100,000,000
//   • KB:    1074218.75
//   • MB:    1049.04

class TinyMessage implements BincodeCodable {
  int number;
  TinyMessage(this.number);

  @override
  @pragma('vm:prefer-inline')
  void encode(BincodeWriter writer) {
    writer.writeU32(number);
  }

  @override
  @pragma('vm:prefer-inline')
  void decode(BincodeReader reader) {
    number = reader.readU32();
  }

  Map<String, dynamic> toJson() => {"number": number};
}



String _fmtInt(int n) =>
    n.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

void main() {
  const iterations = 100000000;
  final message = TinyMessage(1337);

  // ── One‑shot serialization to figure out sizes ─────────────────────
  final encodedBincode = BincodeWriter.encode(message);
  final binSize        = encodedBincode.length;
  final jsonString     = json.encode(message.toJson());
  final jsonBytes      = utf8.encode(jsonString);
  final jsonSize       = jsonBytes.length;

  // ── Prepare a writer that's exactly the right size ─────────────────
  final writer = BincodeWriter(initialCapacity: binSize);
  final needed = writer.measure(message);  // how many bytes we'll actually write
  writer.reserve(needed);                  // grow to exactly that, no copies in loop
  writer.reset();

  final reader = BincodeReader(Uint8List(needed));

  // ── Warm‑up (JIT, caches, etc.) ────────────────────────────────────
  for (var i = 0; i < 1000; i++) {
    writer.reset();
    message.encode(writer);
    reader.copyFrom(writer.toBytes());
    message.decode(reader);
    final tmp = json.encode(message.toJson());
    json.decode(tmp);
  }

  // ── Measure Bincode encode ────────────────────────────────────────
  final swEnc = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    writer.reset();
    message.encode(writer);
  }
  swEnc.stop();
  final totalEncUs = swEnc.elapsedMicroseconds.toDouble();
  final buf = writer.toBytes();

  // ── Measure Bincode decode ────────────────────────────────────────
  final swDec = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    reader.copyFrom(buf);
    message.decode(reader);
  }
  swDec.stop();
  final totalDecUs = swDec.elapsedMicroseconds.toDouble();

  // ── Measure JSON round‑trip ───────────────────────────────────────
  final swJson = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    final enc = json.encode(message.toJson());
    json.decode(enc);
  }
  swJson.stop();
  final totalJsonUs = swJson.elapsedMicroseconds.toDouble();

  // ── Compute stats ────────────────────────────────────────────────
  final avgEncUs    = totalEncUs    / iterations;
  final avgDecUs    = totalDecUs    / iterations;
  final avgJsonUs   = totalJsonUs   / iterations;
  final totalRtUs   = totalEncUs + totalDecUs;
  final avgRtUs     = totalRtUs     / iterations;

  final msEnc       = totalEncUs / 1000.0;
  final msDec       = totalDecUs / 1000.0;
  final msJson      = totalJsonUs  / 1000.0;
  final msRt        = totalRtUs    / 1000.0;

  final speedEnc    = msJson / msEnc;
  final speedDec    = msJson / msDec;
  final speedRt     = msJson / msRt;

  final sizeRatio   = jsonSize / binSize;
  final pctSaved    = (1 - binSize / jsonSize) * 100;
  final bytesSaved  = jsonSize - binSize;
  final totalSaved  = bytesSaved * iterations;
  final savedKB     = totalSaved / 1024;
  final savedMB     = savedKB / 1024;

  final title = ' Minimal Payload Benchmark (×${_fmtInt(iterations)}) ';
  print('\n${'=' * title.length}');
  print(title);
  print('${'=' * title.length}\n');

  void row(String label, double totalMs, double avgUs) {
    print('${label.padRight(18)} | '
          'Total: ${totalMs.toStringAsFixed(1).padLeft(7)}ms | '
          'Avg: ${avgUs.toStringAsFixed(3).padLeft(7)}µs');
  }

  row('Bincode Encode',    msEnc,   avgEncUs);
  row('Bincode Decode',    msDec,   avgDecUs);
  row('JSON round‑trip',   msJson,  avgJsonUs);
  print('-' * 50);
  row('Round‑trips',       msRt,    avgRtUs);

  print('\nSpeed‑ups vs JSON:');
  print('  • Encode faster:      ${speedEnc.toStringAsFixed(2)}×');
  print('  • Decode faster:      ${speedDec.toStringAsFixed(2)}×');
  print('  • Round‑trip faster:  ${speedRt.toStringAsFixed(2)}×');

  print('\nSize Comparison:');
  print('  • Bincode: ${_fmtInt(binSize)} bytes');
  print('  • JSON:    ${_fmtInt(jsonSize)} bytes');
  print('  • JSON is ${sizeRatio.toStringAsFixed(2)}× larger');
  print('  • Bincode saves ${pctSaved.toStringAsFixed(1)}%');

  print('\nTotal Saved Over All Items:');
  print('  • Bytes: ${_fmtInt(totalSaved)}');
  print('  • KB:    ${savedKB.toStringAsFixed(2)}');
  print('  • MB:    ${savedMB.toStringAsFixed(2)}\n');
}
