import 'dart:convert';
import 'package:json_stream_parser/utilities/stream_text_in_chunks.dart';
import 'package:test/test.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('List Property Stream Tests - Flat Lists', () {
    const verbose = false; // Set to true to see detailed output

    void runListTest({
      required String testName,
      required String jsonString,
      required List<dynamic> expectedValue,
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
          expect(parsed, equals(expectedValue));
          expect(parsed, isA<List>());

          if (verbose) TestPrinter.printPassed();
        }
      });
    }

    group('Empty and Minimal Lists', () {
      runListTest(
        testName: 'Empty list',
        jsonString: JsonTestData.emptyList(),
        expectedValue: [],
      );

      runListTest(
        testName: 'List with single string',
        jsonString: '["hello"]',
        expectedValue: ['hello'],
      );

      runListTest(
        testName: 'List with single number',
        jsonString: '[42]',
        expectedValue: [42],
      );

      runListTest(
        testName: 'List with single boolean',
        jsonString: '[true]',
        expectedValue: [true],
      );

      runListTest(
        testName: 'List with single null',
        jsonString: '[null]',
        expectedValue: [null],
      );
    });

    group('Flat String Lists', () {
      runListTest(
        testName: 'List of strings',
        jsonString: JsonTestData.flatStringList(),
        expectedValue: ['apple', 'banana', 'cherry'],
      );

      runListTest(
        testName: 'List of empty strings',
        jsonString: '["","",""]',
        expectedValue: ['', '', ''],
      );

      runListTest(
        testName: 'List of strings with spaces',
        jsonString: '["hello world","foo bar","test data"]',
        expectedValue: ['hello world', 'foo bar', 'test data'],
      );

      runListTest(
        testName: 'List of strings with special characters',
        jsonString: '["hello!","world?","test@123"]',
        expectedValue: ['hello!', 'world?', 'test@123'],
      );

      runListTest(
        testName: 'List of unicode strings',
        jsonString: '["Hello 👋","World 🌍","Test 🔬"]',
        expectedValue: ['Hello 👋', 'World 🌍', 'Test 🔬'],
      );

      runListTest(
        testName: 'List of strings with escape sequences',
        jsonString: r'["line1\nline2","tab\there","quote\"here"]',
        expectedValue: ['line1\nline2', 'tab\there', 'quote"here'],
      );

      runListTest(
        testName: 'List of many strings',
        jsonString: jsonEncode(List.generate(20, (i) => 'item$i')),
        expectedValue: List.generate(20, (i) => 'item$i'),
      );
    });

    group('Flat Number Lists', () {
      runListTest(
        testName: 'List of integers',
        jsonString: JsonTestData.flatNumberList(),
        expectedValue: [1, 2, 3, 4, 5],
      );

      runListTest(
        testName: 'List of floats',
        jsonString: '[1.1,2.2,3.3,4.4,5.5]',
        expectedValue: [1.1, 2.2, 3.3, 4.4, 5.5],
      );

      runListTest(
        testName: 'List of negative numbers',
        jsonString: '[-1,-2,-3,-4,-5]',
        expectedValue: [-1, -2, -3, -4, -5],
      );

      runListTest(
        testName: 'List of mixed positive and negative',
        jsonString: '[-5,-3,0,3,5]',
        expectedValue: [-5, -3, 0, 3, 5],
      );

      runListTest(
        testName: 'List with zero',
        jsonString: '[0,0,0]',
        expectedValue: [0, 0, 0],
      );

      runListTest(
        testName: 'List with scientific notation',
        jsonString: '[1e10,1e-10,1.5e5]',
        expectedValue: [1e10, 1e-10, 1.5e5],
      );

      runListTest(
        testName: 'List of many numbers',
        jsonString: jsonEncode(List.generate(50, (i) => i)),
        expectedValue: List.generate(50, (i) => i),
      );
    });

    group('Flat Boolean Lists', () {
      runListTest(
        testName: 'List of booleans',
        jsonString: '[true,false,true,false]',
        expectedValue: [true, false, true, false],
      );

      runListTest(
        testName: 'List of only true',
        jsonString: '[true,true,true]',
        expectedValue: [true, true, true],
      );

      runListTest(
        testName: 'List of only false',
        jsonString: '[false,false,false]',
        expectedValue: [false, false, false],
      );
    });

    group('Flat Null Lists', () {
      runListTest(
        testName: 'List of nulls',
        jsonString: '[null,null,null]',
        expectedValue: [null, null, null],
      );
    });

    group('Flat Mixed-Type Lists', () {
      runListTest(
        testName: 'List with mixed types',
        jsonString: JsonTestData.flatMixedList(),
        expectedValue: ['hello', 42, true, null, 3.14],
      );

      runListTest(
        testName: 'List with all primitive types',
        jsonString: '["string",123,45.67,true,false,null]',
        expectedValue: ['string', 123, 45.67, true, false, null],
      );

      runListTest(
        testName: 'List with alternating types',
        jsonString: '[1,"a",2,"b",3,"c"]',
        expectedValue: [1, 'a', 2, 'b', 3, 'c'],
      );

      runListTest(
        testName: 'List with multiple nulls and values',
        jsonString: '[null,1,null,2,null,3,null]',
        expectedValue: [null, 1, null, 2, null, 3, null],
      );
    });

    group('Edge Cases', () {
      test('Chunk boundary on array element', () async {
        final jsonString = '["hello","world"]';
        final chunkSize = 7; // Will split in middle

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
        expect(parsed, equals(['hello', 'world']));
      });

      test('Chunk boundary on comma', () async {
        final jsonString = '[1,2,3,4,5]';
        final chunkSize = 4; // Will split as '[1,2', ',3,4', ',5]'

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
        expect(parsed, equals([1, 2, 3, 4, 5]));
      });

      test('Very small chunks (1 char)', () async {
        final jsonString = '[1,2,3]';

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
        expect(parsed, equals([1, 2, 3]));
      });

      test('List with whitespace', () async {
        final jsonString = '[ "a" , "b" , "c" ]';

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

        final parsed = jsonDecode(accumulated);
        expect(parsed, equals(['a', 'b', 'c']));
      });
    });

    group('Stress Tests', () {
      test('Very large list of strings', () async {
        final list = List.generate(100, (i) => 'item$i');
        final jsonString = jsonEncode(list);

        final accumulator = StreamAccumulator<String>();

        final stream = streamTextInChunks(
          text: jsonString,
          chunkSize: 20,
          interval: const Duration(microseconds: 1),
        );

        await for (final chunk in stream) {
          accumulator.add(chunk);
        }

        final accumulated = accumulator.getAccumulatedString();
        expect(accumulated, equals(jsonString));

        final parsed = jsonDecode(accumulated);
        expect(parsed, equals(list));
      }, timeout: const Timeout(Duration(seconds: 10)));

      test('Very large list of numbers', () async {
        final list = List.generate(500, (i) => i * 2);
        final jsonString = jsonEncode(list);

        final accumulator = StreamAccumulator<String>();

        final stream = streamTextInChunks(
          text: jsonString,
          chunkSize: 30,
          interval: const Duration(microseconds: 1),
        );

        await for (final chunk in stream) {
          accumulator.add(chunk);
        }

        final accumulated = accumulator.getAccumulatedString();
        expect(accumulated, equals(jsonString));

        final parsed = jsonDecode(accumulated);
        expect(parsed, equals(list));
      }, timeout: const Timeout(Duration(seconds: 10)));

      test(
        'List with very long string elements',
        () async {
          final longString = 'x' * 1000;
          final list = [longString, longString, longString];
          final jsonString = jsonEncode(list);

          final accumulator = StreamAccumulator<String>();

          final stream = streamTextInChunks(
            text: jsonString,
            chunkSize: 100,
            interval: const Duration(microseconds: 1),
          );

          await for (final chunk in stream) {
            accumulator.add(chunk);
          }

          final accumulated = accumulator.getAccumulatedString();
          expect(accumulated, equals(jsonString));

          final parsed = jsonDecode(accumulated);
          expect(parsed, equals(list));
        },
        timeout: const Timeout(Duration(seconds: 10)),
      );
    });
  });
}
