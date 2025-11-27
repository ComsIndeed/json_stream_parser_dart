import 'dart:async';

import 'package:llm_json_stream/json_stream_parser.dart';
import 'package:test/test.dart';

/// Specific test to reproduce the buffer flushing bug
///
/// When a stream completes without proper onDone handling,
/// buffered data in delegates may not be flushed properly

void main() {
  group('Buffer Flushing Bug Reproduction', () {
    test('POTENTIAL BUG: string ending without chunk boundary', () async {
      // Create a scenario where the string ends but there's still data in the buffer
      // This happens when the closing quote comes in but onChunkEnd was never called

      // Create a custom stream that sends the JSON in a specific pattern
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);
      final nameStream = parser.getStringProperty("name");

      // Send everything up to but not including the final character
      // This simulates a case where buffered data exists when stream closes
      controller.add('{"name":"Alic');

      // Small delay to let it process
      await Future.delayed(Duration(milliseconds: 10));

      // Send the rest and close
      controller.add('e"}');
      await controller.close();

      final result = await nameStream.future.timeout(
        Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Timed out'),
      );

      expect(result, equals('Alice'));
    });

    test('number at end of stream without delimiter', () async {
      // Numbers rely on delimiters or stream end to complete
      // If the stream ends without a delimiter, the number might not be parsed

      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);
      final countStream = parser.getNumberProperty("count");

      // Send in parts that don't align with value boundaries
      controller.add('{"count":4');
      await Future.delayed(Duration(milliseconds: 10));
      controller.add('2}');
      await controller.close();

      final result = await countStream.future.timeout(
        Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Timed out'),
      );

      expect(result, equals(42));
    });

    test('multiple values where last one has buffered data', () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);
      final aStream = parser.getStringProperty("a");
      final bStream = parser.getStringProperty("b");

      // Send chunks that split the last value
      controller.add('{"a":"x","b":"');
      await Future.delayed(Duration(milliseconds: 10));
      controller.add('y"}');
      await controller.close();

      final results = await Future.wait([
        aStream.future,
        bStream.future,
      ]).timeout(Duration(seconds: 5));

      expect(results[0], equals('x'));
      expect(results[1], equals('y'));
    });

    test('nested property at end with buffered data', () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);
      final nameStream = parser.getStringProperty("user.name");

      // Split in the middle of the nested value
      controller.add('{"user":{"name":"Bo');
      await Future.delayed(Duration(milliseconds: 10));
      controller.add('b"}}');
      await controller.close();

      final result = await nameStream.future.timeout(
        Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Timed out'),
      );

      expect(result, equals('Bob'));
    });

    test('stream closes while string buffer has content', () async {
      // This is the core bug: if we have buffered string content
      // and the stream closes, that buffer needs to be flushed

      const testJson = '{"msg":"test"}';

      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);
      final msgStream = parser.getStringProperty("msg");

      final chunks = <String>[];
      msgStream.stream.listen((chunk) {
        chunks.add(chunk);
      });

      // Send character by character except the last quote and brace
      for (int i = 0; i < testJson.length - 2; i++) {
        controller.add(testJson[i]);
        await Future.delayed(Duration(milliseconds: 5));
      }

      // Now send the closing quote and brace
      controller.add('"');
      controller.add('}');

      // Close the stream - this should trigger final buffer flush
      await controller.close();

      final result = await msgStream.future.timeout(
        Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Timed out'),
      );

      expect(result, equals('test'));
      expect(chunks.join(''), equals('test'));
    });

    test('verify onChunkEnd is called on stream completion', () async {
      // This test verifies that onChunkEnd is actually called
      // when the stream completes

      const testJson = '{"data":"value"}';

      // Use single large chunk - onChunkEnd should still be called once
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);
      final dataStream = parser.getStringProperty("data");

      final chunks = <String>[];
      dataStream.stream.listen((chunk) {
        chunks.add(chunk);
      });

      controller.add(testJson);
      await controller.close();

      final result = await dataStream.future.timeout(
        Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Timed out'),
      );

      expect(result, equals('value'));
      // If chunks is empty, it means onChunkEnd was never called
      // or the buffer was never flushed
      expect(chunks, isNotEmpty,
          reason: 'Stream should emit at least one chunk');
    });
  });

  group('Verify Current Behavior', () {
    test('how many stream chunks are emitted with large input chunk?',
        () async {
      const testJson = '{"text":"hello world"}';

      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);
      final textStream = parser.getStringProperty("text");

      final streamChunks = <String>[];
      textStream.stream.listen((chunk) {
        streamChunks.add(chunk);
      });

      // Send entire JSON in one chunk
      controller.add(testJson);
      await controller.close();

      await textStream.future.timeout(Duration(seconds: 5));

      print('Number of stream chunks emitted: ${streamChunks.length}');
      print('Stream chunks: $streamChunks');
      print('Combined: ${streamChunks.join('')}');

      expect(streamChunks.join(''), equals('hello world'));
    });

    test('track when onChunkEnd is called', () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      final aStream = parser.getStringProperty("a");
      final bStream = parser.getStringProperty("b");
      final cStream = parser.getStringProperty("c");

      final aChunks = <String>[];
      final bChunks = <String>[];
      final cChunks = <String>[];

      aStream.stream.listen((c) => aChunks.add(c));
      bStream.stream.listen((c) => bChunks.add(c));
      cStream.stream.listen((c) => cChunks.add(c));

      // Send in 3 chunks
      controller.add('{"a":"1"');
      await Future.delayed(Duration(milliseconds: 10));
      controller.add(',"b":"2"');
      await Future.delayed(Duration(milliseconds: 10));
      controller.add(',"c":"3"}');
      await controller.close();

      await Future.wait([
        aStream.future,
        bStream.future,
        cStream.future,
      ]).timeout(Duration(seconds: 5));

      print('a chunks (${aChunks.length}): $aChunks');
      print('b chunks (${bChunks.length}): $bChunks');
      print('c chunks (${cChunks.length}): $cChunks');
    });
  });
}


