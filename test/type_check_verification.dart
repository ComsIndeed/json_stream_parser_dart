import 'dart:async';
import 'package:llm_json_stream/json_stream_parser.dart';

/// Quick verification that shorthand methods return the correct types
void main() async {
  final controller = StreamController<String>();
  final parser = JsonStreamParser(controller.stream);

  // Test that shorthand methods return correct types
  StringPropertyStream str = parser.str('strProp');
  NumberPropertyStream num = parser.number('numProp');
  BooleanPropertyStream bool = parser.boolean('boolProp');
  NullPropertyStream nil = parser.nil('nilProp');
  MapPropertyStream map = parser.map('mapProp');
  ListPropertyStream list = parser.list('listProp');

  // Test chaining
  MapPropertyStream userMap = parser.map('user');
  StringPropertyStream userName = userMap.str('name');
  NumberPropertyStream userAge = userMap.number('age');

  // Test list property
  ListPropertyStream items = parser.list('items');

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
