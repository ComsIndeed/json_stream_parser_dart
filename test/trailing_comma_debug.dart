import 'dart:async';
import 'package:llm_json_stream/json_stream_parser.dart';

void main() async {
  print('Testing trailing comma in list...\n');

  // Test 1: Simple trailing comma
  print('Test 1: {"test":[1,2,]}');
  try {
    final controller1 = StreamController<String>();
    final parser1 = JsonStreamParser(controller1.stream);

    final future1 =
        parser1.getListProperty('test').future.timeout(Duration(seconds: 2));

    controller1.add('{"test":[1,2,]}');
    controller1.close();

    final result1 = await future1;
    print('✓ Result: $result1\n');
  } catch (e) {
    print('✗ Error: $e\n');
  }

  // Test 2: With chunks
  print('Test 2: {"test":[1,2,]} with chunk size 5');
  try {
    final controller2 = StreamController<String>();
    final parser2 = JsonStreamParser(controller2.stream);

    final future2 =
        parser2.getListProperty('test').future.timeout(Duration(seconds: 2));

    final text = '{"test":[1,2,]}';
    for (int i = 0; i < text.length; i += 5) {
      final chunk =
          text.substring(i, i + 5 > text.length ? text.length : i + 5);
      print('  Chunk: "$chunk"');
      controller2.add(chunk);
      await Future.delayed(Duration(milliseconds: 10));
    }
    controller2.close();

    final result2 = await future2;
    print('✓ Result: $result2\n');
  } catch (e) {
    print('✗ Error: $e\n');
  }

  // Test 3: With very small chunks
  print('Test 3: {"test":[1,2,]} with chunk size 1');
  try {
    final controller3 = StreamController<String>();
    final parser3 = JsonStreamParser(controller3.stream);

    final future3 =
        parser3.getListProperty('test').future.timeout(Duration(seconds: 2));

    final text = '{"test":[1,2,]}';
    for (int i = 0; i < text.length; i++) {
      final chunk = text[i];
      print('  Char $i: "$chunk"');
      controller3.add(chunk);
      await Future.delayed(Duration(milliseconds: 10));
    }
    controller3.close();

    final result3 = await future3;
    print('✓ Result: $result3\n');
  } catch (e) {
    print('✗ Error: $e\n');
  }

  // Test 4: The ACTUAL test - getting first element from list with trailing comma
  print('Test 4: {"test":[1,2,]} getting test[0] with chunk size 1');
  try {
    final controller4 = StreamController<String>();
    final parser4 = JsonStreamParser(controller4.stream);

    final future4 = parser4
        .getNumberProperty('test[0]')
        .future
        .timeout(Duration(seconds: 2));

    final text = '{"test":[1,2,]}';
    for (int i = 0; i < text.length; i++) {
      final chunk = text[i];
      print('  Char $i: "$chunk"');
      controller4.add(chunk);
      await Future.delayed(Duration(milliseconds: 1));
    }
    controller4.close();

    final result4 = await future4;
    print('✓ Result: $result4\n');
  } catch (e) {
    print('✗ Error: $e\n');
  }

  // Test 5: Wait, the test gets "test" as a NUMBER, not an array element!
  print('Test 5: {"test":1} getting test as NUMBER');
  try {
    final controller5 = StreamController<String>();
    final parser5 = JsonStreamParser(controller5.stream);

    final future5 =
        parser5.getNumberProperty('test').future.timeout(Duration(seconds: 2));

    controller5.add('{"test":1}');
    controller5.close();

    final result5 = await future5;
    print('✓ Result: $result5\n');
  } catch (e) {
    print('✗ Error: $e\n');
  }

  // Test 6: The ACTUAL failing case - object with "test" key nested in list with trailing comma
  print('Test 6: Object inside array with trailing comma');
  try {
    final controller6 = StreamController<String>();
    final parser6 = JsonStreamParser(controller6.stream);

    final future6 = parser6
        .getNumberProperty('[0].test')
        .future
        .timeout(Duration(seconds: 2));

    final text = '[{"test":1},]';
    for (int i = 0; i < text.length; i++) {
      final chunk = text[i];
      print('  Char $i: "$chunk"');
      controller6.add(chunk);
      await Future.delayed(Duration(milliseconds: 1));
    }
    controller6.close();

    final result6 = await future6;
    print('✓ Result: $result6\n');
  } catch (e) {
    print('✗ Error: $e\n');
  }
}
