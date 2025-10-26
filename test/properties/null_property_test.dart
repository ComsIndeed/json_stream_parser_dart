import 'dart:convert';
import 'package:json_stream_parser/utilities/stream_text_in_chunks.dart';
import 'package:test/test.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Null Property Stream Tests', () {
    const verbose = false; // Set to true to see detailed output

    void runNullTest({
      required String testName,
      required String jsonString,
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
          expect(parsed, isNull, reason: 'Parsed value should be null');

          if (verbose) TestPrinter.printPassed();
        }
      });
    }

    group('Basic Null', () {
      runNullTest(testName: 'Null value', jsonString: JsonTestData.nullValue);
    });

    group('Edge Cases', () {
      test('Chunk boundary on "null"', () async {
        final jsonString = 'null';
        final chunkSize = 2; // Will split as "nu" and "ll"

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
        expect(parsed, isNull);
      });

      test('Very small chunks (1 char)', () async {
        final jsonString = 'null';

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
        expect(parsed, isNull);
      });

      test('Large chunks (entire string)', () async {
        final jsonString = 'null';

        final accumulator = StreamAccumulator<String>();

        final stream = streamTextInChunks(
          text: jsonString,
          chunkSize: 100,
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
        expect(parsed, isNull);
      });
    });

    group('Null in Arrays', () {
      test('Array of nulls', () async {
        final jsonString = '[null,null,null]';

        final accumulator = StreamAccumulator<String>();

        final stream = streamTextInChunks(
          text: jsonString,
          chunkSize: 4,
          interval: const Duration(microseconds: 1),
        );

        await for (final chunk in stream) {
          accumulator.add(chunk);
        }

        final accumulated = accumulator.getAccumulatedString();
        expect(accumulated, equals(jsonString));

        final parsed = jsonDecode(accumulated);
        expect(parsed, equals([null, null, null]));
        expect(parsed[0], isNull);
        expect(parsed[1], isNull);
        expect(parsed[2], isNull);
      });

      test('Array with mixed types including null', () async {
        final jsonString = '["test",null,42,true,null]';

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
        expect(parsed, equals(['test', null, 42, true, null]));
        expect(parsed[0], equals('test'));
        expect(parsed[1], isNull);
        expect(parsed[2], equals(42));
        expect(parsed[3], equals(true));
        expect(parsed[4], isNull);
      });

      test('Array starting and ending with null', () async {
        final jsonString = '[null,1,2,3,null]';

        final accumulator = StreamAccumulator<String>();

        final stream = streamTextInChunks(
          text: jsonString,
          chunkSize: 3,
          interval: const Duration(microseconds: 1),
        );

        await for (final chunk in stream) {
          accumulator.add(chunk);
        }

        final accumulated = accumulator.getAccumulatedString();
        expect(accumulated, equals(jsonString));

        final parsed = jsonDecode(accumulated);
        expect(parsed, equals([null, 1, 2, 3, null]));
      });
    });

    group('Null in Objects', () {
      test('Object with null values', () async {
        final jsonString = '{"name":null,"age":null}';

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
        expect(parsed, equals({'name': null, 'age': null}));
        expect(parsed['name'], isNull);
        expect(parsed['age'], isNull);
      });

      test('Object with mixed types including null', () async {
        final jsonString =
            '{"name":"test","middle":null,"count":5,"flag":true}';

        final accumulator = StreamAccumulator<String>();

        final stream = streamTextInChunks(
          text: jsonString,
          chunkSize: 7,
          interval: const Duration(microseconds: 1),
        );

        await for (final chunk in stream) {
          accumulator.add(chunk);
        }

        final accumulated = accumulator.getAccumulatedString();
        expect(accumulated, equals(jsonString));

        final parsed = jsonDecode(accumulated);
        expect(parsed['name'], equals('test'));
        expect(parsed['middle'], isNull);
        expect(parsed['count'], equals(5));
        expect(parsed['flag'], equals(true));
      });

      test('Nested object with null', () async {
        final jsonString = '{"user":{"name":"Alice","address":null}}';

        final accumulator = StreamAccumulator<String>();

        final stream = streamTextInChunks(
          text: jsonString,
          chunkSize: 8,
          interval: const Duration(microseconds: 1),
        );

        await for (final chunk in stream) {
          accumulator.add(chunk);
        }

        final accumulated = accumulator.getAccumulatedString();
        expect(accumulated, equals(jsonString));

        final parsed = jsonDecode(accumulated);
        expect(parsed['user']['name'], equals('Alice'));
        expect(parsed['user']['address'], isNull);
      });
    });

    group('Complex Scenarios', () {
      test('Deeply nested structure with multiple nulls', () async {
        final jsonString =
            '{"a":null,"b":{"c":null,"d":[null,1,null]},"e":null}';

        final accumulator = StreamAccumulator<String>();

        final stream = streamTextInChunks(
          text: jsonString,
          chunkSize: 6,
          interval: const Duration(microseconds: 1),
        );

        await for (final chunk in stream) {
          accumulator.add(chunk);
        }

        final accumulated = accumulator.getAccumulatedString();
        expect(accumulated, equals(jsonString));

        final parsed = jsonDecode(accumulated);
        expect(parsed['a'], isNull);
        expect(parsed['b']['c'], isNull);
        expect(parsed['b']['d'], equals([null, 1, null]));
        expect(parsed['e'], isNull);
      });

      test('Array of objects with null values', () async {
        final jsonString =
            '[{"name":"Alice","age":null},{"name":null,"age":30}]';

        final accumulator = StreamAccumulator<String>();

        final stream = streamTextInChunks(
          text: jsonString,
          chunkSize: 10,
          interval: const Duration(microseconds: 1),
        );

        await for (final chunk in stream) {
          accumulator.add(chunk);
        }

        final accumulated = accumulator.getAccumulatedString();
        expect(accumulated, equals(jsonString));

        final parsed = jsonDecode(accumulated);
        expect(parsed[0]['name'], equals('Alice'));
        expect(parsed[0]['age'], isNull);
        expect(parsed[1]['name'], isNull);
        expect(parsed[1]['age'], equals(30));
      });
    });
  });
}
