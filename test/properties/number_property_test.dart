import 'dart:convert';
import 'package:json_stream_parser/utilities/stream_text_in_chunks.dart';
import 'package:test/test.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Number Property Stream Tests', () {
    const verbose = false; // Set to true to see detailed output

    void runNumberTest({
      required String testName,
      required String jsonString,
      required num expectedValue,
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

    group('Integer Numbers', () {
      runNumberTest(
        testName: 'Zero',
        jsonString: JsonTestData.zero,
        expectedValue: 0,
      );

      runNumberTest(
        testName: 'Positive integer - 42',
        jsonString: JsonTestData.positiveInt,
        expectedValue: 42,
      );

      runNumberTest(
        testName: 'Negative integer - -42',
        jsonString: JsonTestData.negativeInt,
        expectedValue: -42,
      );

      runNumberTest(
        testName: 'Single digit - 1',
        jsonString: '1',
        expectedValue: 1,
      );

      runNumberTest(
        testName: 'Single digit - 9',
        jsonString: '9',
        expectedValue: 9,
      );

      runNumberTest(
        testName: 'Large positive integer',
        jsonString: JsonTestData.largeNumber,
        expectedValue: 999999999,
      );

      runNumberTest(
        testName: 'Large negative integer',
        jsonString: '-999999999',
        expectedValue: -999999999,
      );

      runNumberTest(
        testName: 'Very large integer',
        jsonString: '123456789012345',
        expectedValue: 123456789012345,
      );
    });

    group('Floating Point Numbers', () {
      runNumberTest(
        testName: 'Positive float - 3.14',
        jsonString: JsonTestData.positiveFloat,
        expectedValue: 3.14,
      );

      runNumberTest(
        testName: 'Negative float - -3.14',
        jsonString: JsonTestData.negativeFloat,
        expectedValue: -3.14,
      );

      runNumberTest(
        testName: 'Small decimal',
        jsonString: JsonTestData.smallDecimal,
        expectedValue: 0.0001,
      );

      runNumberTest(
        testName: 'Zero as float - 0.0',
        jsonString: '0.0',
        expectedValue: 0.0,
      );

      runNumberTest(
        testName: 'Float with leading zero - 0.5',
        jsonString: '0.5',
        expectedValue: 0.5,
      );

      runNumberTest(
        testName: 'Float without leading zero - .5 (if supported)',
        jsonString: '0.5',
        expectedValue: 0.5,
      );

      runNumberTest(
        testName: 'Large float',
        jsonString: '123456.789',
        expectedValue: 123456.789,
      );

      runNumberTest(
        testName: 'Many decimal places',
        jsonString: '3.141592653589793',
        expectedValue: 3.141592653589793,
      );
    });

    group('Scientific Notation', () {
      runNumberTest(
        testName: 'Scientific notation - 1e10',
        jsonString: '1e10',
        expectedValue: 1e10,
      );

      runNumberTest(
        testName: 'Scientific notation - 1E10',
        jsonString: '1E10',
        expectedValue: 1e10,
      );

      runNumberTest(
        testName: 'Scientific notation with plus - 1e+10',
        jsonString: '1e+10',
        expectedValue: 1e10,
      );

      runNumberTest(
        testName: 'Scientific notation with minus - 1e-10',
        jsonString: '1e-10',
        expectedValue: 1e-10,
      );

      runNumberTest(
        testName: 'Scientific notation with decimal - 1.5e10',
        jsonString: '1.5e10',
        expectedValue: 1.5e10,
      );

      runNumberTest(
        testName: 'Negative scientific notation - -1e10',
        jsonString: '-1e10',
        expectedValue: -1e10,
      );

      runNumberTest(
        testName: 'Large exponent - 1e100',
        jsonString: '1e100',
        expectedValue: 1e100,
      );

      runNumberTest(
        testName: 'Small exponent - 1e-100',
        jsonString: '1e-100',
        expectedValue: 1e-100,
      );
    });

    group('Special Values', () {
      runNumberTest(
        testName: 'Negative zero - -0',
        jsonString: '-0',
        expectedValue: 0,
      );

      runNumberTest(
        testName: 'Integer as float - 10.0',
        jsonString: '10.0',
        expectedValue: 10.0,
      );

      runNumberTest(
        testName: 'Float with trailing zeros - 1.500',
        jsonString: '1.500',
        expectedValue: 1.5,
      );
    });

    group('Edge Cases', () {
      test('Chunk boundary on decimal point', () async {
        final jsonString = '3.14';
        final chunkSize = 2; // Will split as "3." and "14"

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
        expect(parsed, equals(3.14));
      });

      test('Chunk boundary on minus sign', () async {
        final jsonString = '-42';
        final chunkSize = 1; // Will split as "-", "4", "2"

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
        expect(parsed, equals(-42));
      });

      test('Chunk boundary on exponent', () async {
        final jsonString = '1e10';
        final chunkSize = 2; // Will split as "1e" and "10"

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
        expect(parsed, equals(1e10));
      });

      test('Very small chunks (1 char)', () async {
        final jsonString = '123.456';

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
        expect(parsed, equals(123.456));
      });
    });

    group('Arrays of Numbers', () {
      test('Array of integers', () async {
        final jsonString = '[1,2,3,4,5]';

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
        expect(parsed, equals([1, 2, 3, 4, 5]));
      });

      test('Array of floats', () async {
        final jsonString = '[1.1,2.2,3.3,4.4,5.5]';

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
        expect(parsed, equals([1.1, 2.2, 3.3, 4.4, 5.5]));
      });

      test('Array of negative numbers', () async {
        final jsonString = '[-1,-2,-3,-4,-5]';

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
        expect(parsed, equals([-1, -2, -3, -4, -5]));
      });
    });

    group('Stress Tests', () {
      test('Very large number with chunk size 1', () async {
        final jsonString = '123456789012345678901234567890';

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

        // Should be parseable (may lose precision for very large numbers)
        expect(() => jsonDecode(accumulated), returnsNormally);
      });

      test('Many decimal places', () async {
        final jsonString =
            '3.14159265358979323846264338327950288419716939937510';

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

        // Should be parseable (may lose precision)
        expect(() => jsonDecode(accumulated), returnsNormally);
      });
    });
  });
}
