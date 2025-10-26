import 'dart:convert';
import 'package:json_stream_parser/utilities/stream_text_in_chunks.dart';
import 'package:test/test.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('List Property Stream Tests - Nested Lists', () {
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

    group('Lists with Objects', () {
      runListTest(
        testName: 'List of simple objects',
        jsonString: JsonTestData.listWithMaps(),
        expectedValue: [
          {'name': 'Alice', 'age': 30},
          {'name': 'Bob', 'age': 25},
        ],
      );

      runListTest(
        testName: 'List with single object',
        jsonString: '[{"id":1,"name":"test"}]',
        expectedValue: [
          {'id': 1, 'name': 'test'},
        ],
      );

      runListTest(
        testName: 'List of objects with mixed value types',
        jsonString:
            '[{"name":"Alice","age":30,"active":true,"score":95.5,"tags":null}]',
        expectedValue: [
          {
            'name': 'Alice',
            'age': 30,
            'active': true,
            'score': 95.5,
            'tags': null,
          },
        ],
      );

      runListTest(
        testName: 'List of empty objects',
        jsonString: '[{},{},{}]',
        expectedValue: [{}, {}, {}],
      );

      runListTest(
        testName: 'List of objects with varying properties',
        jsonString: '[{"a":1},{"b":2},{"c":3}]',
        expectedValue: [
          {'a': 1},
          {'b': 2},
          {'c': 3},
        ],
      );
    });

    group('Nested Lists (Lists within Lists)', () {
      runListTest(
        testName: 'List of lists - simple',
        jsonString: JsonTestData.nestedLists(),
        expectedValue: [
          [1, 2, 3],
          [4, 5, 6],
          [7, 8, 9],
        ],
      );

      runListTest(
        testName: 'List with empty nested lists',
        jsonString: '[[],[],[]]',
        expectedValue: [[], [], []],
      );

      runListTest(
        testName: 'List with single nested list',
        jsonString: '[[1,2,3]]',
        expectedValue: [
          [1, 2, 3],
        ],
      );

      runListTest(
        testName: 'List with nested lists of different lengths',
        jsonString: '[[1],[1,2],[1,2,3]]',
        expectedValue: [
          [1],
          [1, 2],
          [1, 2, 3],
        ],
      );

      runListTest(
        testName: 'Three levels of nesting',
        jsonString: '[[[1,2],[3,4]],[[5,6],[7,8]]]',
        expectedValue: [
          [
            [1, 2],
            [3, 4],
          ],
          [
            [5, 6],
            [7, 8],
          ],
        ],
      );

      test('Deeply nested lists (5 levels)', () async {
        final jsonString = '[[[[[1,2]]]]]';

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
        expect(parsed[0][0][0][0], equals([1, 2]));
      });
    });

    group('Lists with Nested Objects', () {
      test('List of objects with nested objects', () async {
        final jsonString = jsonEncode([
          {
            'name': 'Alice',
            'address': {'city': 'NYC', 'zip': '10001'},
          },
          {
            'name': 'Bob',
            'address': {'city': 'LA', 'zip': '90001'},
          },
        ]);

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
        expect(parsed[0]['address']['city'], equals('NYC'));
        expect(parsed[1]['address']['city'], equals('LA'));
      });

      test('List of objects with nested arrays', () async {
        final jsonString = jsonEncode([
          {
            'name': 'Alice',
            'tags': ['admin', 'user'],
          },
          {
            'name': 'Bob',
            'tags': ['user'],
          },
        ]);

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
        expect(parsed[0]['tags'], equals(['admin', 'user']));
        expect(parsed[1]['tags'], equals(['user']));
      });
    });

    group('Complex Nested Structures', () {
      runListTest(
        testName: 'Complex nested list from test data',
        jsonString: JsonTestData.complexNestedList(),
        expectedValue: [
          'string',
          123,
          [
            1,
            2,
            [3, 4],
          ],
          {
            'key': 'value',
            'nested': {'deep': true},
          },
          null,
        ],
      );

      test('List with mixed nesting patterns', () async {
        final jsonString = jsonEncode([
          {
            'type': 'object',
            'data': [1, 2, 3],
          },
          ['array', 'with', 'strings'],
          [
            [1, 2],
            [3, 4],
          ],
          {
            'nested': {
              'deep': {'deeper': 'value'},
            },
          },
        ]);

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
        expect(parsed[0]['data'], equals([1, 2, 3]));
        expect(parsed[1], equals(['array', 'with', 'strings']));
        expect(parsed[2][1], equals([3, 4]));
        expect(parsed[3]['nested']['deep']['deeper'], equals('value'));
      });

      test('Array of arrays of objects', () async {
        final jsonString = jsonEncode([
          [
            {'id': 1, 'name': 'A'},
            {'id': 2, 'name': 'B'},
          ],
          [
            {'id': 3, 'name': 'C'},
            {'id': 4, 'name': 'D'},
          ],
        ]);

        final accumulator = StreamAccumulator<String>();

        final stream = streamTextInChunks(
          text: jsonString,
          chunkSize: 18,
          interval: const Duration(microseconds: 1),
        );

        await for (final chunk in stream) {
          accumulator.add(chunk);
        }

        final accumulated = accumulator.getAccumulatedString();
        expect(accumulated, equals(jsonString));

        final parsed = jsonDecode(accumulated);
        expect(parsed[0][1]['name'], equals('B'));
        expect(parsed[1][0]['id'], equals(3));
      });

      test('Deep alternating list-object nesting', () async {
        final jsonString = jsonEncode([
          {
            'items': [
              {
                'values': [1, 2, 3],
                'nested': {
                  'deep': [
                    {'id': 1},
                    {'id': 2},
                  ],
                },
              },
            ],
          },
        ]);

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
        expect(parsed[0]['items'][0]['values'], equals([1, 2, 3]));
        expect(parsed[0]['items'][0]['nested']['deep'][1]['id'], equals(2));
      });
    });

    group('Edge Cases', () {
      test('Chunk boundary on nested array start', () async {
        final jsonString = '[[1,2],[3,4]]';
        final chunkSize = 6; // Will split as '[[1,2]' and ',[3,4]]'

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
        expect(
          parsed,
          equals([
            [1, 2],
            [3, 4],
          ]),
        );
      });

      test('Chunk boundary on nested object', () async {
        final jsonString = '[{"a":1},{"b":2}]';
        final chunkSize = 8; // Will split in middle

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
        expect(
          parsed,
          equals([
            {'a': 1},
            {'b': 2},
          ]),
        );
      });

      test('Very small chunks on complex nesting', () async {
        final jsonString = '[{"a":[1,2]}]';

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
        expect(parsed[0]['a'], equals([1, 2]));
      });
    });

    group('Stress Tests', () {
      test('Large list of objects', () async {
        final list = List.generate(
          50,
          (i) => {
            'id': i,
            'name': 'User $i',
            'data': [i * 2, i * 3, i * 4],
          },
        );
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
        expect(parsed.length, equals(50));
        expect(parsed[25]['id'], equals(25));
        expect(parsed[25]['data'], equals([50, 75, 100]));
      }, timeout: const Timeout(Duration(seconds: 10)));

      test('Deeply nested structure with many levels', () async {
        final jsonString = jsonEncode([
          {
            'level1': [
              {
                'level2': [
                  {
                    'level3': [
                      {'value': 'deep'},
                    ],
                  },
                ],
              },
            ],
          },
        ]);

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
        expect(
          parsed[0]['level1'][0]['level2'][0]['level3'][0]['value'],
          equals('deep'),
        );
      });

      test(
        'Matrix-like structure (10x10)',
        () async {
          final matrix = List.generate(
            10,
            (i) => List.generate(10, (j) => i * 10 + j),
          );
          final jsonString = jsonEncode(matrix);

          final accumulator = StreamAccumulator<String>();

          final stream = streamTextInChunks(
            text: jsonString,
            chunkSize: 40,
            interval: const Duration(microseconds: 1),
          );

          await for (final chunk in stream) {
            accumulator.add(chunk);
          }

          final accumulated = accumulator.getAccumulatedString();
          expect(accumulated, equals(jsonString));

          final parsed = jsonDecode(accumulated);
          expect(parsed[5][5], equals(55));
          expect(parsed[9][9], equals(99));
        },
        timeout: const Timeout(Duration(seconds: 10)),
      );
    });
  });
}
