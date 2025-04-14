// ============================================================
// Disclaimer: This source code is provided "as is", without any
// warranty of any kind, express or implied, including but not
// limited to the warranties of merchantability or fitness for
// a particular purpose.
// ============================================================


/// Base exception used for all bincode-related errors.
base class BincodeException implements Exception {
  /// A descriptive error message.
  final String message;

  /// An optional underlying error or additional context.
  final dynamic cause;

  /// Creates a new BincodeException with a message and optional cause.
  BincodeException(this.message, [this.cause]);

  @override
  String toString() {
    return cause == null
        ? 'BincodeException: $message'
        : 'BincodeException: $message\nCaused by: $cause';
  }
}

/// Thrown when an invalid boolean value is encountered during decoding.
/// 
/// According to the specification, boolean values should be encoded as
/// a single byte of value 0 (false) or 1 (true). Any other value triggers this error.
base class InvalidBooleanValueException extends BincodeException {
  /// The value that was read which is not a valid boolean.
  final int value;

  InvalidBooleanValueException(this.value)
      : super('Invalid boolean value encountered: $value. Expected 0 or 1.');
}

/// Thrown when an invalid option tag is encountered.
/// Option fields should be encoded with a single byte: 0 (None) or 1 (Some).
base class InvalidOptionTagException extends BincodeException {
  final int tag;
  InvalidOptionTagException(this.tag)
      : super('Invalid option tag encountered: $tag. Expected 0 (None) or 1 (Some).');
}

/// Thrown when a character’s encoding does not represent a valid Unicode scalar value.
/// 
/// This error should be thrown during deserialization when the character code 
/// lies in the surrogate range (0xD800–0xDFFF) or outside the valid Unicode range.
base class InvalidCharEncodingException extends BincodeException {
  /// The invalid code point encountered.
  final int codePoint;

  InvalidCharEncodingException(this.codePoint)
      : super(
          'Invalid char encoding: code point $codePoint is not a valid Unicode scalar value.'
        );
}

/// Thrown when the type of the data read does not match the expected type.
/// 
/// This is useful for generic type mismatches where the reader expected, for example,
/// an unsigned integer but the value decoded is incompatible.
base class TypeMismatchException extends BincodeException {
  /// The type that was expected (e.g. "u32", "f64", or "String").
  final String expected;

  /// The actual value that was encountered.
  final dynamic actual;

  TypeMismatchException(this.expected, this.actual)
      : super('Type mismatch: expected $expected, but got value: $actual');
}

/// Thrown when the end of the buffer is reached unexpectedly during decoding.
base class UnexpectedEndOfBufferException extends BincodeException {
  UnexpectedEndOfBufferException()
      : super('Unexpected end of buffer encountered during decoding.');
}

/// Thrown when an error occurs during UTF-8 decoding.
base class Utf8DecodingException extends BincodeException {
  Utf8DecodingException(String details)
      : super('UTF-8 decoding error: $details');
}


/// Base exception for errors that occur during writing.
base class BincodeWriteException extends BincodeException {
  BincodeWriteException(super.message, [super.cause]);
}

/// Thrown when a numeric value is outside the allowed range for its target type.
base class InvalidWriteRangeException extends BincodeWriteException {
  /// The value that was written.
  final int value;

  /// The type being written (for example, 'u64').
  final String type;

  /// The minimum allowed value.
  final dynamic minValue;

  /// The maximum allowed value.
  final dynamic maxValue;

  InvalidWriteRangeException(this.value, this.type, {this.minValue, this.maxValue})
      : super('Value $value is out of range for $type. Expected range: ${minValue ?? "-∞"} to ${maxValue ?? "∞"}');
}