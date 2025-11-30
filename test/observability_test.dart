import 'dart:async';

import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:test/test.dart';

void main() {
  group('Observability - Parser Logging', () {
    test('Parser emits rootStart and rootComplete events', () async {
      final events = <ParseEvent>[];
      final controller = StreamController<String>();
      final parser = JsonStreamParser(
        controller.stream,
        onLog: (event) => events.add(event),
      );

      controller.add('{"name": "test"}');
      await Future.delayed(Duration(milliseconds: 20));

      await controller.close();
      await parser.dispose();

      expect(events.any((e) => e.type == ParseEventType.rootStart), isTrue);
      expect(events.any((e) => e.type == ParseEventType.rootComplete), isTrue);
    });

    test('Parser emits propertyStart and propertyComplete for string',
        () async {
      final events = <ParseEvent>[];
      final controller = StreamController<String>();
      final parser = JsonStreamParser(
        controller.stream,
        onLog: (event) => events.add(event),
      );

      parser.getStringProperty('name'); // Subscribe to the property

      controller.add('{"name": "Alice"}');
      await Future.delayed(Duration(milliseconds: 20));

      await controller.close();
      await parser.dispose();

      final nameStartEvents = events.where(
        (e) =>
            e.type == ParseEventType.propertyStart && e.propertyPath == 'name',
      );
      final nameCompleteEvents = events.where(
        (e) =>
            e.type == ParseEventType.propertyComplete &&
            e.propertyPath == 'name',
      );

      expect(nameStartEvents.length, greaterThanOrEqualTo(1));
      expect(nameCompleteEvents.length, greaterThanOrEqualTo(1));
    });

    test('Parser emits stringChunk events', () async {
      final events = <ParseEvent>[];
      final controller = StreamController<String>();
      final parser = JsonStreamParser(
        controller.stream,
        onLog: (event) => events.add(event),
      );

      parser.getStringProperty('text');

      // Send string in chunks
      controller.add('{"text": "Hel');
      await Future.delayed(Duration(milliseconds: 10));
      controller.add('lo World"}');
      await Future.delayed(Duration(milliseconds: 20));

      await controller.close();
      await parser.dispose();

      final chunkEvents = events.where(
        (e) => e.type == ParseEventType.stringChunk && e.propertyPath == 'text',
      );

      expect(chunkEvents.length, greaterThanOrEqualTo(1));
    });

    test('Parser emits listElementStart events', () async {
      final events = <ParseEvent>[];
      final controller = StreamController<String>();
      final parser = JsonStreamParser(
        controller.stream,
        onLog: (event) => events.add(event),
      );

      parser.getListProperty('items');

      controller.add('{"items": [1, 2, 3]}');
      await Future.delayed(Duration(milliseconds: 20));

      await controller.close();
      await parser.dispose();

      final elementEvents = events.where(
        (e) => e.type == ParseEventType.listElementStart,
      );

      expect(elementEvents.length, greaterThanOrEqualTo(3)); // 3 elements
    });

    test('Parser emits mapKeyDiscovered events', () async {
      final events = <ParseEvent>[];
      final controller = StreamController<String>();
      final parser = JsonStreamParser(
        controller.stream,
        onLog: (event) => events.add(event),
      );

      parser.getMapProperty('user');

      controller.add('{"user": {"name": "Alice", "age": 30}}');
      await Future.delayed(Duration(milliseconds: 20));

      await controller.close();
      await parser.dispose();

      final keyEvents = events.where(
        (e) =>
            e.type == ParseEventType.mapKeyDiscovered &&
            e.propertyPath == 'user',
      );

      expect(keyEvents.length, greaterThanOrEqualTo(2)); // name and age keys
    });

    test('Parser emits yapFiltered event when yap filter triggers', () async {
      final events = <ParseEvent>[];
      final controller = StreamController<String>();
      final parser = JsonStreamParser(
        controller.stream,
        onLog: (event) => events.add(event),
        closeOnRootComplete: true,
      );

      parser.getStringProperty('key');

      controller.add('{"key": "value"}');
      await Future.delayed(Duration(milliseconds: 20));

      // Send yap
      controller.add(' Extra text here!');
      await Future.delayed(Duration(milliseconds: 20));

      await controller.close();

      final yapEvents =
          events.where((e) => e.type == ParseEventType.yapFiltered);
      expect(yapEvents.length, 1);
    });

    test('Parser emits disposed event', () async {
      final events = <ParseEvent>[];
      final controller = StreamController<String>();
      final parser = JsonStreamParser(
        controller.stream,
        onLog: (event) => events.add(event),
      );

      await parser.dispose();

      final disposedEvents =
          events.where((e) => e.type == ParseEventType.disposed);
      expect(disposedEvents.length, 1);
    });
  });

  group('Observability - PropertyStream Logging', () {
    test('StringPropertyStream can set onLog callback', () async {
      final events = <ParseEvent>[];
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      final stringStream = parser.getStringProperty('message');
      stringStream.onLog((event) => events.add(event));

      controller.add('{"message": "Hello"}');
      await Future.delayed(Duration(milliseconds: 20));

      await controller.close();
      await parser.dispose();

      // Should receive events for this specific property
      expect(events.isNotEmpty, isTrue);
      expect(events.every((e) => e.propertyPath.startsWith('message')), isTrue);
    });

    test('MapPropertyStream can set onLog callback', () async {
      final events = <ParseEvent>[];
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      final mapStream = parser.getMapProperty('user');
      mapStream.onLog((event) => events.add(event));

      controller.add('{"user": {"name": "Alice"}}');
      await Future.delayed(Duration(milliseconds: 20));

      await controller.close();
      await parser.dispose();

      expect(events.isNotEmpty, isTrue);
    });

    test('ListPropertyStream can set onLog callback', () async {
      final events = <ParseEvent>[];
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      final listStream = parser.getListProperty('items');
      listStream.onLog((event) => events.add(event));

      controller.add('{"items": [1, 2, 3]}');
      await Future.delayed(Duration(milliseconds: 20));

      await controller.close();
      await parser.dispose();

      expect(events.isNotEmpty, isTrue);
    });

    test('Nested property logs are scoped to subtree', () async {
      final rootEvents = <ParseEvent>[];
      final userEvents = <ParseEvent>[];
      final controller = StreamController<String>();
      final parser = JsonStreamParser(
        controller.stream,
        onLog: (event) => rootEvents.add(event),
      );

      final userStream = parser.getMapProperty('user');
      userStream.onLog((event) => userEvents.add(event));

      controller.add('{"title": "Test", "user": {"name": "Alice"}}');
      await Future.delayed(Duration(milliseconds: 20));

      await controller.close();
      await parser.dispose();

      // Root should get all events
      expect(rootEvents.any((e) => e.propertyPath == 'title'), isTrue);
      expect(rootEvents.any((e) => e.propertyPath.startsWith('user')), isTrue);

      // User events should only be for user subtree
      expect(
          userEvents.every((e) =>
              e.propertyPath == 'user' || e.propertyPath.startsWith('user.')),
          isTrue);
    });

    test('onLog can be set via named parameter in constructor access',
        () async {
      final events = <ParseEvent>[];
      final controller = StreamController<String>();

      // This tests the pattern where onLog is passed when getting the property
      final parser = JsonStreamParser(controller.stream);
      final stream = parser.getStringProperty('name');

      // Set via method
      stream.onLog((event) => events.add(event));

      controller.add('{"name": "Test"}');
      await Future.delayed(Duration(milliseconds: 20));

      await controller.close();
      await parser.dispose();

      expect(events.isNotEmpty, isTrue);
    });
  });

  group('Observability - Error Logging', () {
    test('Parser emits error event on type mismatch', () async {
      final events = <ParseEvent>[];
      final controller = StreamController<String>();

      // Run in a guarded zone to catch any escaped exceptions
      await runZonedGuarded(() async {
        final parser = JsonStreamParser(
          controller.stream,
          onLog: (event) => events.add(event),
        );

        // Request a string property
        final stringStream = parser.getStringProperty('value');

        // But send a number
        controller.add('{"value": 42}');
        await Future.delayed(Duration(milliseconds: 20));

        try {
          await stringStream.future;
        } catch (_) {
          // Expected error
        }

        await controller.close();
        await parser.dispose();
      }, (error, stack) {
        // Ignore zone errors - they're expected for type mismatches
      });

      final errorEvents = events.where((e) => e.type == ParseEventType.error);
      expect(errorEvents.length, greaterThanOrEqualTo(1));
    });
  });
}
