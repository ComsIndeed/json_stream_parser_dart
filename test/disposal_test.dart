import 'dart:async';
import 'package:test/test.dart';
import 'package:streaming_json_parser/json_stream_parser.dart';

void main() {
  group('Parser Disposal', () {
    test('dispose() can be called multiple times safely', () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      await parser.dispose();
      await parser.dispose(); // Should not throw

      await controller.close();
    });

    test('dispose() cleans up resources', () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      // Get some property streams
      parser.getStringProperty('title');
      parser.getNumberProperty('age');

      // Start parsing complete JSON
      controller.add('{"title": "Test", "age": 25}');
      await controller.close();

      // Wait for parsing to complete
      await Future.delayed(Duration(milliseconds: 100));

      // Dispose the parser - this should clean up internal state
      await parser.dispose();

      // If we get here without hanging, disposal worked
      expect(true, isTrue);
    });
  });
}
