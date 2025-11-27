import 'dart:async';

import 'package:llm_json_stream/json_stream_parser.dart';
import 'package:test/test.dart';

void main() {
  group('Error Handling Tests', () {
    test('complete JSON - all properties complete', () async {
      final json = '{"name":"Alice"}'; // Simple complete JSON
      final stream = streamTextInChunks(
        text: json,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      // Property should complete successfully
      final name = await parser
          .getStringProperty("name")
          .future
          .timeout(Duration(seconds: 1));

      expect(name, equals('Alice'));

      // The root map should also complete
      final rootMap =
          await parser.getMapProperty("").future.timeout(Duration(seconds: 1));
      expect(rootMap, isA<Map>());
    });

    test('complete JSON - arrays complete properly', () async {
      final json = '{"items":[1,2]}'; // Simple complete JSON
      final stream = streamTextInChunks(
        text: json,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      // Individual items should complete
      final item0 = await parser
          .getNumberProperty("items[0]")
          .future
          .timeout(Duration(seconds: 1));
      final item1 = await parser
          .getNumberProperty("items[1]")
          .future
          .timeout(Duration(seconds: 1));

      expect(item0, equals(1));
      expect(item1, equals(2));

      // The list should also complete
      final items = await parser
          .getListProperty("items")
          .future
          .timeout(Duration(seconds: 1));
      expect(items, equals([1, 2]));
    });

    test('unclosed string - missing closing quote', () async {
      final json = '{"name":"Alice';
      final stream = streamTextInChunks(
        text: json,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      // The string should timeout since it never closes
      final nameStream = parser.getStringProperty("name");
      await expectLater(
        nameStream.future.timeout(Duration(milliseconds: 500)),
        throwsA(isA<TimeoutException>()),
      );
    });

    // Note: Type mismatches (e.g., requesting a number as a string) will cause
    // TypeError exceptions to be thrown during stream processing. The parser
    // detects these at runtime when trying to cast property controllers.
    // These errors are logged but may not propagate to the future in all cases,
    // which is expected behavior for this streaming parser.

    test(
      'type mismatch - subscribing to same property with different types',
      () async {
        final json = '{"data":{"a":1}}';
        final stream = streamTextInChunks(
          text: json,
          chunkSize: 5,
          interval: Duration(milliseconds: 10),
        );
        final parser = JsonStreamParser(stream);

        // First subscription as map
        final mapStream = parser.getMapProperty("data");

        // Second subscription as list should throw
        expect(() => parser.getListProperty("data"), throwsA(isA<Exception>()));

        // Make sure the map subscription works
        final data = await mapStream.future.timeout(Duration(seconds: 1));
        expect(data, isA<Map>());
      },
    );

    test(
      'type mismatch - subscribing to same property with different types (reverse)',
      () async {
        final json = '{"data":[1,2,3]}';
        final stream = streamTextInChunks(
          text: json,
          chunkSize: 5,
          interval: Duration(milliseconds: 10),
        );
        final parser = JsonStreamParser(stream);

        // First subscription as list
        final listStream = parser.getListProperty("data");

        // Second subscription as map should throw
        expect(() => parser.getMapProperty("data"), throwsA(isA<Exception>()));

        // Make sure the list subscription works
        final data = await listStream.future.timeout(Duration(seconds: 1));
        expect(data, equals([1, 2, 3]));
      },
    );

    test('empty input', () async {
      final json = '';
      final stream = streamTextInChunks(
        text: json,
        chunkSize: 1,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      // Trying to access anything should timeout
      final rootMap = parser.getMapProperty("");
      await expectLater(
        rootMap.future.timeout(Duration(milliseconds: 500)),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('whitespace only input', () async {
      final json = '   \n\t  ';
      final stream = streamTextInChunks(
        text: json,
        chunkSize: 2,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      // Trying to access anything should timeout
      final rootMap = parser.getMapProperty("");
      await expectLater(
        rootMap.future.timeout(Duration(milliseconds: 500)),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('accessing non-existent property', () async {
      final json = '{"name":"Alice"}';
      final stream = streamTextInChunks(
        text: json,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      // Accessing a property that doesn't exist should timeout
      final ageStream = parser.getNumberProperty("age");
      await expectLater(
        ageStream.future.timeout(Duration(milliseconds: 500)),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('accessing out of bounds array index', () async {
      final json = '{"items":[1,2,3]}';
      final stream = streamTextInChunks(
        text: json,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      // Accessing an index that doesn't exist should timeout
      final item10Stream = parser.getNumberProperty("items[10]");
      await expectLater(
        item10Stream.future.timeout(Duration(milliseconds: 500)),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('nested structure completes properly', () async {
      final json = '{"a":{"b":1}}';
      final stream = streamTextInChunks(
        text: json,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      // Deep property should complete
      final b = await parser
          .getNumberProperty("a.b")
          .future
          .timeout(Duration(seconds: 1));
      expect(b, equals(1));
    });

    test('escaped characters in strings', () async {
      final json = r'{"text":"Hello \"World\"\nNew line\tTab"}';
      final stream = streamTextInChunks(
        text: json,
        chunkSize: 8,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final text = await parser
          .getStringProperty("text")
          .future
          .timeout(Duration(seconds: 1));

      // Should properly handle escape sequences
      expect(text, equals('Hello "World"\nNew line\tTab'));
    });

    test('negative numbers', () async {
      final json = '{"temp":-15}';
      final stream = streamTextInChunks(
        text: json,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final temp = await parser
          .getNumberProperty("temp")
          .future
          .timeout(Duration(seconds: 1));
      expect(temp, equals(-15));
    });

    test('decimal numbers', () async {
      final json = '{"price":19.99}';
      final stream = streamTextInChunks(
        text: json,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final price = await parser
          .getNumberProperty("price")
          .future
          .timeout(Duration(seconds: 1));
      expect(price, equals(19.99));
    });

    test('scientific notation numbers', () async {
      final json = '{"value":1.5e10}';
      final stream = streamTextInChunks(
        text: json,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final value = await parser
          .getNumberProperty("value")
          .future
          .timeout(Duration(seconds: 1));
      expect(value, equals(1.5e10));
    });

    test('boolean true value', () async {
      final json = '{"active":true}';
      final stream = streamTextInChunks(
        text: json,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final active = await parser
          .getBooleanProperty("active")
          .future
          .timeout(Duration(seconds: 1));
      expect(active, equals(true));
    });

    test('boolean false value', () async {
      final json = '{"active":false}';
      final stream = streamTextInChunks(
        text: json,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final active = await parser
          .getBooleanProperty("active")
          .future
          .timeout(Duration(seconds: 1));
      expect(active, equals(false));
    });

    test('null value', () async {
      final json = '{"value":null}';
      final stream = streamTextInChunks(
        text: json,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final value = await parser
          .getNullProperty("value")
          .future
          .timeout(Duration(seconds: 1));
      expect(value, equals(null));
    });

    test('empty object', () async {
      final json = '{"data":{}}';
      final stream = streamTextInChunks(
        text: json,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final data = await parser
          .getMapProperty("data")
          .future
          .timeout(Duration(seconds: 1));
      expect(data, isA<Map>());
      expect(data, isEmpty);
    });

    test('empty array', () async {
      final json = '{"items":[]}';
      final stream = streamTextInChunks(
        text: json,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final items = await parser
          .getListProperty("items")
          .future
          .timeout(Duration(seconds: 1));
      expect(items, isA<List>());
      expect(items, isEmpty);
    });

    test('string with only spaces', () async {
      final json = '{"text":"   "}';
      final stream = streamTextInChunks(
        text: json,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final text = await parser
          .getStringProperty("text")
          .future
          .timeout(Duration(seconds: 1));
      expect(text, equals('   '));
    });

    test('empty string', () async {
      final json = '{"text":""}';
      final stream = streamTextInChunks(
        text: json,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final text = await parser
          .getStringProperty("text")
          .future
          .timeout(Duration(seconds: 1));
      expect(text, equals(''));
    });
  });
}


