// ============================================================
// Disclaimer: This source code is provided "as is", without any
// warranty of any kind, express or implied, including but not
// limited to the warranties of merchantability or fitness for
// a particular purpose.
// ============================================================

import 'dart:convert';

import 'package:euc/jis.dart';

import '../enums.dart';

  /// Decodes a list of integer [codes] into a string using the specified [encoding].
  ///
  /// For UTF‑8, uses [utf8.decode] with malformed sequences allowed.
  /// For UTF‑16, converts character codes directly.
  /// For Shift‑JIS, uses the [ShiftJIS] decoder from the 'euc' package.
  String decodeString(List<int> codes, StringEncoding encoding) {
    switch (encoding) {
      case StringEncoding.utf8:
        return utf8.decode(codes, allowMalformed: true);
      case StringEncoding.utf16:
        return String.fromCharCodes(codes);
      case StringEncoding.shiftJis:
        return ShiftJIS().decode(codes);
    }
  }


/// Encodes a string [str] into a list of integers using the specified [encoding].
///
/// For UTF‑8, returns the UTF‑8 encoded bytes.
/// For UTF‑16, returns the character codes.
/// For Shift‑JIS, uses the [ShiftJIS] encoder from the 'euc' package.
List<int> encodeString(String str, StringEncoding encoding) {
  switch (encoding) {
    case StringEncoding.utf8:
      return utf8.encode(str);
    case StringEncoding.utf16:
      return str.codeUnits;
    case StringEncoding.shiftJis:
      return ShiftJIS().encode(str);
  }
}
