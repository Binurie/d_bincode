// ============================================================
// Disclaimer: This source code is provided "as is", without any
// warranty of any kind, express or implied, including but not
// limited to the warranties of merchantability or fitness for
// a particular purpose.
// ============================================================

/// Supported string encodings for bincode serialization/deserialization.
/// UTF-8 full supported, other encodings based on configurations from the other side.
enum StringEncoding {
  /// UTF‑8 encoding.
  utf8,

  /// UTF‑16 encoding.
  utf16,

  /// Shift-JIS encoding.
  shiftJis,
}