import 'dart:convert';
import 'package:json_stream_parser/utilities/stream_text_in_chunks.dart';
import 'package:test/test.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('String Property Stream Tests', () {
    const verbose = false; // Set to true to see detailed output

    void runStringTest({
      required String testName,
      required String jsonString,
      required String expectedValue,
      List<int>? chunkSizes,
    }) {
      final sizes = chunkSizes ?? ChunkSizeVariations.quick;

      test(testName, () async {
        if (verbose) TestPrinter.printTestCase(testName);

        for (final chunkSize in sizes) {
          if (verbose) {
            print('    Testing with chunk size: $chunkSize');
          }

          final accumulator = StreamAccumulator<String>();
          final chunks = <String>[];

          // Create stream
          final stream = streamTextInChunks(
            text: jsonString,
            chunkSize: chunkSize,
            interval: const Duration(microseconds: 1),
          );

          // Listen to stream and accumulate
          await for (final chunk in stream) {
            chunks.add(chunk);
            accumulator.add(chunk);

            if (verbose) {
              TestPrinter.printChunk(
                chunk,
                chunks.length,
                (jsonString.length / chunkSize).ceil(),
              );
            }
          }

          // Validate accumulated value
          final accumulated = accumulator.getAccumulatedString();
          if (verbose) {
            TestPrinter.printAccumulated(accumulated);
            TestPrinter.printExpected(jsonString);
          }

          expect(
            accumulated,
            equals(jsonString),
            reason: 'Accumulated chunks should match original JSON',
          );

          // Validate that the accumulated JSON can be parsed
          final parsed = jsonDecode(accumulated);
          expect(
            parsed,
            equals(expectedValue),
            reason: 'Parsed value should match expected',
          );

          if (verbose) TestPrinter.printPassed();
        }
      });
    }

    group('Basic Strings', () {
      runStringTest(
        testName: 'Simple string - "hello"',
        jsonString: JsonTestData.simpleString,
        expectedValue: 'hello',
      );

      runStringTest(
        testName: 'String with spaces - "hello world"',
        jsonString: JsonTestData.stringWithSpaces,
        expectedValue: 'hello world',
      );

      runStringTest(
        testName: 'Empty string - ""',
        jsonString: JsonTestData.emptyString,
        expectedValue: '',
      );

      runStringTest(
        testName: 'Single character - "a"',
        jsonString: '"a"',
        expectedValue: 'a',
      );

      runStringTest(
        testName: 'Single space - " "',
        jsonString: '" "',
        expectedValue: ' ',
      );
    });

    group('Strings with Escape Sequences', () {
      runStringTest(
        testName: 'String with escaped quotes',
        jsonString: JsonTestData.stringWithEscapes,
        expectedValue: 'hello "world"',
      );

      runStringTest(
        testName: 'String with newline',
        jsonString: JsonTestData.stringWithNewline,
        expectedValue: 'hello\nworld',
      );

      runStringTest(
        testName: 'String with tab',
        jsonString: JsonTestData.stringWithTab,
        expectedValue: 'hello\tworld',
      );

      runStringTest(
        testName: 'String with backslash',
        jsonString: r'"back\\slash"',
        expectedValue: r'back\slash',
      );

      runStringTest(
        testName: 'String with forward slash',
        jsonString: r'"forward\/slash"',
        expectedValue: 'forward/slash',
      );

      runStringTest(
        testName: 'String with multiple escapes',
        jsonString: r'"line1\nline2\tindented\r\nline3"',
        expectedValue: 'line1\nline2\tindented\r\nline3',
      );
    });

    group('Unicode Strings', () {
      runStringTest(
        testName: 'String with emojis',
        jsonString: JsonTestData.unicode,
        expectedValue: 'Hello 👋 World 🌍',
      );

      runStringTest(
        testName: 'String with various unicode',
        jsonString: '"Café ☕ naïve résumé"',
        expectedValue: 'Café ☕ naïve résumé',
      );

      runStringTest(
        testName: 'String with CJK characters',
        jsonString: '"你好世界 こんにちは 안녕하세요"',
        expectedValue: '你好世界 こんにちは 안녕하세요',
      );

      runStringTest(
        testName: 'String with mixed scripts',
        jsonString: '"Hello Мир Dünya 世界"',
        expectedValue: 'Hello Мир Dünya 世界',
      );
    });

    group('Long Strings', () {
      runStringTest(
        testName: 'Long string (100 chars)',
        jsonString: '"${"a" * 100}"',
        expectedValue: 'a' * 100,
        chunkSizes: [1, 10, 50],
      );

      runStringTest(
        testName: 'Long string (1000 chars)',
        jsonString: JsonTestData.longString,
        expectedValue: 'a' * 1000,
        chunkSizes: [1, 50, 100],
      );

      runStringTest(
        testName: 'Long string with repeating pattern',
        jsonString: '"${"abc" * 100}"',
        expectedValue: 'abc' * 100,
        chunkSizes: [3, 10, 30],
      );
    });

    group('Special Cases', () {
      runStringTest(
        testName: 'String with only spaces',
        jsonString: '"     "',
        expectedValue: '     ',
      );

      runStringTest(
        testName: 'String with numbers',
        jsonString: '"12345"',
        expectedValue: '12345',
      );

      runStringTest(
        testName: 'String with special chars',
        jsonString: r'"!@#$%^&*()_+-=[]{}|;:,.<>?"',
        expectedValue: r'!@#$%^&*()_+-=[]{}|;:,.<>?',
      );

      runStringTest(
        testName: 'URL string',
        jsonString: '"https://example.com/path?query=value&other=123"',
        expectedValue: 'https://example.com/path?query=value&other=123',
      );

      runStringTest(
        testName: 'JSON-like content as string',
        jsonString: r'"{\"nested\":\"value\"}"',
        expectedValue: r'{"nested":"value"}',
      );

      runStringTest(
        testName: 'String with literal backslash-n',
        jsonString: r'"line1\\nline2\\nline3"',
        expectedValue: r'line1\nline2\nline3',
      );
    });

    group('Edge Cases', () {
      test('Chunk boundary on escape sequence', () async {
        // Test when chunk boundary falls in the middle of \n
        final jsonString = r'"hello\nworld"';
        final chunkSize = 7; // Will split at "hello\n

        final accumulator = StreamAccumulator<String>();

        final stream = streamTextInChunks(
          text: jsonString,
          chunkSize: chunkSize,
          interval: const Duration(microseconds: 1),
        );

        await for (final chunk in stream) {
          accumulator.add(chunk);
        }

        final accumulated = accumulator.getAccumulatedString();
        expect(accumulated, equals(jsonString));

        final parsed = jsonDecode(accumulated);
        expect(parsed, equals('hello\nworld'));
      });

      test('Chunk boundary on quote', () async {
        // Test when chunk boundary falls on opening/closing quote
        final jsonString = '"test"';
        final chunkSize = 1; // Each character is a chunk

        final accumulator = StreamAccumulator<String>();

        final stream = streamTextInChunks(
          text: jsonString,
          chunkSize: chunkSize,
          interval: const Duration(microseconds: 1),
        );

        await for (final chunk in stream) {
          accumulator.add(chunk);
        }

        final accumulated = accumulator.getAccumulatedString();
        expect(accumulated, equals(jsonString));

        final parsed = jsonDecode(accumulated);
        expect(parsed, equals('test'));
      });

      test('Very small chunks (1 char)', () async {
        final jsonString = '"Hello World!"';

        final accumulator = StreamAccumulator<String>();

        final stream = streamTextInChunks(
          text: jsonString,
          chunkSize: 1,
          interval: const Duration(microseconds: 1),
        );

        await for (final chunk in stream) {
          accumulator.add(chunk);
          expect(chunk.length, equals(1));
        }

        final accumulated = accumulator.getAccumulatedString();
        expect(accumulated, equals(jsonString));

        final parsed = jsonDecode(accumulated);
        expect(parsed, equals('Hello World!'));
      });

      test('Large chunks (entire string)', () async {
        final jsonString = '"Hello World!"';

        final accumulator = StreamAccumulator<String>();

        final stream = streamTextInChunks(
          text: jsonString,
          chunkSize: 1000,
          interval: const Duration(microseconds: 1),
        );

        int chunkCount = 0;
        await for (final chunk in stream) {
          accumulator.add(chunk);
          chunkCount++;
        }

        expect(chunkCount, equals(1), reason: 'Should emit single chunk');

        final accumulated = accumulator.getAccumulatedString();
        expect(accumulated, equals(jsonString));

        final parsed = jsonDecode(accumulated);
        expect(parsed, equals('Hello World!'));
      });
    });

    group('Stress Tests', () {
      test(
        'Very long string with chunk size 1',
        () async {
          final longString = 'x' * 5000;
          final jsonString = '"$longString"';

          final accumulator = StreamAccumulator<String>();

          final stream = streamTextInChunks(
            text: jsonString,
            chunkSize: 1,
            interval: const Duration(microseconds: 1),
          );

          await for (final chunk in stream) {
            accumulator.add(chunk);
          }

          final accumulated = accumulator.getAccumulatedString();
          expect(accumulated, equals(jsonString));

          final parsed = jsonDecode(accumulated);
          expect(parsed, equals(longString));
        },
        timeout: const Timeout(Duration(seconds: 10)),
      );

      test('String with many escape sequences', () async {
        final content = r'\"\\\/\b\f\n\r\t' * 100;
        final jsonString = '"$content"';

        final accumulator = StreamAccumulator<String>();

        final stream = streamTextInChunks(
          text: jsonString,
          chunkSize: 5,
          interval: const Duration(microseconds: 1),
        );

        await for (final chunk in stream) {
          accumulator.add(chunk);
        }

        final accumulated = accumulator.getAccumulatedString();
        expect(accumulated, equals(jsonString));

        // Should be parseable
        expect(() => jsonDecode(accumulated), returnsNormally);
      });
    });
  });
}
