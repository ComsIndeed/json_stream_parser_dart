## 0.3.1
### Documentation
- Updated README import statements to use `llm_json_stream` package name

## 0.3.0
### Fixes:
- Fixed return types for getter methods
- Fixed exports
- Moved all files into `src/` folder for better package structure

## 0.2.3
### Changes
- Removed `JsonStreamParserController` as an export
- Add type casting getters for `PropertyStream` objects:
  - `asString()`
  - `asNum()`
  - `asBool()`
  - `asMap()`
  - `asList()`
### Documentation
- Updated README

## 0.2.2
### Added
- Added shorthands
- Added streams for lists and maps
### Documentation
- Updated README with new demos

## 0.2.1
### Documentation
- Updated README with new demos showcasing functionality

## 0.2.0

### Fixed
- Fixed `getMapProperty()` returning empty maps instead of populated content
- Fixed nested lists and maps within parent maps returning null values
- Fixed map property delegates not creating controllers for nested structures before child delegates
- Fixed array element maps (e.g., `items[0]`) not containing their full content

### Changed
- Map property delegates now collect all child values (primitives, maps, lists) before completing
- Improved property controller initialization order for complex nested structures

### Tests
- Added 166 comprehensive tests for map and list value retrieval across different nesting levels
- Tests cover various chunk sizes (1-50), timing intervals (0-200ms), and nesting depths (1-5 levels)

## 0.1.4
- Updated demo to use Github raw content URL

## 0.1.3
- Fixed demo not showing in Pub.dev

## 0.1.2
- Changelog fixes
- Added main example

## 0.1.1
- Minor documentation updates

## 0.1.0

### Added
- Initial release of streaming JSON parser optimized for LLM responses
- Path-based property subscriptions with chainable API
- Support for all JSON types: String, Number, Boolean, Null, Map, List
- Array index access and dynamic element callbacks
- Handles leading whitespace before root JSON elements

### Features
- Reactive property access: Subscribe to JSON properties as they complete in the stream
- Nested structures: Full support for deeply nested objects and arrays
- Chainable API: Access nested properties with fluent syntax
- Type safety: Typed property streams for all JSON types
- Memory safe: Proper stream lifecycle management and closed stream guards

### Fixed
- Root maps completing properly
- Nested maps completing correctly
- List chainable property access working
- "Cannot add event after closing" errors
- Proper delimiter handling between primitives and containers
- Child delegate completion detection
