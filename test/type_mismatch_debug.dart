import 'dart:async';
import 'package:llm_json_stream/llm_json_stream.dart';

void main() async {
  print('Testing type mismatch: getting number from array property\n');

  // Test: Try to get a number from an array property
  print('Test: {"test":[1,2]} trying to getNumberProperty("test")');
  try {
    final controller = StreamController<String>();
    final parser = JsonStreamParser(controller.stream);

    final future =
        parser.getNumberProperty('test').future.timeout(Duration(seconds: 2));

    controller.add('{"test":[1,2]}');
    controller.close();

    final result = await future;
    print('✓ Result: $result\n');
  } catch (e) {
    print('✗ Error: $e\n');
  }

  // Test with trailing comma
  print('Test: {"test":[1,2,]} trying to getNumberProperty("test")');
  try {
    final controller2 = StreamController<String>();
    final parser2 = JsonStreamParser(controller2.stream);

    final future2 =
        parser2.getNumberProperty('test').future.timeout(Duration(seconds: 2));

    controller2.add('{"test":[1,2,]}');
    controller2.close();

    final result2 = await future2;
    print('✓ Result: $result2\n');
  } catch (e) {
    print('✗ Error: $e\n');
  }
}


