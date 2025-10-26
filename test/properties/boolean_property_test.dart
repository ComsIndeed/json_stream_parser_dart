import 'dart:convert';
import 'package:json_stream_parser/utilities/stream_text_in_chunks.dart';
import 'package:test/test.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Boolean Property Stream Tests', () {
    const verbose = false; // Set to true to see detailed output

    void runBooleanTest({
      required String testName,
      required String jsonString,
      required bool expectedValue,
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
          expect(
            parsed,
            isA<bool>(),
            reason: 'Parsed value should be a boolean',
          );

          if (verbose) TestPrinter.printPassed();
        }
      });
    }

    group('Basic Booleans', () {
      runBooleanTest(
        testName: 'Boolean true',
        jsonString: JsonTestData.trueValue,
        expectedValue: true,
      );

      runBooleanTest(
        testName: 'Boolean false',
        jsonString: JsonTestData.falseValue,
        expectedValue: false,
      );
    });

    group('Edge Cases', () {
      test('Chunk boundary on "true"', () async {
        final jsonString = 'true';
        final chunkSize = 2; // Will split as "tr" and "ue"

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
        expect(parsed, equals(true));
        expect(parsed, isA<bool>());
      });

      test('Chunk boundary on "false"', () async {
        final jsonString = 'false';
        final chunkSize = 3; // Will split as "fal" and "se"

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
        expect(parsed, equals(false));
        expect(parsed, isA<bool>());
      });

      test('Very small chunks (1 char) - true', () async {
        final jsonString = 'true';

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
        expect(parsed, equals(true));
        expect(parsed, isA<bool>());
      });

      test('Very small chunks (1 char) - false', () async {
        final jsonString = 'false';

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
        expect(parsed, equals(false));
        expect(parsed, isA<bool>());
      });
    });

    group('Booleans in Arrays', () {
      test('Array of booleans', () async {
        final jsonString = '[true,false,true,false]';

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
        expect(parsed, equals([true, false, true, false]));
      });

      test('Array with only true values', () async {
        final jsonString = '[true,true,true]';

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
        expect(parsed, equals([true, true, true]));
      });

      test('Array with only false values', () async {
        final jsonString = '[false,false,false]';

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
        expect(parsed, equals([false, false, false]));
      });
    });

    group('Booleans in Objects', () {
      test('Object with boolean values', () async {
        final jsonString = '{"active":true,"verified":false}';

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
        expect(parsed, equals({'active': true, 'verified': false}));
        expect(parsed['active'], isA<bool>());
        expect(parsed['verified'], isA<bool>());
      });

      test('Object with mixed types including booleans', () async {
        final jsonString =
            '{"name":"test","count":5,"active":true,"valid":false}';

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
        expect(parsed['count'], equals(5));
        expect(parsed['active'], equals(true));
        expect(parsed['valid'], equals(false));
      });
    });
  });
}
