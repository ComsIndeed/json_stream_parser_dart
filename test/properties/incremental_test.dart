import 'dart:async';

import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:test/test.dart';

void main() {
  group('Incremental Updates', () {
    test('String emits on each chunk', () async {
      final streamController = StreamController<String>();
      final parser = JsonStreamParser(streamController.stream);

      // Subscribe BEFORE adding chunks to capture all emissions
      final stringStream = parser.getStringProperty('name');
      final emittedStrings = <String>[];
      stringStream.stream.listen((str) {
        print('String emitted: $str');
        emittedStrings.add(str);
      });

      print('Adding chunk 1: {"name":"Al');
      streamController.add('{"name":"Al');
      await Future.delayed(Duration(milliseconds: 10));
      print('Emitted strings count: ${emittedStrings.length}');

      print('Adding chunk 2: ice"}');
      streamController.add('ice"}');
      await Future.delayed(Duration(milliseconds: 10));
      print('Emitted strings count: ${emittedStrings.length}');

      streamController.close();
      await Future.delayed(Duration(milliseconds: 10));

      print('Final emitted strings: $emittedStrings');

      // String stream emits each chunk as it arrives (not accumulated)
      // This is the expected behavior for streaming strings
      expect(emittedStrings.length, 2,
          reason: 'Should emit twice - once per chunk');
      expect(emittedStrings[0], 'Al',
          reason: 'First emission should have first chunk "Al"');
      expect(emittedStrings[1], 'ice',
          reason: 'Second emission should have second chunk "ice"');

      // To get the complete string, use the future property
      final complete = await stringStream.future;
      expect(complete, 'Alice',
          reason: 'Future should return complete string "Alice"');
    });

    test('String emits buffered chunks', () async {
      final streamController = StreamController<String>();
      final parser = JsonStreamParser(streamController.stream);
      final emittedStrings = <String>[];

      // Emit chunks before subscribing
      streamController.add('{"title":"This i');
      await Future.delayed(Duration(milliseconds: 10));
      streamController.add('s a co');
      await Future.delayed(Duration(milliseconds: 10));
      // Now subscribe to the string property
      final stringStream = parser
          .getStringProperty('title')
          .stream
          .listen((str) => emittedStrings.add(str));
      // Add final chunk
      await Future.delayed(Duration(
          milliseconds: 10)); // TODO: Test fails without this for some reason!
      streamController.add('ol parser!');
      await Future.delayed(Duration(milliseconds: 10));
      streamController.add(' Whatt!"}');
      await Future.delayed(Duration(milliseconds: 10));
      await stringStream.cancel();
      streamController.close();

      // The string stream should emit all buffered chunks upon subscription
      print('Emitted strings: $emittedStrings');
      expect(emittedStrings.length, 3,
          reason:
              'Should emit 3 times. First for buffered, the last two for final chunk');

      expect(emittedStrings.join(), 'This is a cool parser! Whatt!');
      expect(emittedStrings[0], 'This is a co');
      expect(emittedStrings[1], 'ol parser!');
      expect(emittedStrings[2], ' Whatt!');
    });

    test('String does not emit unbuffereds', () async {
      final streamController = StreamController<String>();
      final parser = JsonStreamParser(streamController.stream);
      final emittedStrings = <String>[];

      // Emit chunks before subscribing
      streamController.add('{"title":"This i');
      await Future.delayed(Duration(milliseconds: 10));
      streamController.add('s a co');
      await Future.delayed(Duration(milliseconds: 10));
      // Now subscribe to the string property
      final stringStream = parser
          .getStringProperty('title')
          .unbufferedStream
          .listen((str) => emittedStrings.add(str));
      // Add final chunk
      await Future.delayed(Duration(
          milliseconds: 10)); // TODO: Test fails without this for some reason!
      streamController.add('ol parser!');
      await Future.delayed(Duration(milliseconds: 10));
      streamController.add(' Whatt!"}');
      await Future.delayed(Duration(milliseconds: 10));
      await stringStream.cancel();
      streamController.close();

      // The string stream should not emit buffered chunks upon subscription
      print('Emitted strings: $emittedStrings');
      expect(emittedStrings.length, 2,
          reason:
              'Should emit 2 times. Only for final chunks, no buffered emissions');

      expect(emittedStrings.join(), 'ol parser! Whatt!');
      expect(emittedStrings[0], 'ol parser!');
      expect(emittedStrings[1], ' Whatt!');
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
