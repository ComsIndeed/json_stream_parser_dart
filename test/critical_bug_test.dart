import 'dart:async';

import 'package:streaming_json_parser/classes/json_stream_parser.dart';
import 'package:streaming_json_parser/utilities/stream_text_in_chunks.dart';
import 'package:test/test.dart';

/// Critical test to verify the exact bug scenario:
/// When chunk size is larger than the value, does the parser work correctly?

void main() {
  group('Bug Report: Chunk Size Larger Than Value', () {
    test('CRITICAL: Single character value with huge chunk', () async {
      const testJson = '{"x":"a"}';

      // Chunk size (1000) is much larger than value ("a" = 1 char)
      final stream = streamTextInChunks(
        text: testJson,
        chunkSize: 1000,
        interval: Duration(milliseconds: 10),
      );

      final parser = JsonStreamParser(stream);
      final xStream = parser.getStringProperty("x");

      final result = await xStream.future.timeout(
        Duration(seconds: 5),
        onTimeout: () => throw TimeoutException(
            'BUG: Parser timed out when chunk size > value size'),
      );

      expect(result, equals('a'),
          reason: 'Single character value should be parsed correctly');
    });

    test('CRITICAL: Two character value with huge chunk', () async {
      const testJson = '{"xy":"ab"}';

      // Chunk size (500) is much larger than value ("ab" = 2 chars)
      final stream = streamTextInChunks(
        text: testJson,
        chunkSize: 500,
        interval: Duration(milliseconds: 10),
      );

      final parser = JsonStreamParser(stream);
      final xyStream = parser.getStringProperty("xy");

      final result = await xyStream.future.timeout(
        Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('BUG: Parser timed out'),
      );

      expect(result, equals('ab'));
    });

    test('CRITICAL: Empty string with huge chunk', () async {
      const testJson = '{"empty":""}';

      // Chunk size (1000) is larger than value ("" = 0 chars)
      final stream = streamTextInChunks(
        text: testJson,
        chunkSize: 1000,
        interval: Duration(milliseconds: 10),
      );

      final parser = JsonStreamParser(stream);
      final emptyStream = parser.getStringProperty("empty");

      final result = await emptyStream.future.timeout(
        Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('BUG: Parser timed out'),
      );

      expect(result, equals(''));
    });

    test('CRITICAL: Single digit number with huge chunk', () async {
      const testJson = '{"n":5}';

      // Chunk size (1000) is larger than value (5 = 1 char)
      final stream = streamTextInChunks(
        text: testJson,
        chunkSize: 1000,
        interval: Duration(milliseconds: 10),
      );

      final parser = JsonStreamParser(stream);
      final nStream = parser.getNumberProperty("n");

      final result = await nStream.future.timeout(
        Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('BUG: Parser timed out'),
      );

      expect(result, equals(5));
    });

    test('CRITICAL: Boolean value with huge chunk', () async {
      const testJson = '{"flag":true}';

      // Chunk size (1000) is larger than value ("true" = 4 chars)
      final stream = streamTextInChunks(
        text: testJson,
        chunkSize: 1000,
        interval: Duration(milliseconds: 10),
      );

      final parser = JsonStreamParser(stream);
      final flagStream = parser.getBooleanProperty("flag");

      final result = await flagStream.future.timeout(
        Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('BUG: Parser timed out'),
      );

      expect(result, equals(true));
    });

    test('CRITICAL: Null value with huge chunk', () async {
      const testJson = '{"nothing":null}';

      // Chunk size (1000) is larger than value ("null" = 4 chars)
      final stream = streamTextInChunks(
        text: testJson,
        chunkSize: 1000,
        interval: Duration(milliseconds: 10),
      );

      final parser = JsonStreamParser(stream);
      final nothingStream = parser.getNullProperty("nothing");

      final result = await nothingStream.future.timeout(
        Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('BUG: Parser timed out'),
      );

      expect(result, isNull);
    });

    test('CRITICAL: Compare small value - small chunk vs large chunk',
        () async {
      const testJson = '{"val":"hi"}';

      // Test 1: Small chunks (working case)
      final smallChunkStream = streamTextInChunks(
        text: testJson,
        chunkSize: 2,
        interval: Duration(milliseconds: 5),
      );
      final parser1 = JsonStreamParser(smallChunkStream);
      final val1Stream = parser1.getStringProperty("val");
      final result1 = await val1Stream.future.timeout(Duration(seconds: 5));

      // Test 2: Large chunk (potentially buggy case)
      final largeChunkStream = streamTextInChunks(
        text: testJson,
        chunkSize: 1000,
        interval: Duration(milliseconds: 5),
      );
      final parser2 = JsonStreamParser(largeChunkStream);
      final val2Stream = parser2.getStringProperty("val");
      final result2 = await val2Stream.future.timeout(Duration(seconds: 5));

      expect(result1, equals('hi'), reason: 'Small chunks should work');
      expect(result2, equals('hi'), reason: 'Large chunks should also work');
      expect(result1, equals(result2),
          reason: 'Both should produce the same result');
    });

    test('CRITICAL: Very small value (1 char) vs very large chunk (10000)',
        () async {
      const testJson = '{"k":"v"}';

      final stream = streamTextInChunks(
        text: testJson,
        chunkSize: 10000,
        interval: Duration(milliseconds: 10),
      );

      final parser = JsonStreamParser(stream);
      final kStream = parser.getStringProperty("k");

      final result = await kStream.future.timeout(
        Duration(seconds: 5),
        onTimeout: () => throw TimeoutException(
            'BUG CONFIRMED: Parser cannot handle chunk size much larger than value'),
      );

      expect(result, equals('v'));
    });

    test('CRITICAL: Multiple tiny values with single massive chunk', () async {
      const testJson = '{"a":"1","b":"2","c":"3","d":"4","e":"5"}';

      final stream = streamTextInChunks(
        text: testJson,
        chunkSize: 10000,
        interval: Duration(milliseconds: 10),
      );

      final parser = JsonStreamParser(stream);

      final results = await Future.wait([
        parser.getStringProperty("a").future,
        parser.getStringProperty("b").future,
        parser.getStringProperty("c").future,
        parser.getStringProperty("d").future,
        parser.getStringProperty("e").future,
      ]).timeout(
        Duration(seconds: 5),
        onTimeout: () => throw TimeoutException(
            'BUG: Multiple tiny values failed with large chunk'),
      );

      expect(results, equals(['1', '2', '3', '4', '5']));
    });

    test('CRITICAL: Check if onChunkEnd matters when chunk > value', () async {
      // This test helps determine if the bug is related to onChunkEnd
      // not being called when the entire JSON comes in one chunk

      const testJson = '{"msg":"x"}';

      final stream = streamTextInChunks(
        text: testJson,
        chunkSize: 1000,
        interval: Duration(milliseconds: 10),
      );

      final parser = JsonStreamParser(stream);
      final msgStream = parser.getStringProperty("msg");

      // Listen to stream events to see if chunks are emitted
      int chunkCount = 0;
      msgStream.stream.listen((chunk) {
        chunkCount++;
      });

      final result = await msgStream.future.timeout(
        Duration(seconds: 5),
        onTimeout: () =>
            throw TimeoutException('BUG: onChunkEnd not properly handled'),
      );

      expect(result, equals('x'));
      print('Chunks emitted when chunk size >> value size: $chunkCount');
      expect(chunkCount, greaterThan(0),
          reason:
              'At least one chunk should be emitted even with large input chunks');
    });
  });

  group('Stress Test: Extreme Chunk Size Ratios', () {
    test('chunk size 1000x larger than value', () async {
      const testJson = '{"tiny":"ab"}'; // value is 2 chars

      final stream = streamTextInChunks(
        text: testJson,
        chunkSize: 2000, // 1000x larger
        interval: Duration(milliseconds: 10),
      );

      final parser = JsonStreamParser(stream);
      final tinyStream = parser.getStringProperty("tiny");

      final result = await tinyStream.future.timeout(Duration(seconds: 5));
      expect(result, equals('ab'));
    });

    test('chunk size 10000x larger than value', () async {
      const testJson = '{"nano":"a"}'; // value is 1 char

      final stream = streamTextInChunks(
        text: testJson,
        chunkSize: 10000, // 10000x larger
        interval: Duration(milliseconds: 10),
      );

      final parser = JsonStreamParser(stream);
      final nanoStream = parser.getStringProperty("nano");

      final result = await nanoStream.future.timeout(Duration(seconds: 5));
      expect(result, equals('a'));
    });

    test('instant delivery (0ms) with massive chunk', () async {
      const testJson = '{"fast":"go"}';

      final stream = streamTextInChunks(
        text: testJson,
        chunkSize: 99999,
        interval: Duration.zero, // Instant delivery
      );

      final parser = JsonStreamParser(stream);
      final fastStream = parser.getStringProperty("fast");

      final result = await fastStream.future.timeout(Duration(seconds: 5));
      expect(result, equals('go'));
    });
  });
}
