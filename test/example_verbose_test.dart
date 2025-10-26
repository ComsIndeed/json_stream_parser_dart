import 'dart:convert';
import 'package:json_stream_parser/utilities/stream_text_in_chunks.dart';
import 'package:test/test.dart';
import 'helpers/test_helpers.dart';

/// Example test file showing verbose output
/// This demonstrates how to see detailed output during test execution
void main() {
  group('Example Tests with Verbose Output', () {
    // Set this to true to see detailed output
    const verbose = true; // 👈 Change this to control verbosity

    test('Example: String streaming with verbose output', () async {
      final jsonString = '"Hello World!"';

      if (verbose) {
        print('\n${'=' * 60}');
        print('🧪 Test: String streaming with verbose output');
        print('=' * 60);
        print('Input JSON: $jsonString');
        print('Chunk size: 4');
        print('');
      }

      final accumulator = StreamAccumulator<String>();
      var chunkNumber = 0;

      final stream = streamTextInChunks(
        text: jsonString,
        chunkSize: 4,
        interval: const Duration(microseconds: 1),
      );

      await for (final chunk in stream) {
        chunkNumber++;
        accumulator.add(chunk);

        if (verbose) {
          print('📤 Chunk $chunkNumber: "$chunk"');
          print(
            '   Accumulated so far: "${accumulator.getAccumulatedString()}"',
          );
        }
      }

      final accumulated = accumulator.getAccumulatedString();

      if (verbose) {
        print('');
        print('✅ Final accumulated: "$accumulated"');
        print('📋 Expected: "$jsonString"');
        print('🎯 Match: ${accumulated == jsonString}');

        final parsed = jsonDecode(accumulated);
        print('🔍 Parsed value: "$parsed"');
        print('✨ Test completed successfully!');
        print('=' * 60 + '\n');
      }

      expect(accumulated, equals(jsonString));
      final parsed = jsonDecode(accumulated);
      expect(parsed, equals('Hello World!'));
    });

    test('Example: Map streaming with verbose output', () async {
      final map = {'name': 'Alice', 'age': 30, 'active': true};
      final jsonString = jsonEncode(map);

      if (verbose) {
        print('\n${'=' * 60}');
        print('🧪 Test: Map streaming with verbose output');
        print('=' * 60);
        print('Input map: $map');
        print('JSON string: $jsonString');
        print('Chunk size: 6');
        print('');
      }

      final accumulator = StreamAccumulator<String>();
      var chunkNumber = 0;

      final stream = streamTextInChunks(
        text: jsonString,
        chunkSize: 6,
        interval: const Duration(microseconds: 1),
      );

      await for (final chunk in stream) {
        chunkNumber++;
        accumulator.add(chunk);

        if (verbose) {
          print('📤 Chunk $chunkNumber: "$chunk"');
          print('   Accumulated: "${accumulator.getAccumulatedString()}"');

          // Try to parse if it looks complete
          final current = accumulator.getAccumulatedString();
          if (current.startsWith('{') && current.endsWith('}')) {
            try {
              final partial = jsonDecode(current);
              print('   ✓ Valid JSON so far: $partial');
            } catch (e) {
              print('   ⏳ Incomplete JSON...');
            }
          }
        }
      }

      final accumulated = accumulator.getAccumulatedString();

      if (verbose) {
        print('');
        print('✅ Final accumulated: "$accumulated"');
        final parsed = jsonDecode(accumulated);
        print('🔍 Parsed map: $parsed');
        print('📊 Keys: ${(parsed as Map).keys.toList()}');
        print('📊 Values: ${(parsed).values.toList()}');
        print('✨ Test completed successfully!');
        print('=' * 60 + '\n');
      }

      expect(accumulated, equals(jsonString));
      final parsed = jsonDecode(accumulated);
      expect(parsed, equals(map));
    });

    test('Example: List streaming with verbose output', () async {
      final list = [1, 2, 3, 4, 5];
      final jsonString = jsonEncode(list);

      if (verbose) {
        print('\n${'=' * 60}');
        print('🧪 Test: List streaming with verbose output');
        print('=' * 60);
        print('Input list: $list');
        print('JSON string: $jsonString');
        print('Chunk size: 3');
        print('');
      }

      final accumulator = StreamAccumulator<String>();
      var chunkNumber = 0;

      final stream = streamTextInChunks(
        text: jsonString,
        chunkSize: 3,
        interval: const Duration(microseconds: 1),
      );

      await for (final chunk in stream) {
        chunkNumber++;
        accumulator.add(chunk);

        if (verbose) {
          print('📤 Chunk $chunkNumber: "$chunk"');

          // Show what we have so far
          final current = accumulator.getAccumulatedString();
          print('   Accumulated: "$current"');

          // Try to parse
          if (current.startsWith('[') && current.endsWith(']')) {
            try {
              final partial = jsonDecode(current);
              print(
                '   ✓ Valid JSON: $partial (${(partial as List).length} items)',
              );
            } catch (e) {
              print('   ⏳ Incomplete JSON...');
            }
          }
        }
      }

      final accumulated = accumulator.getAccumulatedString();

      if (verbose) {
        print('');
        print('✅ Final accumulated: "$accumulated"');
        final parsed = jsonDecode(accumulated);
        print('🔍 Parsed list: $parsed');
        print('📊 Length: ${(parsed as List).length}');
        print('📊 Items: ${parsed.join(', ')}');
        print('✨ Test completed successfully!');
        print('=' * 60 + '\n');
      }

      expect(accumulated, equals(jsonString));
      final parsed = jsonDecode(accumulated);
      expect(parsed, equals(list));
    });

    test('Example: Complex nested structure', () async {
      final data = {
        'user': {
          'name': 'Bob',
          'tags': ['admin', 'user'],
        },
        'count': 42,
      };
      final jsonString = jsonEncode(data);

      if (verbose) {
        print('\n${'=' * 60}');
        print('🧪 Test: Complex nested structure');
        print('=' * 60);
        print('Input structure: $data');
        print('JSON string: $jsonString');
        print('Chunk size: 8');
        print('');
      }

      final accumulator = StreamAccumulator<String>();
      var chunkNumber = 0;

      final stream = streamTextInChunks(
        text: jsonString,
        chunkSize: 8,
        interval: const Duration(microseconds: 1),
      );

      await for (final chunk in stream) {
        chunkNumber++;
        accumulator.add(chunk);

        if (verbose) {
          print('📤 Chunk $chunkNumber: "$chunk"');
          final current = accumulator.getAccumulatedString();
          print('   Length: ${current.length} chars');

          // Try to parse
          try {
            final partial = jsonDecode(current);
            print('   ✓ Valid JSON: $partial');
          } catch (e) {
            print('   ⏳ Building JSON structure...');
          }
        }
      }

      final accumulated = accumulator.getAccumulatedString();

      if (verbose) {
        print('');
        print('✅ Final result:');
        final parsed = jsonDecode(accumulated);
        print('   Full structure: $parsed');
        print('   User name: ${parsed['user']['name']}');
        print('   User tags: ${parsed['user']['tags']}');
        print('   Count: ${parsed['count']}');
        print('✨ Test completed successfully!');
        print('=' * 60 + '\n');
      }

      expect(accumulated, equals(jsonString));
      final parsed = jsonDecode(accumulated);
      expect(parsed, equals(data));
    });
  });
}
