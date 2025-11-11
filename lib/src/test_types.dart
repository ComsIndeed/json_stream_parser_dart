import 'dart:convert';

import 'package:json_stream_parser/classes/json_stream_parser.dart';
import 'package:json_stream_parser/utilities/stream_text_in_chunks.dart';

void main() async {
  print('Testing type parameters for getListProperty...\n');

  // Test 1: List<int>
  await testIntList();

  // Test 2: List<String>
  await testStringList();

  // Test 3: List<Object?> (default/flexible)
  await testMixedList();

  print('\nAll tests completed successfully!');
}

Future<void> testIntList() async {
  print('Test 1: List<int>');
  final map = {
    "numbers": [1, 2, 3, 4, 5],
  };

  final json = jsonEncode(map);
  final stream = streamTextInChunks(
    text: json,
    chunkSize: 10,
    interval: Duration(milliseconds: 10),
  );

  final parser = JsonStreamParser(stream);
  final result = await parser.getListProperty<int>('numbers').future;

  print('  Result: $result');
  print('  Type: ${result.runtimeType}');
  assert(result.length == 5, 'Expected 5 elements');
  print('  ✓ Passed\n');
}

Future<void> testStringList() async {
  print('Test 2: List<String>');
  final map = {
    "names": ["Alice", "Bob", "Charlie"],
  };

  final json = jsonEncode(map);
  final stream = streamTextInChunks(
    text: json,
    chunkSize: 10,
    interval: Duration(milliseconds: 10),
  );

  final parser = JsonStreamParser(stream);
  final result = await parser.getListProperty<String>('names').future;

  print('  Result: $result');
  print('  Type: ${result.runtimeType}');
  assert(result.length == 3, 'Expected 3 elements');
  print('  ✓ Passed\n');
}

Future<void> testMixedList() async {
  print('Test 3: List<Object?> (mixed types)');
  final map = {
    "mixed": [1, "two", true, null, 5.5],
  };

  final json = jsonEncode(map);
  final stream = streamTextInChunks(
    text: json,
    chunkSize: 10,
    interval: Duration(milliseconds: 10),
  );

  final parser = JsonStreamParser(stream);
  // No type parameter - should default to Object?
  final result = await parser.getListProperty('mixed').future;

  print('  Result: $result');
  print('  Type: ${result.runtimeType}');
  assert(result.length == 5, 'Expected 5 elements');
  assert(result[0] == 1, 'Expected first element to be 1');
  assert(result[1] == "two", 'Expected second element to be "two"');
  assert(result[2] == true, 'Expected third element to be true');
  assert(result[3] == null, 'Expected fourth element to be null');
  assert(result[4] == 5.5, 'Expected fifth element to be 5.5');
  print('  ✓ Passed\n');
}
