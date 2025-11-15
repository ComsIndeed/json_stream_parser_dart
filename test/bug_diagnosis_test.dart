import 'dart:convert';

import 'package:json_stream_parser/classes/json_stream_parser.dart';
import 'package:json_stream_parser/utilities/stream_text_in_chunks.dart';
import 'package:test/test.dart';

/// Detailed diagnostic test to understand the chunk=25 bug

void main() {
  group('Bug Diagnosis - Chunk 25', () {
    test('Reproduce bug with minimal JSON', () async {
      // Simplified version that should hit the same issue
      final json = jsonEncode({
        "tags": ["more details"],
        "key": "value",
      });

      print('\n${'=' * 80}');
      print('MINIMAL TEST JSON');
      print('=' * 80);
      print('JSON: $json');
      print('Length: ${json.length}');
      print('=' * 80 + '\n');

      // Try different chunk sizes around the problem area
      for (final chunkSize in [10, 15, 20, 25, 30]) {
        print('\nTrying chunk size: $chunkSize');

        try {
          final stream = streamTextInChunks(
            text: json,
            chunkSize: chunkSize,
            interval: Duration(milliseconds: 10),
          );
          final parser = JsonStreamParser(stream);
          final keyStream = parser.getStringProperty("key");

          final result = await keyStream.future.timeout(Duration(seconds: 2));
          print('✅ chunk=$chunkSize SUCCESS: $result');
        } catch (e) {
          print('❌ chunk=$chunkSize FAILED: ${e.toString().split('\n').first}');
        }
      }
    });

    test('Exact reproduction - chunk boundary in list string', () async {
      // This JSON should split a string value inside a list at exactly chunk 25
      // {"tags":["sample details"]}
      // Position 0-25: {"tags":["sample details
      // Position 25+: "]}

      final json = '{"tags":["sample details"],"key":"val"}';
      print('\n${'=' * 80}');
      print('EXACT REPRODUCTION TEST');
      print('=' * 80);
      print('JSON: $json');
      print('Length: ${json.length}');

      // Show what chunks look like
      print('\nChunks with size 15:');
      for (int i = 0; i < (json.length / 15).ceil(); i++) {
        int start = i * 15;
        int end = (start + 15 < json.length) ? start + 15 : json.length;
        String chunk = json.substring(start, end);
        print('  [$start-$end): "$chunk"');
      }
      print('=' * 80 + '\n');

      try {
        final stream = streamTextInChunks(
          text: json,
          chunkSize: 15,
          interval: Duration(milliseconds: 10),
        );
        final parser = JsonStreamParser(stream);
        final keyStream = parser.getStringProperty("key");

        final result = await keyStream.future.timeout(Duration(seconds: 2));
        print('✅ Result: $result');
      } catch (e) {
        print('❌ FAILED: $e');
        rethrow;
      }
    });

    test('Test the actual failing JSON with chunk 25', () async {
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

      print('\n${'=' * 80}');
      print('ACTUAL FAILING JSON TEST');
      print('=' * 80);
      print('JSON length: ${json.length}');

      // Show the problematic chunks
      print('\nChunk 11-13 with size 25 (problematic area):');
      for (int i = 10; i < 13; i++) {
        int start = i * 25;
        int end = (start + 25 < json.length) ? start + 25 : json.length;
        if (end > json.length) break;
        String chunk = json.substring(start, end);
        print('  Chunk ${i + 1} [$start-$end): "$chunk"');
      }
      print('=' * 80 + '\n');

      print('Attempting to parse with chunk=25...');
      try {
        final stream = streamTextInChunks(
          text: json,
          chunkSize: 25,
          interval: Duration(milliseconds: 10),
        );
        final parser = JsonStreamParser(stream);
        final colorStream = parser.getStringProperty("details.color");

        final result = await colorStream.future.timeout(Duration(seconds: 5));
        print('✅ Unexpected success: $result');
      } catch (e) {
        print(
            '❌ Expected failure: ${e.toString().split('\n').take(3).join('\n')}');

        // This is expected - we're documenting the bug
      }
    });

    test('Concluding test for the bug', () async {
      // human written test
      final json = jsonEncode({
        "name": "Sample Item",
        "description":
            "This is a very long description that could potentially span multiple lines and contain a lot of information about the item, including its features, benefits, and usage.", // long description value
        "tags": [
          // list of strings
          "sample tag 1 with some extra info",
          "sample tag 2 with more details",
          "sample tag 3 that is a bit longer",
        ],
        "details": {
          // nested map
          "color": "red",
          "size": "large",
          "weight": "1.5kg",
          "material": "plastic",
        },
        "status": "active", // ending string key-value pair
      });

      final stream = streamTextInChunks(
          text: json, chunkSize: 25, interval: Duration(milliseconds: 100));
      final parser = JsonStreamParser(stream);

      String streamColor = "";
      String streamSize = "";
      String streamWeight = "";
      String streamMaterial = "";

      parser
          .getStringProperty("details.color")
          .stream
          .listen((chunk) => streamColor += chunk);
      parser
          .getStringProperty("details.size")
          .stream
          .listen((chunk) => streamSize += chunk);
      parser
          .getStringProperty("details.weight")
          .stream
          .listen((chunk) => streamWeight += chunk);
      parser
          .getStringProperty("details.material")
          .stream
          .listen((chunk) => streamMaterial += chunk);

      final futures = await Future.wait([
        parser.getStringProperty("details.color").future,
        parser.getStringProperty("details.size").future,
        parser.getStringProperty("details.weight").future,
        parser.getStringProperty("details.material").future
      ]);

      print({
        "streams": {
          "color": streamColor,
          "size": streamSize,
          "weight": streamWeight,
          "material": streamMaterial
        },
        "futures": {
          "color": futures[0],
          "size": futures[1],
          "weight": futures[2],
          "material": futures[3]
        }
      });

      expect(streamColor, "red");
      expect(streamSize, "large");
      expect(streamWeight, "1.5kg");
      expect(streamMaterial, "plastic");
      expect(futures[0], "red");
      expect(futures[1], "large");
      expect(futures[2], "1.5kg");
      expect(futures[3], "plastic");
    });
  });
}
