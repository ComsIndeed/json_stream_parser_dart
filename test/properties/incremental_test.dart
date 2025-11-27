import 'dart:async';

import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:test/test.dart';

void main() {
  group('Incremental Updates', () {
    test('String emits on each chunk', () async {
      final streamController = StreamController<String>();
      final parser = JsonStreamParser(streamController.stream);

      // First add the chunk, then subscribe
      print('Adding chunk 1: {"name":"Al');
      streamController.add('{"name":"Al');
      await Future.delayed(Duration(milliseconds: 10));

      final stringStream = parser.getStringProperty('name');
      final emittedStrings = <String>[];
      stringStream.stream.listen((str) {
        print('String emitted: $str');
        emittedStrings.add(str);
      });

      print('Adding chunk 2: ice"}');
      streamController.add('ice"}');
      await Future.delayed(Duration(milliseconds: 10));
      print('Emitted strings count: ${emittedStrings.length}');

      streamController.close();
      await Future.delayed(Duration(milliseconds: 10));

      print('Final emitted strings: $emittedStrings');

      // Strict expectations: We should get exactly one emission with "ice"
      expect(emittedStrings.length, 1,
          reason: 'Should emit exactly once after the string completes');
      expect(emittedStrings[0], 'ice',
          reason: 'Should emit the partial string "ice" before completion');
    });

    test('Nested map in list emits on each chunk', () async {
      final streamController = StreamController<String>();
      final parser = JsonStreamParser(streamController.stream);
      final mapStream = parser.getMapProperty('posts[0]');

      final emittedMaps = <Map<String, dynamic>>[];
      mapStream.stream.listen((map) {
        print('Map emitted: $map');
        emittedMaps.add(Map<String, dynamic>.from(map));
      });

      print('Adding chunk 1: {"posts":[{"title":"A');
      streamController.add('{"posts":[{"title":"A');
      await Future.delayed(Duration(milliseconds: 50));
      print('Emitted maps count: ${emittedMaps.length}');
      if (emittedMaps.isNotEmpty) {
        print('Last map: ${emittedMaps.last}');
      }

      print('Adding chunk 2: lice"}]}');
      streamController.add('lice"}]}');
      await Future.delayed(Duration(milliseconds: 50));
      print('Emitted maps count: ${emittedMaps.length}');
      if (emittedMaps.isNotEmpty) {
        print('Last map: ${emittedMaps.last}');
      }

      streamController.close();
      await Future.delayed(Duration(milliseconds: 50));

      print('Final emitted maps: $emittedMaps');
      print('Number of emissions: ${emittedMaps.length}');

      // Strict expectations: Should emit exactly 3 times with specific values
      expect(emittedMaps.length, 3,
          reason:
              'Should emit 3 times: initial map, after chunk 1, after chunk 2');

      // First emission: map with null title (initial state)
      expect(emittedMaps[0]['title'], null,
          reason: 'First emission should have null title');

      // Second emission: map with partial title "A"
      expect(emittedMaps[1]['title'], 'A',
          reason: 'Second emission should have partial title "A"');

      // Third emission: map with complete title "Alice"
      expect(emittedMaps[2]['title'], 'Alice',
          reason: 'Third emission should have complete title "Alice"');
    });
  });
}


