import 'dart:convert';
import 'package:json_stream_parser/utilities/stream_text_in_chunks.dart';
import 'package:test/test.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Map Property Stream Tests - Nested Maps', () {
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
          expect(parsed, isA<Map>());

          if (verbose) TestPrinter.printPassed();
        }
      });
    }

    group('Simple Nested Maps', () {
      runMapTest(
        testName: 'Map with one level of nesting',
        jsonString: '{"user":{"name":"John","age":30}}',
        expectedValue: {
          'user': {'name': 'John', 'age': 30},
        },
      );

      runMapTest(
        testName: 'Map with multiple nested objects',
        jsonString: JsonTestData.nestedMaps(),
        expectedValue: {
          'user': {
            'name': 'John',
            'address': {'street': '123 Main St', 'city': 'New York'},
          },
        },
      );

      runMapTest(
        testName: 'Map with empty nested object',
        jsonString: '{"outer":{},"inner":{"data":"value"}}',
        expectedValue: {
          'outer': {},
          'inner': {'data': 'value'},
        },
      );

      runMapTest(
        testName: 'Map with nested object as last property',
        jsonString: '{"name":"John","details":{"age":30,"city":"NYC"}}',
        expectedValue: {
          'name': 'John',
          'details': {'age': 30, 'city': 'NYC'},
        },
      );
    });

    group('Deeply Nested Maps', () {
      runMapTest(
        testName: 'Three levels of nesting',
        jsonString: '{"level1":{"level2":{"level3":"value"}}}',
        expectedValue: {
          'level1': {
            'level2': {'level3': 'value'},
          },
        },
      );

      runMapTest(
        testName: 'Five levels of nesting',
        jsonString: '{"a":{"b":{"c":{"d":{"e":"deep"}}}}}',
        expectedValue: {
          'a': {
            'b': {
              'c': {
                'd': {'e': 'deep'},
              },
            },
          },
        },
      );

      test('Very deep nesting (10 levels)', () async {
        final jsonString =
            '{"l1":{"l2":{"l3":{"l4":{"l5":{"l6":{"l7":{"l8":{"l9":{"l10":"bottom"}}}}}}}}}}';

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
        expect(
          parsed['l1']['l2']['l3']['l4']['l5']['l6']['l7']['l8']['l9']['l10'],
          equals('bottom'),
        );
      });
    });

    group('Maps with Lists', () {
      runMapTest(
        testName: 'Map with simple array',
        jsonString: JsonTestData.mapWithLists(),
        expectedValue: {
          'name': 'John',
          'hobbies': ['reading', 'gaming', 'coding'],
          'scores': [10, 20, 30],
        },
      );

      runMapTest(
        testName: 'Map with empty array',
        jsonString: '{"name":"John","tags":[]}',
        expectedValue: {'name': 'John', 'tags': []},
      );

      runMapTest(
        testName: 'Map with array of mixed types',
        jsonString: '{"data":["string",42,true,null,3.14]}',
        expectedValue: {
          'data': ['string', 42, true, null, 3.14],
        },
      );

      runMapTest(
        testName: 'Map with multiple arrays',
        jsonString:
            '{"strings":["a","b","c"],"numbers":[1,2,3],"bools":[true,false]}',
        expectedValue: {
          'strings': ['a', 'b', 'c'],
          'numbers': [1, 2, 3],
          'bools': [true, false],
        },
      );

      runMapTest(
        testName: 'Map with nested array in nested object',
        jsonString: '{"user":{"name":"John","tags":["admin","user"]}}',
        expectedValue: {
          'user': {
            'name': 'John',
            'tags': ['admin', 'user'],
          },
        },
      );
    });

    group('Maps with Nested Lists of Objects', () {
      runMapTest(
        testName: 'Map with array of objects',
        jsonString:
            '{"users":[{"name":"Alice","age":30},{"name":"Bob","age":25}]}',
        expectedValue: {
          'users': [
            {'name': 'Alice', 'age': 30},
            {'name': 'Bob', 'age': 25},
          ],
        },
      );

      runMapTest(
        testName: 'Complex nested map structure',
        jsonString: JsonTestData.complexNestedMap(),
        expectedValue: {
          'users': [
            {
              'name': 'Alice',
              'tags': ['admin', 'user'],
              'metadata': {'created': '2024-01-01', 'active': true},
            },
            {
              'name': 'Bob',
              'tags': ['user'],
              'metadata': {'created': '2024-01-02', 'active': false},
            },
          ],
          'count': 2,
        },
      );

      test('Deeply nested array of objects', () async {
        final jsonString = jsonEncode({
          'company': {
            'departments': [
              {
                'name': 'Engineering',
                'teams': [
                  {
                    'name': 'Frontend',
                    'members': [
                      {'name': 'Alice', 'role': 'Lead'},
                      {'name': 'Bob', 'role': 'Dev'},
                    ],
                  },
                ],
              },
            ],
          },
        });

        final accumulator = StreamAccumulator<String>();

        final stream = streamTextInChunks(
          text: jsonString,
          chunkSize: 15,
          interval: const Duration(microseconds: 1),
        );

        await for (final chunk in stream) {
          accumulator.add(chunk);
        }

        final accumulated = accumulator.getAccumulatedString();
        expect(accumulated, equals(jsonString));

        final parsed = jsonDecode(accumulated);
        expect(
          parsed['company']['departments'][0]['teams'][0]['members'][0]['name'],
          equals('Alice'),
        );
      });
    });

    group('Mixed Nesting Patterns', () {
      test('Map with alternating object-array nesting', () async {
        final jsonString = jsonEncode({
          'level1': {
            'items': [
              {
                'data': {
                  'values': [1, 2, 3],
                },
              },
            ],
          },
        });

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
        expect(
          parsed['level1']['items'][0]['data']['values'],
          equals([1, 2, 3]),
        );
      });

      test('Map with nested arrays of arrays', () async {
        final jsonString = jsonEncode({
          'matrix': [
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, 9],
          ],
        });

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
        expect(parsed['matrix'][1][1], equals(5));
      });

      test('Map with multiple nesting styles', () async {
        final jsonString = jsonEncode({
          'simple': 'value',
          'nested': {'key': 'value'},
          'array': [1, 2, 3],
          'complex': {
            'data': [
              {
                'id': 1,
                'tags': ['a', 'b'],
              },
              {
                'id': 2,
                'tags': ['c', 'd'],
              },
            ],
          },
        });

        final accumulator = StreamAccumulator<String>();

        final stream = streamTextInChunks(
          text: jsonString,
          chunkSize: 12,
          interval: const Duration(microseconds: 1),
        );

        await for (final chunk in stream) {
          accumulator.add(chunk);
        }

        final accumulated = accumulator.getAccumulatedString();
        expect(accumulated, equals(jsonString));

        final parsed = jsonDecode(accumulated);
        expect(parsed['simple'], equals('value'));
        expect(parsed['nested']['key'], equals('value'));
        expect(parsed['array'], equals([1, 2, 3]));
        expect(parsed['complex']['data'][0]['id'], equals(1));
      });
    });

    group('Edge Cases', () {
      test('Chunk boundary on nested object start', () async {
        final jsonString = '{"outer":{"inner":"value"}}';
        final chunkSize =
            9; // Will split at '{"outer":{' and '"inner":"value"}}'

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
        expect(parsed['outer']['inner'], equals('value'));
      });

      test('Very small chunks on complex nesting', () async {
        final jsonString = '{"a":{"b":{"c":"d"}}}';

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
        expect(parsed['a']['b']['c'], equals('d'));
      });
    });

    group('Stress Tests', () {
      test('Large nested structure', () async {
        final jsonString = jsonEncode({
          'data': List.generate(
            10,
            (i) => {
              'id': i,
              'nested': {
                'values': List.generate(5, (j) => j * i),
                'metadata': {
                  'created': '2024-01-0${i + 1}',
                  'tags': ['tag$i', 'tag${i + 1}'],
                },
              },
            },
          ),
        });

        final accumulator = StreamAccumulator<String>();

        final stream = streamTextInChunks(
          text: jsonString,
          chunkSize: 25,
          interval: const Duration(microseconds: 1),
        );

        await for (final chunk in stream) {
          accumulator.add(chunk);
        }

        final accumulated = accumulator.getAccumulatedString();
        expect(accumulated, equals(jsonString));

        final parsed = jsonDecode(accumulated);
        expect(parsed['data'].length, equals(10));
        expect(
          parsed['data'][5]['nested']['values'],
          equals([0, 5, 10, 15, 20]),
        );
      }, timeout: const Timeout(Duration(seconds: 10)));
    });
  });
}
