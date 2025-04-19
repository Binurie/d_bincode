## 1.0.0

- Initial version.

## 1.0.1

- Added nested objects/classes support - writeNested,  writeOptionalNested, readNestedObject, readOptionalNestedObject.
- `toBincode()` / `fromBincode()` API inherit from BincodeEncodable / BincodeDecodable.
- Added error handling and validation.
- Removed `Debuggable` and `Fluent` APIs.
- Added benchmarks (speed & size) vs JSON example.
- Improved documentation and fixed lints for pub.dev compliance.

## 2.0.0

### Breaking Changes

* Removed `length` parameter from `read*List` methods (now reads length prefix). Update calls by removing the argument.
* Renamed `loadFromBytes` to `fromBincode`.

### Added

* Optional `unsafe`/`unchecked` flags for `BincodeReader`/`BincodeWriter` to bypass checks for performance.
* New `readNestedObjectForFixed` and `readOptionNestedObjectForFixed` methods for fixed-size object reading.
* `readRawBytes(int length)` method.

### Deprecated

* `readNestedObject` / `readOptionNestedObject`. Use `ForCollection` or `ForFixed` variants instead.

### Removed

* Internal implementation classes (`Builder`, `Wrapper`, `Exception`) from public API.


## 3.0.0

### Breaking Changes

* BincodeEncodable & BincodeDecodable use now encode(BincodeReader reader) and decode(BincodeWriter writer) - from and toBincode are removed.
 
### Added

* More static methods for BincodeWriter and BincodeReader
* Improved performance by alot by removing Wrapper overheat and overall impls of the methods 
* More methods for BincodeWriter and BincodeReader for manual buffer modifications

### Removed

* ByteDataWrapper removed to increase performance
* String Encode and Decode Method's and Enums removed - only utf8/ASCII Supported
* Less Exceptions and checks
* euc dependency got removed