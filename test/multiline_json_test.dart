import 'dart:async';

import 'package:llm_json_stream/classes/json_stream_parser.dart';
import 'package:test/test.dart';

void main() {
  group('Multiline JSON Tests', () {
    test('Debug: Show characters in multiline JSON', () async {
      final json = '''
{
  "name": "Alice"
}
''';

      print('Characters in JSON:');
      for (int i = 0; i < json.length; i++) {
        final char = json[i];
        final code = char.codeUnitAt(0);
        final display = char == '\n'
            ? '\\n'
            : char == '\r'
                ? '\\r'
                : char == '\t'
                    ? '\\t'
                    : char;
        print('[$i] "$display" (code: $code)');
      }
    });

    test('Parse JSON with actual newline characters from triple-quoted string',
        () async {
      // This is the exact format the user described - using triple quotes
      // which creates actual newline characters in the string
      final json = '''
{
  "status": "success",
  "data": {
    "id": 123,
    "name": "Sample Item",
    "description": "This is a sample item from the API response.",
    "attributes": {
      "color": "red",
      "size": "large",
      "weight": "1.5kg"
    }
  },
  "message": "Item retrieved successfully."
}
''';

      print('JSON string length: ${json.length}');
      print('JSON content:');
      print(json);

      // Create a stream that emits character by character
      final stream = Stream.fromIterable(json.split(''));
      final parser = JsonStreamParser(stream);

      // Try to get some properties
      final statusFuture = parser.getStringProperty("status").future;
      final idFuture = parser.getNumberProperty("data.id").future;
      final nameFuture = parser.getStringProperty("data.name").future;
      final colorFuture =
          parser.getStringProperty("data.attributes.color").future;
      final messageFuture = parser.getStringProperty("message").future;

      // Wait for all properties with a timeout
      final results = await Future.wait([
        statusFuture,
        idFuture,
        nameFuture,
        colorFuture,
        messageFuture,
      ]).timeout(Duration(seconds: 5));

      expect(results[0], equals('success'));
      expect(results[1], equals(123));
      expect(results[2], equals('Sample Item'));
      expect(results[3], equals('red'));
      expect(results[4], equals('Item retrieved successfully.'));
    });

    test('Parse simple multiline JSON', () async {
      final json = '''
{
  "name": "Alice",
  "age": 30
}
''';

      final stream = Stream.fromIterable(json.split(''));
      final parser = JsonStreamParser(stream);

      final name = await parser
          .getStringProperty("name")
          .future
          .timeout(Duration(seconds: 2));
      final age = await parser
          .getNumberProperty("age")
          .future
          .timeout(Duration(seconds: 2));

      expect(name, equals('Alice'));
      expect(age, equals(30));
    });

    test('Parse multiline array', () async {
      final json = '''
{
  "items": [
    "first",
    "second",
    "third"
  ]
}
''';

      final stream = Stream.fromIterable(json.split(''));
      final parser = JsonStreamParser(stream);

      final first = await parser
          .getStringProperty("items[0]")
          .future
          .timeout(Duration(seconds: 2));
      final second = await parser
          .getStringProperty("items[1]")
          .future
          .timeout(Duration(seconds: 2));
      final third = await parser
          .getStringProperty("items[2]")
          .future
          .timeout(Duration(seconds: 2));

      expect(first, equals('first'));
      expect(second, equals('second'));
      expect(third, equals('third'));
    });

    test('Parse multiline nested objects', () async {
      final json = '''
{
  "user": {
    "profile": {
      "name": "Bob",
      "email": "bob@example.com"
    }
  }
}
''';

      final stream = Stream.fromIterable(json.split(''));
      final parser = JsonStreamParser(stream);

      final name = await parser
          .getStringProperty("user.profile.name")
          .future
          .timeout(Duration(seconds: 2));
      final email = await parser
          .getStringProperty("user.profile.email")
          .future
          .timeout(Duration(seconds: 2));

      expect(name, equals('Bob'));
      expect(email, equals('bob@example.com'));
    });

    test('JSON with leading whitespace (newlines, spaces, tabs)', () async {
      // This test specifically targets the bug where leading whitespace
      // before the root { or [ would cause the parser to fail
      final json = '\n\n  \t  {"name": "Charlie", "value": 42}';

      final stream = Stream.fromIterable(json.split(''));
      final parser = JsonStreamParser(stream);

      final name = await parser
          .getStringProperty("name")
          .future
          .timeout(Duration(seconds: 2));
      final value = await parser
          .getNumberProperty("value")
          .future
          .timeout(Duration(seconds: 2));

      expect(name, equals('Charlie'));
      expect(value, equals(42));
    });

    test('Array with leading whitespace', () async {
      final json = '\n\n  ["a", "b", "c"]';

      final stream = Stream.fromIterable(json.split(''));
      final parser = JsonStreamParser(stream);

      final first = await parser
          .getStringProperty("[0]")
          .future
          .timeout(Duration(seconds: 2));
      final second = await parser
          .getStringProperty("[1]")
          .future
          .timeout(Duration(seconds: 2));

      expect(first, equals('a'));
      expect(second, equals('b'));
    });

    test('Windows-style line endings (CRLF)', () async {
      // Test with \r\n (Windows line endings)
      final json = '{\r\n  "name": "Dave",\r\n  "age": 25\r\n}';

      final stream = Stream.fromIterable(json.split(''));
      final parser = JsonStreamParser(stream);

      final name = await parser
          .getStringProperty("name")
          .future
          .timeout(Duration(seconds: 2));
      final age = await parser
          .getNumberProperty("age")
          .future
          .timeout(Duration(seconds: 2));

      expect(name, equals('Dave'));
      expect(age, equals(25));
    });
  });
}
