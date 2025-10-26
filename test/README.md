# JSON Stream Parser - Test Suite

A comprehensive test suite for validating streaming JSON parsing behavior, designed to simulate LLM inference response patterns.

## 📋 Test Organization

### Test Files Structure

```
test/
├── json_stream_parser_all_tests.dart    # Main test runner
├── helpers/
│   └── test_helpers.dart                # Utility functions and test data
└── properties/
    ├── string_property_test.dart        # String value tests
    ├── number_property_test.dart        # Number value tests
    ├── boolean_property_test.dart       # Boolean value tests
    ├── null_property_test.dart          # Null value tests
    ├── map_flat_property_test.dart      # Flat map tests
    ├── map_nested_property_test.dart    # Nested map tests
    ├── list_flat_property_test.dart     # Flat list tests
    └── list_nested_property_test.dart   # Nested list tests
```

## 🎯 What's Being Tested

Each test validates that:
1. JSON values can be serialized (stringified/jsonified)
2. Serialized strings can be split into chunks
3. Chunks can be emitted individually in a stream
4. Accumulated chunks match the original JSON string
5. Parsed JSON matches the expected value

This simulates the behavior of LLM inference APIs that stream responses in chunks.

## 🔤 String Property Tests

Tests for all string edge cases:
- **Basic strings**: Simple, with spaces, empty strings
- **Escape sequences**: `\n`, `\t`, `\"`, `\\`, etc.
- **Unicode**: Emojis, CJK characters, mixed scripts
- **Long strings**: 100, 1000+ characters
- **Special cases**: URLs, JSON-like content, special chars
- **Edge cases**: Chunk boundaries on escape sequences and quotes

## 🔢 Number Property Tests

Tests for numeric values:
- **Integers**: Positive, negative, zero, large numbers
- **Floats**: Decimals, small decimals, trailing zeros
- **Scientific notation**: `1e10`, `1E-10`, etc.
- **Edge cases**: Chunk boundaries on decimal points, minus signs, exponents

## ✅ Boolean Property Tests

Tests for boolean values:
- Simple `true` and `false` values
- Chunk boundaries splitting boolean keywords
- Booleans in arrays and objects

## ⚪ Null Property Tests

Tests for null values:
- Simple `null` values
- Chunk boundaries splitting "null" keyword
- Nulls in arrays and objects
- Multiple nulls in complex structures

## 📦 Flat Map Property Tests

Tests for simple map structures:
- **Empty maps**: `{}`
- **String-to-string**: Basic key-value pairs
- **Mixed types**: Strings, numbers, booleans, nulls
- **Many properties**: 10, 20, 50+ properties
- **Special keys**: Single char, long names, underscores, numbers

## 🗂️ Nested Map Property Tests

Tests for complex map structures:
- **Simple nesting**: One level deep
- **Deep nesting**: 3, 5, 10+ levels
- **Maps with lists**: Arrays as values
- **Maps with nested objects**: Multi-level object nesting
- **Mixed nesting**: Complex combinations

## 📋 Flat List Property Tests

Tests for simple list structures:
- **Empty lists**: `[]`
- **String lists**: Various string values
- **Number lists**: Integers, floats, scientific notation
- **Boolean lists**: True/false values
- **Null lists**: Multiple null values
- **Mixed lists**: All primitive types together

## 🎯 Nested List Property Tests

Tests for complex list structures:
- **Lists with objects**: Arrays of maps
- **Nested lists**: 2D, 3D arrays
- **Lists with nested objects**: Objects containing arrays/objects
- **Complex structures**: Mixed nesting patterns
- **Matrix-like**: 10x10 arrays

## 🚀 Running Tests

### Run All Tests
```bash
dart test
```

### Run Specific Test File
```bash
# String tests only
dart test test/properties/string_property_test.dart

# Map tests only
dart test test/properties/map_flat_property_test.dart

# All tests via main runner
dart test test/json_stream_parser_all_tests.dart
```

### Run Specific Test Group
```bash
# Run only basic string tests
dart test -n "Basic Strings"

# Run only nested map tests
dart test -n "Nested Maps"
```

### Run with Verbose Output

Edit the test file and change:
```dart
const verbose = false; // Set to true to see detailed output
```

When `verbose = true`, tests will print:
- Each chunk being emitted
- Accumulated values
- Expected values
- Test results

## 📊 Test Features

### Multiple Chunk Sizes
Each test runs with different chunk sizes:
- **Quick**: `[4, 16]` - Fast tests with common sizes
- **Standard**: `[1, 2, 4, 8, 16]` - Comprehensive coverage
- **Extreme**: `[1, 3, 7, 13, 100]` - Edge case testing

### Edge Case Testing
- Chunk boundaries on special characters
- Chunk boundaries on escape sequences
- Very small chunks (1 character)
- Very large chunks (entire string)

### Stress Testing
- Large data structures (100+ elements)
- Very long strings (1000+ chars)
- Deep nesting (10+ levels)
- With reasonable timeouts (10 seconds)

## 🛠️ Test Utilities

### `StreamAccumulator<T>`
Accumulates stream values for validation:
```dart
final accumulator = StreamAccumulator<String>();
await for (final chunk in stream) {
  accumulator.add(chunk);
}
final result = accumulator.getAccumulatedString();
```

### `JsonStreamTestRunner`
Simulates streaming with configurable chunk sizes:
```dart
final runner = JsonStreamTestRunner(
  jsonString: '{"key":"value"}',
  chunkSize: 4,
  interval: Duration(microseconds: 1),
  verbose: true, // Enable detailed output
);
final stream = runner.createChunkStream();
```

### `JsonTestData`
Pre-defined test data for common scenarios:
```dart
JsonTestData.simpleString      // "hello"
JsonTestData.flatMapMixedValues()  // {...}
JsonTestData.nestedLists()     // [[...], [...]]
```

### `TestPrinter`
Pretty printing for test output:
```dart
TestPrinter.printTestGroup('My Tests');
TestPrinter.printTestCase('Test name');
TestPrinter.printChunk('chunk', 1, 10);
```

## 📈 Test Coverage

The test suite covers:
- ✅ All JSON primitive types (string, number, boolean, null)
- ✅ All JSON complex types (object, array)
- ✅ All nesting combinations
- ✅ Edge cases and chunk boundaries
- ✅ Stress tests for large data
- ✅ Multiple chunk sizes per test
- ✅ Unicode and special characters
- ✅ Escape sequences

## 💡 Tips for Development

1. **Enable verbose output** when debugging specific tests
2. **Run specific test files** during development for faster feedback
3. **Use test groups** to focus on specific scenarios
4. **Add custom chunk sizes** to test specific edge cases
5. **Check timeouts** for stress tests if they're failing

## 🎨 Example Test Output

When `verbose = true`:
```
🧪 Running test: String with spaces - "hello world"
   Testing with chunk size: 4
   📤 Chunk 1/4: ""hel"
   📤 Chunk 2/4: "lo w"
   📤 Chunk 3/4: "orld"
   📤 Chunk 4/4: """
   Accumulated: "hello world"
   Expected: "hello world"
   ✅ Test passed!
```

## 🔍 Debugging Failed Tests

If a test fails:
1. Enable verbose output for that test
2. Check the chunk boundaries
3. Verify the expected value matches the input
4. Look for encoding/escaping issues
5. Check if chunk size causes unexpected splits

## 📝 Adding New Tests

To add a new test:

1. Choose the appropriate test file
2. Add to existing group or create new group
3. Use helper functions for consistency:
```dart
runStringTest(
  testName: 'My new test',
  jsonString: '"test value"',
  expectedValue: 'test value',
);
```

## 🏆 Best Practices

- Test edge cases and boundaries
- Use multiple chunk sizes
- Test with real-world data patterns
- Include stress tests for large data
- Use descriptive test names
- Group related tests together
- Add comments for complex test cases

---

Happy testing! 🧪✨
