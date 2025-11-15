import 'dart:async';
import 'dart:convert';

import 'package:llm_json_stream/classes/json_stream_parser.dart';
import 'package:llm_json_stream/utilities/stream_text_in_chunks.dart';
import 'package:test/test.dart';

/// Comprehensive test suite demonstrating chunk size and stream speed variations
/// This test file is meant to be run with verbose output to show behavior

void main() {
  group('Comprehensive Chunk Size & Speed Matrix', () {
    const testJson = '{"name":"Alice","age":30,"active":true}';
    final chunkSizes = [1, 3, 10, 50, 100, 1000];
    final speeds = [
      Duration.zero,
      Duration(milliseconds: 5),
      Duration(milliseconds: 50),
      Duration(milliseconds: 100),
    ];

    for (final chunkSize in chunkSizes) {
      for (final speed in speeds) {
        test('chunkSize=$chunkSize, speed=${speed.inMilliseconds}ms', () async {
          final stream = streamTextInChunks(
            text: testJson,
            chunkSize: chunkSize,
            interval: speed,
          );

          final parser = JsonStreamParser(stream);
          final nameStream = parser.getStringProperty("name");
          final ageStream = parser.getNumberProperty("age");
          final activeStream = parser.getBooleanProperty("active");

          final start = DateTime.now();

          final results = await Future.wait([
            nameStream.future,
            ageStream.future,
            activeStream.future,
          ]).timeout(
            Duration(seconds: 10),
            onTimeout: () => throw TimeoutException(
              'FAILED: chunk=$chunkSize, speed=${speed.inMilliseconds}ms',
            ),
          );

          final elapsed = DateTime.now().difference(start);

          expect(results[0], equals('Alice'));
          expect(results[1], equals(30));
          expect(results[2], equals(true));

          // Calculate expected minimum time based on chunks and speed
          final numChunks = (testJson.length / chunkSize).ceil();
          final expectedMinTime = speed * (numChunks - 1);

          print('✅ chunk=$chunkSize, speed=${speed.inMilliseconds}ms, '
              'chunks=$numChunks, time=${elapsed.inMilliseconds}ms, '
              'expected≥${expectedMinTime.inMilliseconds}ms');
        });
      }
    }
  });

  group('Visual Demonstration of Bug Scenario', () {
    test('DEMONSTRATION: Tiny value, huge chunk', () async {
      print('\n${'=' * 80}');
      print('DEMONSTRATING: Chunk size (1000) >> Value size (1 char)');
      print('=' * 80);

      const testJson = '{"x":"a"}';
      print('JSON: $testJson (length: ${testJson.length})');
      print('Value "a" length: 1');

      const chunkSize = 1000;
      print('Chunk size: $chunkSize');
      print('Ratio: $chunkSize:1 (chunk size : value size)');

      final stream = streamTextInChunks(
        text: testJson,
        chunkSize: chunkSize,
        interval: Duration(milliseconds: 10),
      );

      final parser = JsonStreamParser(stream);
      final xStream = parser.getStringProperty("x");

      int streamEventCount = 0;
      xStream.stream.listen((chunk) {
        streamEventCount++;
        print('Stream event #$streamEventCount: "$chunk"');
      });

      print('\nWaiting for result...');
      final result = await xStream.future.timeout(
        Duration(seconds: 5),
        onTimeout: () {
          print('❌ TIMEOUT - BUG CONFIRMED!');
          throw TimeoutException('BUG: Parser failed with large chunk size');
        },
      );

      print('✅ SUCCESS: Result = "$result"');
      print('Stream events received: $streamEventCount');
      print('=' * 80 + '\n');

      expect(result, equals('a'));
    });

    test('DEMONSTRATION: Multiple tiny values, single chunk', () async {
      print('\n${'=' * 80}');
      print('DEMONSTRATING: Multiple 1-char values, single 1000-char chunk');
      print('=' * 80);

      const testJson = '{"a":"1","b":"2","c":"3"}';
      print('JSON: $testJson (length: ${testJson.length})');
      print('Chunk size: 1000 (entire JSON in one chunk)');

      final stream = streamTextInChunks(
        text: testJson,
        chunkSize: 1000,
        interval: Duration(milliseconds: 10),
      );

      final parser = JsonStreamParser(stream);
      final aStream = parser.getStringProperty("a");
      final bStream = parser.getStringProperty("b");
      final cStream = parser.getStringProperty("c");

      int aEvents = 0, bEvents = 0, cEvents = 0;
      aStream.stream.listen((c) => aEvents++);
      bStream.stream.listen((c) => bEvents++);
      cStream.stream.listen((c) => cEvents++);

      print('\nWaiting for results...');
      final results = await Future.wait([
        aStream.future,
        bStream.future,
        cStream.future,
      ]).timeout(
        Duration(seconds: 5),
        onTimeout: () {
          print('❌ TIMEOUT - BUG CONFIRMED!');
          throw TimeoutException('BUG: Parser failed');
        },
      );

      print('✅ SUCCESS:');
      print('  a = "${results[0]}" (stream events: $aEvents)');
      print('  b = "${results[1]}" (stream events: $bEvents)');
      print('  c = "${results[2]}" (stream events: $cEvents)');
      print('=' * 80 + '\n');

      expect(results, equals(['1', '2', '3']));
    });

    test('DEMONSTRATION: Compare 1-char chunk vs 1000-char chunk', () async {
      print('\n${'=' * 80}');
      print('COMPARING: Same JSON with different chunk sizes');
      print('=' * 80);

      const testJson = '{"value":"hello"}';
      print('JSON: $testJson');

      // Test with tiny chunks
      print('\n--- Test 1: Chunk size = 1 ---');
      final tinyStream = streamTextInChunks(
        text: testJson,
        chunkSize: 1,
        interval: Duration(milliseconds: 1),
      );
      final parser1 = JsonStreamParser(tinyStream);
      final value1Stream = parser1.getStringProperty("value");

      int events1 = 0;
      value1Stream.stream.listen((c) {
        events1++;
        print('  Chunk #$events1: "$c"');
      });

      final start1 = DateTime.now();
      final result1 = await value1Stream.future.timeout(Duration(seconds: 5));
      final time1 = DateTime.now().difference(start1);

      print(
          'Result: "$result1" (time: ${time1.inMilliseconds}ms, events: $events1)');

      // Test with huge chunk
      print('\n--- Test 2: Chunk size = 1000 ---');
      final hugeStream = streamTextInChunks(
        text: testJson,
        chunkSize: 1000,
        interval: Duration(milliseconds: 1),
      );
      final parser2 = JsonStreamParser(hugeStream);
      final value2Stream = parser2.getStringProperty("value");

      int events2 = 0;
      value2Stream.stream.listen((c) {
        events2++;
        print('  Chunk #$events2: "$c"');
      });

      final start2 = DateTime.now();
      final result2 = await value2Stream.future.timeout(Duration(seconds: 5));
      final time2 = DateTime.now().difference(start2);

      print(
          'Result: "$result2" (time: ${time2.inMilliseconds}ms, events: $events2)');

      print('\n--- Comparison ---');
      print('Both results match: ${result1 == result2} ✅');
      print('Tiny chunks: $events1 stream events, ${time1.inMilliseconds}ms');
      print('Huge chunk: $events2 stream events, ${time2.inMilliseconds}ms');
      print('=' * 80 + '\n');

      expect(result1, equals('hello'));
      expect(result2, equals('hello'));
      expect(result1, equals(result2));
    });
  });

  group('API Demo Flutter App Tests - Reproducing Real Bug', () {
    // This JSON mirrors the structure from the actual Flutter app demo
    final json = jsonEncode({
      "name": "Sample Item",
      "description":
          "This is a very long description that could potentially span multiple lines and contain a lot of information about the item, including its features, benefits, and usage.",
      "tags": [
        "sample tag 1 with some extra info",
        "sample tag 2 with more details",
        "sample tag 3 that is a bit longer",
      ],
      "details": {
        "color": "red",
        "size": "large",
        "weight": "1.5kg",
        "material": "plastic",
      },
      "status": "active",
    });

    // Print JSON for debugging
    print('\n${'=' * 80}');
    print('API DEMO TEST JSON (length: ${json.length} chars)');
    print('=' * 80);
    print(json);
    print('=' * 80 + '\n');

    final testCases = [
      {'chunkSize': 1, 'interval': 5},
      {'chunkSize': 5, 'interval': 10},
      {'chunkSize': 10, 'interval': 10},
      {'chunkSize': 25, 'interval': 10},
      {'chunkSize': 50, 'interval': 10},
      {'chunkSize': 100, 'interval': 5},
      {'chunkSize': 500, 'interval': 0},
      {'chunkSize': 1000, 'interval': 0},
    ];

    for (final testCase in testCases) {
      final chunkSize = testCase['chunkSize'] as int;
      final intervalMs = testCase['interval'] as int;

      test(
          'chunk=$chunkSize, interval=${intervalMs}ms - test futures AND streams',
          () async {
        final stream = streamTextInChunks(
          text: json,
          chunkSize: chunkSize,
          interval: Duration(milliseconds: intervalMs),
        );
        final parser = JsonStreamParser(stream);

        // Get properties
        final nameStream = parser.getStringProperty("name");
        final descriptionStream = parser.getStringProperty("description");
        final colorStream = parser.getStringProperty("details.color");
        final sizeStream = parser.getStringProperty("details.size");
        final weightStream = parser.getStringProperty("details.weight");
        final materialStream = parser.getStringProperty("details.material");
        final statusStream = parser.getStringProperty("status");

        // Accumulate stream chunks
        String streamName = '';
        String streamDescription = '';
        String streamColor = '';
        String streamSize = '';
        String streamWeight = '';
        String streamMaterial = '';
        String streamStatus = '';

        nameStream.stream.listen((chunk) => streamName += chunk);
        descriptionStream.stream.listen((chunk) => streamDescription += chunk);
        colorStream.stream.listen((chunk) => streamColor += chunk);
        sizeStream.stream.listen((chunk) => streamSize += chunk);
        weightStream.stream.listen((chunk) => streamWeight += chunk);
        materialStream.stream.listen((chunk) => streamMaterial += chunk);
        statusStream.stream.listen((chunk) => streamStatus += chunk);

        // Wait for futures
        final futureResults = await Future.wait([
          nameStream.future,
          descriptionStream.future,
          colorStream.future,
          sizeStream.future,
          weightStream.future,
          materialStream.future,
          statusStream.future,
        ]).timeout(
          Duration(seconds: 30),
          onTimeout: () => throw TimeoutException(
            'TIMEOUT: chunk=$chunkSize, interval=${intervalMs}ms',
          ),
        );

        // Verify futures
        expect(futureResults[0], equals('Sample Item'),
            reason: 'name future mismatch');
        expect(
          futureResults[1],
          equals(
              'This is a very long description that could potentially span multiple lines and contain a lot of information about the item, including its features, benefits, and usage.'),
          reason: 'description future mismatch',
        );
        expect(futureResults[2], equals('red'),
            reason: 'color future mismatch');
        expect(futureResults[3], equals('large'),
            reason: 'size future mismatch');
        expect(futureResults[4], equals('1.5kg'),
            reason: 'weight future mismatch');
        expect(futureResults[5], equals('plastic'),
            reason: 'material future mismatch');
        expect(futureResults[6], equals('active'),
            reason: 'status future mismatch');

        // Verify streams (accumulated chunks should match futures)
        expect(streamName, equals(futureResults[0]),
            reason: 'name stream chunks mismatch');
        expect(streamDescription, equals(futureResults[1]),
            reason: 'description stream chunks mismatch');
        expect(streamColor, equals(futureResults[2]),
            reason: 'color stream chunks mismatch');
        expect(streamSize, equals(futureResults[3]),
            reason: 'size stream chunks mismatch');
        expect(streamWeight, equals(futureResults[4]),
            reason: 'weight stream chunks mismatch');
        expect(streamMaterial, equals(futureResults[5]),
            reason: 'material stream chunks mismatch');
        expect(streamStatus, equals(futureResults[6]),
            reason: 'status stream chunks mismatch');

        print(
            '✅ chunk=$chunkSize, interval=${intervalMs}ms - ALL PASSED (futures & streams match)');
      });
    }

    test('SPECIFIC: Large chunk with nested properties', () async {
      print('\n${'=' * 80}');
      print('TESTING: Large chunk (1000) with nested JSON structure');
      print('=' * 80);

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 1000,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final colorStream = parser.getStringProperty("details.color");
      final weightStream = parser.getStringProperty("details.weight");

      final colorChunks = <String>[];
      final weightChunks = <String>[];

      colorStream.stream.listen((chunk) {
        print('  color chunk: "$chunk"');
        colorChunks.add(chunk);
      });
      weightStream.stream.listen((chunk) {
        print('  weight chunk: "$chunk"');
        weightChunks.add(chunk);
      });

      final results = await Future.wait([
        colorStream.future,
        weightStream.future,
      ]).timeout(Duration(seconds: 5));

      print('Color future: "${results[0]}"');
      print('Color stream chunks: $colorChunks -> "${colorChunks.join('')}"');
      print('Weight future: "${results[1]}"');
      print(
          'Weight stream chunks: $weightChunks -> "${weightChunks.join('')}"');
      print('=' * 80 + '\n');

      expect(results[0], equals('red'));
      expect(results[1], equals('1.5kg'));
      expect(colorChunks.join(''), equals('red'));
      expect(weightChunks.join(''), equals('1.5kg'));
    });

    test('SPECIFIC: Very small chunks with long description', () async {
      print('\n${'=' * 80}');
      print('TESTING: Tiny chunks (2 chars) with long description value');
      print('=' * 80);

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 2,
        interval: Duration(milliseconds: 1),
      );
      final parser = JsonStreamParser(stream);

      final descriptionStream = parser.getStringProperty("description");

      final descriptionChunks = <String>[];
      descriptionStream.stream.listen((chunk) {
        descriptionChunks.add(chunk);
      });

      final result =
          await descriptionStream.future.timeout(Duration(seconds: 10));

      final accumulated = descriptionChunks.join('');
      print('Description length: ${result.length}');
      print('Stream chunks received: ${descriptionChunks.length}');
      print('Accumulated matches future: ${accumulated == result}');
      print('=' * 80 + '\n');

      expect(result, contains('very long description'));
      expect(accumulated, equals(result));
      expect(descriptionChunks.length, greaterThan(1),
          reason:
              'Should have multiple chunks for long value with tiny chunk size');
    });
  });
}
