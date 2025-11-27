import 'dart:async';

import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:test/test.dart';

/// Test to ensure the parser completes properly when the stream ends
/// This addresses a potential bug where the parser might not properly
/// handle the end of the stream, especially when chunk sizes are large

void main() {
  group('Stream Completion Tests', () {
    test('parser completes when stream closes - single large chunk', () async {
      const testJson = '{"name":"Alice"}';

      // Create a stream that emits the entire JSON in one chunk then closes
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);
      final nameStream = parser.getStringProperty("name");

      // Emit the entire JSON in one go
      controller.add(testJson);

      // Close the stream
      await controller.close();

      // The parser should still complete
      final result = await nameStream.future.timeout(
        Duration(seconds: 5),
        onTimeout: () => throw TimeoutException(
            'Parser did not complete when stream closed'),
      );

      expect(result, equals('Alice'));
    });

    test('parser completes when stream closes - multiple properties', () async {
      const testJson = '{"name":"Bob","age":25,"active":true}';

      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      final nameStream = parser.getStringProperty("name");
      final ageStream = parser.getNumberProperty("age");
      final activeStream = parser.getBooleanProperty("active");

      // Emit entire JSON and close
      controller.add(testJson);
      await controller.close();

      final results = await Future.wait([
        nameStream.future,
        ageStream.future,
        activeStream.future,
      ]).timeout(
        Duration(seconds: 5),
        onTimeout: () =>
            throw TimeoutException('Parser did not complete all properties'),
      );

      expect(results[0], equals('Bob'));
      expect(results[1], equals(25));
      expect(results[2], equals(true));
    });

    test('parser completes when stream closes - nested properties', () async {
      const testJson = '{"user":{"name":"Carol","age":30}}';

      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      final userStream = parser.getMapProperty("user");
      final nameStream = parser.getStringProperty("user.name");
      final ageStream = parser.getNumberProperty("user.age");

      // Emit entire JSON and close
      controller.add(testJson);
      await controller.close();

      final results = await Future.wait([
        userStream.future,
        nameStream.future,
        ageStream.future,
      ]).timeout(
        Duration(seconds: 5),
        onTimeout: () =>
            throw TimeoutException('Parser did not complete nested properties'),
      );

      expect(results[0], isA<Map<String, Object?>>());
      expect(results[1], equals('Carol'));
      expect(results[2], equals(30));
    });

    test('parser handles stream done event properly', () async {
      const testJson = '{"value":"test"}';

      // Use streamTextInChunks with very large chunk size
      final stream = streamTextInChunks(
        text: testJson,
        chunkSize: 1000,
        interval: Duration.zero,
      );

      final parser = JsonStreamParser(stream);
      final valueStream = parser.getStringProperty("value");

      final result = await valueStream.future.timeout(
        Duration(seconds: 5),
        onTimeout: () =>
            throw TimeoutException('Parser timed out with large chunk'),
      );

      expect(result, equals('test'));
    });

    test('string property at end of JSON with large chunk', () async {
      // Test the specific case where a string property is at the end
      // and the entire JSON comes in one chunk
      const testJson = '{"first":"value1","last":"value2"}';

      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      final firstStream = parser.getStringProperty("first");
      final lastStream = parser.getStringProperty("last");

      controller.add(testJson);
      await controller.close();

      final results = await Future.wait([
        firstStream.future,
        lastStream.future,
      ]).timeout(
        Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Did not complete'),
      );

      expect(results[0], equals('value1'));
      expect(results[1], equals('value2'));
    });

    test('incremental chunks vs single chunk - same result', () async {
      const testJson = '{"name":"Dave","score":100}';

      // Test with small chunks
      final smallChunkStream = streamTextInChunks(
        text: testJson,
        chunkSize: 3,
        interval: Duration(milliseconds: 5),
      );
      final parser1 = JsonStreamParser(smallChunkStream);
      final name1 = parser1.getStringProperty("name");
      final score1 = parser1.getNumberProperty("score");

      // Test with single large chunk
      final largeChunkStream = streamTextInChunks(
        text: testJson,
        chunkSize: 1000,
        interval: Duration(milliseconds: 5),
      );
      final parser2 = JsonStreamParser(largeChunkStream);
      final name2 = parser2.getStringProperty("name");
      final score2 = parser2.getNumberProperty("score");

      final results1 = await Future.wait([name1.future, score1.future])
          .timeout(Duration(seconds: 5));
      final results2 = await Future.wait([name2.future, score2.future])
          .timeout(Duration(seconds: 5));

      expect(results1[0], equals(results2[0]));
      expect(results1[1], equals(results2[1]));
      expect(results1[0], equals('Dave'));
      expect(results1[1], equals(100));
    });
  });

  group('Stream Listener Behavior', () {
    test('string stream emits chunks with small chunk size', () async {
      const testJson = '{"text":"hello"}';

      final stream = streamTextInChunks(
        text: testJson,
        chunkSize: 2,
        interval: Duration(milliseconds: 5),
      );

      final parser = JsonStreamParser(stream);
      final textStream = parser.getStringProperty("text");

      final chunks = <String>[];
      textStream.stream.listen((chunk) {
        chunks.add(chunk);
      });

      await textStream.future.timeout(Duration(seconds: 5));

      // With small chunks, we should get multiple emissions
      expect(chunks, isNotEmpty);
      expect(chunks.join(''), equals('hello'));
    });

    test('string stream behavior with large chunk size', () async {
      const testJson = '{"text":"hello"}';

      final stream = streamTextInChunks(
        text: testJson,
        chunkSize: 1000,
        interval: Duration(milliseconds: 5),
      );

      final parser = JsonStreamParser(stream);
      final textStream = parser.getStringProperty("text");

      final chunks = <String>[];
      textStream.stream.listen((chunk) {
        chunks.add(chunk);
      });

      await textStream.future.timeout(Duration(seconds: 5));

      // Even with large chunks, we should get the complete value
      expect(chunks.join(''), equals('hello'));
    });
  });

  group('Edge Case - Stream Close Timing', () {
    test('close stream immediately after adding data', () async {
      const testJson = '{"key":"value"}';

      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);
      final keyStream = parser.getStringProperty("key");

      // Add and close synchronously
      controller.add(testJson);
      controller.close();

      final result = await keyStream.future.timeout(
        Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Timed out'),
      );

      expect(result, equals('value'));
    });

    test('close stream with delay after adding data', () async {
      const testJson = '{"key":"value"}';

      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);
      final keyStream = parser.getStringProperty("key");

      controller.add(testJson);

      // Add a small delay before closing
      await Future.delayed(Duration(milliseconds: 50));
      await controller.close();

      final result = await keyStream.future.timeout(
        Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Timed out'),
      );

      expect(result, equals('value'));
    });
  });
}


