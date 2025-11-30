import 'dart:async';

import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:test/test.dart';

void main() {
  group('Yap Filter - Stop parsing after root object completes', () {
    test('Parser stops after root map object closes', () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      final nameStream = parser.getStringProperty('name');

      // Send valid JSON
      controller.add('{"name": "Valid"}');
      await Future.delayed(Duration(milliseconds: 20));

      // Send trailing "Yap" / garbage that LLMs sometimes generate
      controller.add(' \n\n Here is some extra text I generated!');
      await Future.delayed(Duration(milliseconds: 20));

      // Parser should have completed gracefully without crashing
      expect(await nameStream.future, 'Valid');

      await controller.close();
      await parser.dispose();
    });

    test('Parser stops after root list closes', () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      final listStream = parser.getListProperty('');

      // Send valid JSON array
      controller.add('[1, 2, 3]');
      await Future.delayed(Duration(milliseconds: 20));

      // Send trailing garbage
      controller.add(' And here is more text after the array!');
      await Future.delayed(Duration(milliseconds: 20));

      // Parser should have completed gracefully
      final result = await listStream.future;
      expect(result, [1, 2, 3]);

      await controller.close();
      await parser.dispose();
    });

    test('Parser handles JSON followed by markdown code fence', () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      final titleStream = parser.getStringProperty('title');

      // Some LLMs wrap JSON in markdown code blocks
      controller.add('{"title": "Hello"}');
      await Future.delayed(Duration(milliseconds: 20));

      // Trailing markdown fence
      controller.add('\n```');
      await Future.delayed(Duration(milliseconds: 20));

      expect(await titleStream.future, 'Hello');

      await controller.close();
      await parser.dispose();
    });

    test('Parser handles JSON followed by explanation text', () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      final dataStream = parser.getMapProperty('');

      // Complete JSON followed by LLM "explanation"
      controller.add('{"key": "value"}');
      await Future.delayed(Duration(milliseconds: 20));

      controller.add(
          '\n\nI hope this JSON helps! Let me know if you need anything else.');
      await Future.delayed(Duration(milliseconds: 20));

      final result = await dataStream.future;
      expect(result['key'], 'value');

      await controller.close();
      await parser.dispose();
    });

    test('Nested structures complete before yap filter triggers', () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      final userStream = parser.getMapProperty('user');
      final nameStream = parser.getStringProperty('user.name');
      final ageStream = parser.getNumberProperty('user.age');

      // Send complete nested JSON
      controller.add('{"user": {"name": "Alice", "age": 30}}');
      await Future.delayed(Duration(milliseconds: 20));

      // Send yap
      controller.add(' There you go!');
      await Future.delayed(Duration(milliseconds: 20));

      expect(await nameStream.future, 'Alice');
      expect(await ageStream.future, 30);
      final user = await userStream.future;
      expect(user['name'], 'Alice');
      expect(user['age'], 30);

      await controller.close();
      await parser.dispose();
    });

    test('Parser with closeOnRootComplete=false continues parsing', () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(
        controller.stream,
        closeOnRootComplete: false,
      );

      final nameStream = parser.getStringProperty('name');

      // Send valid JSON
      controller.add('{"name": "Test"}');
      await Future.delayed(Duration(milliseconds: 20));

      expect(await nameStream.future, 'Test');

      // Parser should still be active (not disposed)
      // We can verify by checking that sending more data doesn't crash
      controller.add(' Extra text');
      await Future.delayed(Duration(milliseconds: 20));

      await controller.close();
      await parser.dispose();
    });

    test('Chunked JSON completes correctly before yap', () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      final messageStream = parser.getStringProperty('message');

      // Send JSON in chunks
      controller.add('{"mess');
      await Future.delayed(Duration(milliseconds: 10));
      controller.add('age": "Hel');
      await Future.delayed(Duration(milliseconds: 10));
      controller.add('lo World"}');
      await Future.delayed(Duration(milliseconds: 20));

      // Send yap after complete JSON
      controller.add(' -- generated by AI');
      await Future.delayed(Duration(milliseconds: 20));

      expect(await messageStream.future, 'Hello World');

      await controller.close();
      await parser.dispose();
    });
  });
}
