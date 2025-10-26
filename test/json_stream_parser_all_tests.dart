/// Comprehensive Test Suite for JSON Stream Parser
///
/// This test suite validates the streaming behavior of JSON parsing by:
/// 1. Taking serialized JSON values
/// 2. Splitting them into chunks of various sizes
/// 3. Emitting chunks individually via streams (simulating LLM inference responses)
/// 4. Validating that accumulated chunks match expected values
///
/// Test Organization:
/// - helpers/test_helpers.dart: Utility functions for testing
/// - properties/string_property_test.dart: String value tests
/// - properties/number_property_test.dart: Number value tests
/// - properties/boolean_property_test.dart: Boolean value tests
/// - properties/null_property_test.dart: Null value tests
/// - properties/map_flat_property_test.dart: Flat map tests
/// - properties/map_nested_property_test.dart: Nested map tests
/// - properties/list_flat_property_test.dart: Flat list tests
/// - properties/list_nested_property_test.dart: Nested list tests
///
/// Running Tests:
/// - Run all tests: `dart test`
/// - Run specific file: `dart test test/properties/string_property_test.dart`
/// - Run with verbose output: Change `verbose` flag to `true` in test files
/// - Run specific test group: `dart test -n "Basic Strings"`
///
/// Test Features:
/// - Multiple chunk sizes tested for each scenario
/// - Edge case testing (chunk boundaries, escape sequences, etc.)
/// - Stress testing (large data structures, deep nesting)
/// - Validation of both accumulated chunks and parsed JSON values
library;

import 'package:test/test.dart';

// Import all test files
import 'properties/string_property_test.dart' as string_tests;
import 'properties/number_property_test.dart' as number_tests;
import 'properties/boolean_property_test.dart' as boolean_tests;
import 'properties/null_property_test.dart' as null_tests;
import 'properties/map_flat_property_test.dart' as map_flat_tests;
import 'properties/map_nested_property_test.dart' as map_nested_tests;
import 'properties/list_flat_property_test.dart' as list_flat_tests;
import 'properties/list_nested_property_test.dart' as list_nested_tests;

void main() {
  print('\n${'=' * 70}');
  print('🧪 JSON STREAM PARSER - COMPREHENSIVE TEST SUITE');
  print('=' * 70);
  print('\nTesting streaming JSON parsing with various chunk sizes');
  print('Simulating LLM inference response patterns\n');

  group('🔤 String Property Tests', () {
    string_tests.main();
  });

  group('🔢 Number Property Tests', () {
    number_tests.main();
  });

  group('✅ Boolean Property Tests', () {
    boolean_tests.main();
  });

  group('⚪ Null Property Tests', () {
    null_tests.main();
  });

  group('📦 Map Property Tests (Flat)', () {
    map_flat_tests.main();
  });

  group('🗂️ Map Property Tests (Nested)', () {
    map_nested_tests.main();
  });

  group('📋 List Property Tests (Flat)', () {
    list_flat_tests.main();
  });

  group('🎯 List Property Tests (Nested)', () {
    list_nested_tests.main();
  });
}
