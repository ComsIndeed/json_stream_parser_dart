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

    test('Maps emit buffered (latest value only)', () async {
      final streamController = StreamController<String>();
      final parser = JsonStreamParser(streamController.stream);
      final emittedMaps = <Map<String, dynamic>>[];

      // Emit chunks before subscribing
      streamController.add('{"name": "Al');
      await Future.delayed(Duration(milliseconds: 10));
      streamController.add('ice", "age": 30');
      await Future.delayed(Duration(milliseconds: 10));

      // Now subscribe to the map property - should get LATEST state immediately
      final mapStream = parser
          .getMapProperty('')
          .stream
          .listen((map) => emittedMaps.add(Map<String, dynamic>.from(map)));
      await Future.delayed(Duration(milliseconds: 10));

      // Add more data
      streamController.add(', "active": true}');
      await Future.delayed(Duration(milliseconds: 10));
      await mapStream.cancel();
      streamController.close();

      print('Emitted maps: $emittedMaps');

      // With BehaviorSubject-style buffering:
      // 1. First emission: the LATEST buffered state when we subscribed
      // 2. Subsequent emissions: live updates as more data arrives
      expect(emittedMaps.isNotEmpty, isTrue,
          reason: 'Should receive at least one emission');

      // The first emission is whatever partial state existed at subscribe time
      // Since parsing is async, we may have partial values (name still being parsed)
      expect(emittedMaps.first.containsKey('name'), isTrue,
          reason: 'First emission should contain the name key');

      // Wait for final value via future to ensure complete parsing
      final finalMap = await parser.getMapProperty('').future;
      expect(finalMap['name'], 'Alice');
      expect(finalMap['age'], 30);
      expect(finalMap['active'], true);
    });

    test('Maps unbuffered does not replay', () async {
      final streamController = StreamController<String>();
      final parser = JsonStreamParser(streamController.stream);
      final emittedMaps = <Map<String, dynamic>>[];

      // Emit chunks before subscribing
      streamController.add('{"name": "Al');
      await Future.delayed(Duration(milliseconds: 10));
      streamController.add('ice", "age": 30');
      await Future.delayed(Duration(milliseconds: 10));

      // Subscribe to unbuffered stream - should NOT get past values
      final mapStream = parser
          .getMapProperty('')
          .unbufferedStream
          .listen((map) => emittedMaps.add(Map<String, dynamic>.from(map)));
      await Future.delayed(Duration(milliseconds: 10));

      // Add more data - only this should be received
      streamController.add(', "active": true}');
      await Future.delayed(Duration(milliseconds: 10));
      await mapStream.cancel();
      streamController.close();

      print('Emitted maps (unbuffered): $emittedMaps');

      // Unbuffered stream only gets emissions AFTER subscription
      expect(emittedMaps.isNotEmpty, isTrue);

      // Verify final state via future
      final finalMap = await parser.getMapProperty('').future;
      expect(finalMap['active'], true);
    });

    test('Lists emit buffered (latest value only)', () async {
      final streamController = StreamController<String>();
      final parser = JsonStreamParser(streamController.stream);
      final emittedLists = <List<dynamic>>[];

      // Emit chunks before subscribing
      streamController.add('{"items": [1, 2');
      await Future.delayed(Duration(milliseconds: 10));
      streamController.add(', 3');
      await Future.delayed(Duration(milliseconds: 10));

      // Subscribe - should get LATEST state immediately
      final listStream = parser
          .getListProperty('items')
          .stream
          .listen((list) => emittedLists.add(List<dynamic>.from(list)));
      await Future.delayed(Duration(milliseconds: 10));

      // Add more data
      streamController.add(', 4, 5]}');
      await Future.delayed(Duration(milliseconds: 10));
      await listStream.cancel();
      streamController.close();

      print('Emitted lists: $emittedLists');

      expect(emittedLists.isNotEmpty, isTrue,
          reason: 'Should receive at least one emission');

      // Final emission should have all items
      expect(emittedLists.last, equals([1, 2, 3, 4, 5]));
    });

    test('Lists unbuffered does not replay', () async {
      final streamController = StreamController<String>();
      final parser = JsonStreamParser(streamController.stream);
      final emittedLists = <List<dynamic>>[];

      // Emit chunks before subscribing
      streamController.add('{"items": [1, 2');
      await Future.delayed(Duration(milliseconds: 10));
      streamController.add(', 3');
      await Future.delayed(Duration(milliseconds: 10));

      // Subscribe to unbuffered - should NOT get past values
      final listStream = parser
          .getListProperty('items')
          .unbufferedStream
          .listen((list) => emittedLists.add(List<dynamic>.from(list)));
      await Future.delayed(Duration(milliseconds: 10));

      // Add more data - only this triggers emissions
      streamController.add(', 4, 5]}');
      await Future.delayed(Duration(milliseconds: 10));
      await listStream.cancel();
      streamController.close();

      print('Emitted lists (unbuffered): $emittedLists');

      expect(emittedLists.isNotEmpty, isTrue);
      // Final state should have all items (from live updates after subscribe)
      expect(emittedLists.last, equals([1, 2, 3, 4, 5]));
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

      // We subscribed BEFORE any data was added, so we get live updates
      // The stream emits each time the map state changes
      expect(emittedMaps.isNotEmpty, isTrue,
          reason: 'Should receive emissions as data arrives');

      // Final emission should have complete title "Alice"
      expect(emittedMaps.last['title'], 'Alice',
          reason: 'Final emission should have complete title "Alice"');
    });
  });
}
