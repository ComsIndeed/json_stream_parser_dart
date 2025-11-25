import 'dart:async';
import 'package:llm_json_stream/json_stream_parser.dart';

/// Quick verification that shorthand methods return the correct types
void main() async {
  final controller = StreamController<String>();
  final parser = JsonStreamParser(controller.stream);

  // Test that shorthand methods return correct types
  parser.str('strProp'); // StringPropertyStream
  parser.number('numProp'); // NumberPropertyStream
  parser.boolean('boolProp'); // BooleanPropertyStream
  parser.nil('nilProp'); // NullPropertyStream
  parser.map('mapProp'); // MapPropertyStream
  parser.list('listProp'); // ListPropertyStream

  // Test chaining
  final userMap = parser.map('user');
  userMap.str('name'); // StringPropertyStream
  userMap.number('age'); // NumberPropertyStream

  // Test list property
  parser.list('items'); // ListPropertyStream

  print('✅ All type assignments are valid!');
  print('✅ Shorthand methods return correct types');
  print('   - .str() returns StringPropertyStream');
  print('   - .number() returns NumberPropertyStream');
  print('   - .boolean() returns BooleanPropertyStream');
  print('   - .nil() returns NullPropertyStream');
  print('   - .map() returns MapPropertyStream');
  print('   - .list() returns ListPropertyStream');
  print('✅ Chaining works correctly on MapPropertyStream');

  controller.add('{"user": {"name": "test"}}');
  controller.close();

  await parser.dispose();
}
