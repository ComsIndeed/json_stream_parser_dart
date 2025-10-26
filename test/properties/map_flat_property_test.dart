import 'dart:convert';
import 'package:json_stream_parser/utilities/stream_text_in_chunks.dart';
import 'package:test/test.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Map Property Stream Tests - Flat Maps', () {
    const verbose = false; // Set to true to see detailed output

    void runMapTest({
      required String testName,
      required String jsonString,
      required Map<String, dynamic> expectedValue,
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
          expect(parsed, isA<Map>(), reason: 'Parsed value should be a Map');

          if (verbose) TestPrinter.printPassed();
        }
      });
    }

    group('Empty and Minimal Maps', () {
      test('Empty map', () async {
        final jsonString = '{}';

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
        expect(parsed, equals({}));
        expect(parsed, isA<Map>());
      });

      test('Map with single string property', () async {
        final jsonString = '{"name":"John"}';

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
        expect(parsed, equals({'name': 'John'}));
      });

      test('Map with single number property', () async {
        final jsonString = '{"age":30}';

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
        expect(parsed, equals({'age': 30}));
      });
    });

    group('Flat String-to-String Maps', () {
      runMapTest(
        testName: 'Map with string values only',
        jsonString: JsonTestData.flatMapStringToString(),
        expectedValue: {'name': 'John', 'city': 'New York', 'country': 'USA'},
      );

      runMapTest(
        testName: 'Map with empty string values',
        jsonString: '{"key1":"","key2":"value","key3":""}',
        expectedValue: {'key1': '', 'key2': 'value', 'key3': ''},
      );

      runMapTest(
        testName: 'Map with special characters in values',
        jsonString: '{"url":"https://example.com","email":"user@example.com"}',
        expectedValue: {
          'url': 'https://example.com',
          'email': 'user@example.com',
        },
      );

      runMapTest(
        testName: 'Map with unicode string values',
        jsonString: '{"greeting":"Hello 👋","world":"World 🌍"}',
        expectedValue: {'greeting': 'Hello 👋', 'world': 'World 🌍'},
      );

      runMapTest(
        testName: 'Map with escaped characters in values',
        jsonString: r'{"quote":"She said \"hello\"","newline":"line1\nline2"}',
        expectedValue: {'quote': 'She said "hello"', 'newline': 'line1\nline2'},
      );
    });

    group('Flat Mixed-Type Maps', () {
      runMapTest(
        testName: 'Map with mixed value types',
        jsonString: JsonTestData.flatMapMixedValues(),
        expectedValue: {
          'name': 'John',
          'age': 30,
          'isActive': true,
          'score': 95.5,
          'nickname': null,
        },
      );

      runMapTest(
        testName: 'Map with all primitive types',
        jsonString:
            '{"str":"text","num":42,"float":3.14,"bool":true,"none":null}',
        expectedValue: {
          'str': 'text',
          'num': 42,
          'float': 3.14,
          'bool': true,
          'none': null,
        },
      );

      runMapTest(
        testName: 'Map with multiple boolean values',
        jsonString: '{"active":true,"verified":false,"pending":true}',
        expectedValue: {'active': true, 'verified': false, 'pending': true},
      );

      runMapTest(
        testName: 'Map with multiple null values',
        jsonString: '{"field1":null,"field2":"value","field3":null}',
        expectedValue: {'field1': null, 'field2': 'value', 'field3': null},
      );

      runMapTest(
        testName: 'Map with various number types',
        jsonString:
            '{"int":42,"float":3.14,"negative":-10,"zero":0,"scientific":1e5}',
        expectedValue: {
          'int': 42,
          'float': 3.14,
          'negative': -10,
          'zero': 0,
          'scientific': 1e5,
        },
      );
    });

    group('Maps with Many Properties', () {
      runMapTest(
        testName: 'Map with 10 properties',
        jsonString: JsonTestData.flatMapManyProperties(),
        expectedValue: {
          'prop1': 'value1',
          'prop2': 'value2',
          'prop3': 'value3',
          'prop4': 'value4',
          'prop5': 'value5',
          'prop6': 'value6',
          'prop7': 'value7',
          'prop8': 'value8',
          'prop9': 'value9',
          'prop10': 'value10',
        },
      );

      test('Map with 20 properties', () async {
        final map = Map.fromIterables(
          List.generate(20, (i) => 'key${i + 1}'),
          List.generate(20, (i) => 'value${i + 1}'),
        );
        final jsonString = jsonEncode(map);

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
        expect(parsed, equals(map));
      });
    });

    group('Edge Cases', () {
      test('Chunk boundary on key', () async {
        final jsonString = '{"name":"John"}';
        final chunkSize = 5; // Will split as '{"nam', 'e":"J', 'ohn"}'

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
        expect(parsed, equals({'name': 'John'}));
      });

      test('Chunk boundary on value', () async {
        final jsonString = '{"city":"New York"}';
        final chunkSize = 7; // Will split in middle of "New York"

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
        expect(parsed, equals({'city': 'New York'}));
      });

      test('Very small chunks (1 char)', () async {
        final jsonString = '{"a":"b"}';

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
        expect(parsed, equals({'a': 'b'}));
      });

      test('Map with whitespace', () async {
        final jsonString = '{ "name" : "John" , "age" : 30 }';

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
        expect(parsed, equals({'name': 'John', 'age': 30}));
      });
    });

    group('Special Key Names', () {
      runMapTest(
        testName: 'Map with single-character keys',
        jsonString: '{"a":"1","b":"2","c":"3"}',
        expectedValue: {'a': '1', 'b': '2', 'c': '3'},
      );

      runMapTest(
        testName: 'Map with long keys',
        jsonString:
            '{"veryLongKeyNameHere":"value1","anotherReallyLongKeyName":"value2"}',
        expectedValue: {
          'veryLongKeyNameHere': 'value1',
          'anotherReallyLongKeyName': 'value2',
        },
      );

      runMapTest(
        testName: 'Map with keys containing underscores',
        jsonString: '{"first_name":"John","last_name":"Doe"}',
        expectedValue: {'first_name': 'John', 'last_name': 'Doe'},
      );

      runMapTest(
        testName: 'Map with keys containing numbers',
        jsonString: '{"key1":"value1","key2":"value2","key3":"value3"}',
        expectedValue: {'key1': 'value1', 'key2': 'value2', 'key3': 'value3'},
      );

      runMapTest(
        testName: 'Map with camelCase keys',
        jsonString: '{"firstName":"John","lastName":"Doe","isActive":true}',
        expectedValue: {
          'firstName': 'John',
          'lastName': 'Doe',
          'isActive': true,
        },
      );
    });

    group('Stress Tests', () {
      test(
        'Large flat map with 50 properties',
        () async {
          final map = Map.fromIterables(
            List.generate(50, (i) => 'property$i'),
            List.generate(50, (i) => 'value$i'),
          );
          final jsonString = jsonEncode(map);

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
          expect(parsed, equals(map));
        },
        timeout: const Timeout(Duration(seconds: 10)),
      );

      test(
        'Map with very long string values',
        () async {
          final longValue = 'x' * 1000;
          final jsonString = jsonEncode({
            'key1': longValue,
            'key2': longValue,
            'key3': longValue,
          });

          final accumulator = StreamAccumulator<String>();

          final stream = streamTextInChunks(
            text: jsonString,
            chunkSize: 50,
            interval: const Duration(microseconds: 1),
          );

          await for (final chunk in stream) {
            accumulator.add(chunk);
          }

          final accumulated = accumulator.getAccumulatedString();
          expect(accumulated, equals(jsonString));

          final parsed = jsonDecode(accumulated);
          expect(parsed['key1'], equals(longValue));
          expect(parsed['key2'], equals(longValue));
          expect(parsed['key3'], equals(longValue));
        },
        timeout: const Timeout(Duration(seconds: 10)),
      );
    });
  });
}
