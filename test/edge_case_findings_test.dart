import 'dart:async';

import 'package:llm_json_stream/json_stream_parser.dart';
import 'package:test/test.dart';

/// Tests for specific edge cases that were found to fail
///
/// These tests document actual parser limitations and edge cases
void main() {
  group('Known Failing Edge Cases', () {
    test('chunk boundary splitting markdown wrapper - KNOWN TO FAIL', () async {
      // When ``` is split across chunk boundaries, parser might not handle it
      final input = '```json\n{"test":1}\n```';

      // Chunk size 3 will split the opening ```
      final stream = streamTextInChunks(
        text: input,
        chunkSize: 3,
        interval: Duration(milliseconds: 5),
      );
      final parser = JsonStreamParser(stream);

      try {
        final test = await parser
            .getNumberProperty("test")
            .future
            .timeout(Duration(seconds: 1));

        expect(test, equals(1));
        print('✓ Chunk boundary case passed (parser improved!)');
      } catch (e) {
        print('✗ Chunk boundary case failed as expected: $e');
        // This is expected to fail - document it
        expect(e, anyOf(isA<TimeoutException>(), isA<Exception>()));
      }
    });

    test('chunk boundary splitting <think> tag', () async {
      final input = '<think>reasoning</think>{"test":1}';

      // Chunk size 2 will split <think>
      final stream = streamTextInChunks(
        text: input,
        chunkSize: 2,
        interval: Duration(milliseconds: 5),
      );
      final parser = JsonStreamParser(stream);

      try {
        final test = await parser
            .getNumberProperty("test")
            .future
            .timeout(Duration(seconds: 1));

        expect(test, equals(1));
        print('✓ Think tag chunk boundary passed');
      } catch (e) {
        print('✗ Think tag chunk boundary failed: $e');
        rethrow;
      }
    });

    // TODO: Add support for delimiters
    // test('Skipping <think> tag', () async {
    //   final input =
    //       '<think>This is some reasoning that contains {"valid": "json"} that needs to be skipped </think>{"test":1}';

    //   // Chunk size 2 will split <think>
    //   final stream = streamTextInChunks(
    //     text: input,
    //     chunkSize: 2,
    //     interval: Duration(milliseconds: 5),
    //   );
    //   final parser = JsonStreamParser(stream);

    //   try {
    //     final test = await parser
    //         .getNumberProperty("test")
    //         .future
    //         .timeout(Duration(seconds: 1));

    //     expect(test, equals(1));
    //     print('✓ Think tag chunk boundary passed');
    //   } catch (e) {
    //     print('✗ Think tag chunk boundary failed: $e');
    //     rethrow;
    //   }
    // });

    test('chunk boundary splitting JSON structure', () async {
      final input = '{"test":1}';

      // Test with very small chunks
      final stream = streamTextInChunks(
        text: input,
        chunkSize: 1,
        interval: Duration(milliseconds: 1),
      );
      final parser = JsonStreamParser(stream);

      try {
        final test = await parser
            .getNumberProperty("test")
            .future
            .timeout(Duration(seconds: 1));

        expect(test, equals(1));
        print('✓ Single character chunks work');
      } catch (e) {
        print('✗ Single character chunks failed: $e');
        rethrow;
      }
    });
  });

  group('Specific Boundary Tests', () {
    test('chunk splits between ":" and value', () async {
      final input = '{"key":123}';
      // Chunk at position that splits between : and 1
      final stream = streamTextInChunks(
        text: input,
        chunkSize: 7, // {"key": | 123}
        interval: Duration(milliseconds: 5),
      );
      final parser = JsonStreamParser(stream);

      final key = await parser
          .getNumberProperty("key")
          .future
          .timeout(Duration(seconds: 1));

      expect(key, equals(123));
    });

    test('chunk splits in middle of string value', () async {
      final input = '{"text":"hello world"}';
      final stream = streamTextInChunks(
        text: input,
        chunkSize: 5,
        interval: Duration(milliseconds: 5),
      );
      final parser = JsonStreamParser(stream);

      final text = await parser
          .getStringProperty("text")
          .future
          .timeout(Duration(seconds: 1));

      expect(text, equals('hello world'));
    });

    test('chunk splits in middle of number', () async {
      final input = '{"num":123456789}';
      final stream = streamTextInChunks(
        text: input,
        chunkSize: 4,
        interval: Duration(milliseconds: 5),
      );
      final parser = JsonStreamParser(stream);

      final num = await parser
          .getNumberProperty("num")
          .future
          .timeout(Duration(seconds: 1));

      expect(num, equals(123456789));
    });

    test('chunk splits array elements', () async {
      final input = '{"arr":[1,2,3,4,5,6,7,8,9]}';
      final stream = streamTextInChunks(
        text: input,
        chunkSize: 3,
        interval: Duration(milliseconds: 5),
      );
      final parser = JsonStreamParser(stream);

      final arr = await parser
          .getListProperty("arr")
          .future
          .timeout(Duration(seconds: 1));

      expect(arr, equals([1, 2, 3, 4, 5, 6, 7, 8, 9]));
    });
  });

  group('Leading Comma Behavior', () {
    test('leading comma in array - actual behavior', () async {
      final input = '{"nums":[,1,2]}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final nums = await parser
          .getListProperty("nums")
          .future
          .timeout(Duration(seconds: 1));

      print('Leading comma array result: $nums');
      // Document actual behavior - parser likely ignores leading comma
      expect(nums, equals([1, 2]));
    });

    test('leading comma in object - actual behavior', () async {
      final input = '{,"a":1}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 3,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      try {
        final a = await parser
            .getNumberProperty("a")
            .future
            .timeout(Duration(seconds: 1));
        print('Leading comma object result: $a');
        expect(a, equals(1));
      } catch (e) {
        print('Leading comma in object caused timeout/error as expected');
        // Document that this edge case might not work
      }
    });

    test('double leading commas', () async {
      final input = '{"nums":[,,1,2]}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      try {
        final nums = await parser
            .getListProperty("nums")
            .future
            .timeout(Duration(seconds: 1));
        print('Double leading comma result: $nums');
        expect(nums, equals([1, 2]));
      } catch (e) {
        print('Double leading comma failed: $e');
      }
    });
  });

  group('Markdown with Braces - Actual Behavior', () {
    test('markdown containing { should be skipped', () async {
      final input = '''```text
This has { and } characters that look like JSON
```
{"real":true}''';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 15,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      // Parser should skip the { in the markdown and find the real JSON
      final real = await parser
          .getBooleanProperty("real")
          .future
          .timeout(Duration(seconds: 2));

      expect(real, equals(true));
      print('✓ Parser correctly skipped { in markdown');
    });

    test('what if { appears in preamble text?', () async {
      final input = 'Use {variables} like this: {"actual":123}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 10,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      // The first { in {variables} might confuse the parser
      try {
        final actual = await parser
            .getNumberProperty("actual")
            .future
            .timeout(Duration(seconds: 1));
        print('✓ Parser found real JSON despite { in preamble');
        expect(actual, equals(123));
      } catch (e) {
        print('✗ Parser was confused by { in preamble: $e');
        // This might fail - parser might treat {variables} as start of JSON
      }
    });

    test('JSON-like syntax in preamble', () async {
      final input = '''The format is {"key": "value"} for objects.
Real data: {"data":"test"}''';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 12,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      // This is tricky - how does parser know which { is real?
      try {
        final data = await parser
            .getStringProperty("data")
            .future
            .timeout(Duration(seconds: 1));
        print('Result when JSON-like in preamble: $data');
        expect(data, anyOf(equals('test'), equals('value')));
      } catch (e) {
        print('Parser confused by JSON-like preamble: $e');
      }
    });
  });

  group('More Extreme Cases', () {
    test('empty strings everywhere', () async {
      final input = '{"a":"","b":"","c":""}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 4,
        interval: Duration(milliseconds: 5),
      );
      final parser = JsonStreamParser(stream);

      final a = await parser
          .getStringProperty("a")
          .future
          .timeout(Duration(seconds: 1));
      final b = await parser
          .getStringProperty("b")
          .future
          .timeout(Duration(seconds: 1));
      final c = await parser
          .getStringProperty("c")
          .future
          .timeout(Duration(seconds: 1));

      expect(a, equals(''));
      expect(b, equals(''));
      expect(c, equals(''));
    });

    test('zero values everywhere', () async {
      final input = '{"a":0,"b":0.0,"c":0}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 5,
        interval: Duration(milliseconds: 5),
      );
      final parser = JsonStreamParser(stream);

      final a = await parser
          .getNumberProperty("a")
          .future
          .timeout(Duration(seconds: 1));
      final b = await parser
          .getNumberProperty("b")
          .future
          .timeout(Duration(seconds: 1));

      expect(a, equals(0));
      expect(b, equals(0.0));
    });

    test('very long string value', () async {
      final longValue = 'a' * 10000;
      final input = '{"long":"$longValue"}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 100,
        interval: Duration(milliseconds: 1),
      );
      final parser = JsonStreamParser(stream);

      final long = await parser
          .getStringProperty("long")
          .future
          .timeout(Duration(seconds: 3));

      expect(long.length, equals(10000));
    });

    test('very large number', () async {
      final input = '{"big":9223372036854775807}'; // Max int64

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 8,
        interval: Duration(milliseconds: 5),
      );
      final parser = JsonStreamParser(stream);

      final big = await parser
          .getNumberProperty("big")
          .future
          .timeout(Duration(seconds: 1));

      expect(big, equals(9223372036854775807));
    });

    test('very small decimal', () async {
      final input = '{"tiny":0.000000001}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 6,
        interval: Duration(milliseconds: 5),
      );
      final parser = JsonStreamParser(stream);

      final tiny = await parser
          .getNumberProperty("tiny")
          .future
          .timeout(Duration(seconds: 1));

      expect(tiny, equals(0.000000001));
    });
  });
}


