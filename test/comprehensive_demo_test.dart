import 'dart:async';

import 'package:json_stream_parser/classes/json_stream_parser.dart';
import 'package:json_stream_parser/utilities/stream_text_in_chunks.dart';
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
}
