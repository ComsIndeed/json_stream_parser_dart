# Bug Fix: Leading Whitespace Handling

**Date**: November 14, 2025  
**Issue**: Parser fails to handle JSON with leading whitespace  
**Status**: ✅ Fixed

## Problem

The parser could not handle JSON strings with leading whitespace characters (newlines, tabs, spaces) before the root `{` or `[` character. This was particularly problematic when using Dart's triple-quoted string syntax (`'''`), which naturally includes leading and trailing newlines.

### Example that would fail:

```dart
final json = '''
{
  "name": "Alice",
  "age": 30
}
''';
```

The JSON above starts with a `\n` character, and the parser would never create the root delegate because it was only checking for `{` or `[` characters without first skipping whitespace.

## Root Cause

In `JsonStreamParser._parseChunk()` method:

```dart
void _parseChunk(String chunk) {
  for (final character in chunk.split('')) {
    if (_rootDelegate != null) {
      _rootDelegate!.addCharacter(character);
      continue;
    }

    // BUG: No whitespace skipping here!
    if (character == '{') {
      _rootDelegate = MapPropertyDelegate(...);
      _rootDelegate!.addCharacter(character);
    }

    if (character == "[") {
      _rootDelegate = ListPropertyDelegate(...);
      _rootDelegate!.addCharacter(character);
    }

    continue;
  }
  _rootDelegate?.onChunkEnd();
}
```

When `_rootDelegate` is `null`, the parser checks if the character is `{` or `[`, but if it's whitespace, it does nothing. The root delegate never gets created, and the JSON never gets parsed.

## Solution

Added whitespace skipping logic before checking for root element:

```dart
void _parseChunk(String chunk) {
  for (final character in chunk.split('')) {
    if (_rootDelegate != null) {
      _rootDelegate!.addCharacter(character);
      continue;
    }

    // FIX: Skip leading whitespace before the root element
    if (character == ' ' ||
        character == '\t' ||
        character == '\n' ||
        character == '\r') {
      continue;
    }

    if (character == '{') {
      _rootDelegate = MapPropertyDelegate(...);
      _rootDelegate!.addCharacter(character);
    }

    if (character == "[") {
      _rootDelegate = ListPropertyDelegate(...);
      _rootDelegate!.addCharacter(character);
    }

    continue;
  }
  _rootDelegate?.onChunkEnd();
}
```

## Testing

Added comprehensive test suite in `test/multiline_json_test.dart`:

1. ✅ Parse JSON with actual newline characters from triple-quoted string
2. ✅ Parse simple multiline JSON
3. ✅ Parse multiline array
4. ✅ Parse multiline nested objects
5. ✅ JSON with leading whitespace (newlines, spaces, tabs)
6. ✅ Array with leading whitespace
7. ✅ Windows-style line endings (CRLF - `\r\n`)
8. ✅ Debug test showing character codes

**Result**: All 83 tests passing (75 original + 8 new multiline tests)

## Files Changed

1. `lib/classes/json_stream_parser.dart` - Added whitespace skipping in `_parseChunk()`
2. `test/multiline_json_test.dart` - New comprehensive test suite
3. `example/multiline_json_example.dart` - Example demonstrating the fix
4. `README.md` - Updated test count and added note about multiline JSON support
5. `CHANGELOG.md` - Documented the fix in version 1.0.1

## Impact

- **Backward compatible**: Does not break any existing functionality
- **Standard JSON handling**: Properly handles leading whitespace per JSON spec
- **Developer experience**: Works seamlessly with Dart's triple-quoted strings
- **Real-world usage**: Better support for formatted/pretty-printed JSON from APIs
