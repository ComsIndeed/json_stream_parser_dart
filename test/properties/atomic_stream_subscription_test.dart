import 'dart:async';

import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:test/test.dart';

void main() {
  group('Atomic Stream Subscriptions', () {
    test('Boolean stream can be subscribed to and emits value', () async {
      final streamController = StreamController<String>();
      final parser = JsonStreamParser(streamController.stream);
      final boolStream = parser.getBooleanProperty('isActive');

      // Subscribe to the boolean stream
      final emittedValues = <bool>[];
      bool streamClosed = false;

      boolStream.stream.listen(
        (value) {
          print('Boolean emitted: $value');
          emittedValues.add(value);
        },
        onDone: () {
          print('Boolean stream closed');
          streamClosed = true;
        },
      );

      // Send JSON with boolean value
      streamController.add('{"isActive":true}');
      await Future.delayed(Duration(milliseconds: 10));
      streamController.close();
      await Future.delayed(Duration(milliseconds: 10));

      // Verify the stream emitted the value and closed
      expect(emittedValues.length, 1,
          reason: 'Boolean stream should emit exactly once');
      expect(emittedValues[0], true,
          reason: 'Boolean stream should emit true');
      expect(streamClosed, true,
          reason: 'Boolean stream should close after emitting');

      // Also verify the future works
      final boolValue = await boolStream.future;
      expect(boolValue, true);
    });

    test('Number stream can be subscribed to and emits value', () async {
      final streamController = StreamController<String>();
      final parser = JsonStreamParser(streamController.stream);
      final numberStream = parser.getNumberProperty('count');

      // Subscribe to the number stream
      final emittedValues = <num>[];
      bool streamClosed = false;

      numberStream.stream.listen(
        (value) {
          print('Number emitted: $value');
          emittedValues.add(value);
        },
        onDone: () {
          print('Number stream closed');
          streamClosed = true;
        },
      );

      // Send JSON with number value
      streamController.add('{"count":42}');
      await Future.delayed(Duration(milliseconds: 10));
      streamController.close();
      await Future.delayed(Duration(milliseconds: 10));

      // Verify the stream emitted the value and closed
      expect(emittedValues.length, 1,
          reason: 'Number stream should emit exactly once');
      expect(emittedValues[0], 42, reason: 'Number stream should emit 42');
      expect(streamClosed, true,
          reason: 'Number stream should close after emitting');

      // Also verify the future works
      final numberValue = await numberStream.future;
      expect(numberValue, 42);
    });

    test('Null stream can be subscribed to and emits value', () async {
      final streamController = StreamController<String>();
      final parser = JsonStreamParser(streamController.stream);
      final nullStream = parser.getNullProperty('data');

      // Subscribe to the null stream
      final emittedValues = <Object?>[];
      bool streamClosed = false;

      nullStream.stream.listen(
        (value) {
          print('Null emitted: $value');
          emittedValues.add(value);
        },
        onDone: () {
          print('Null stream closed');
          streamClosed = true;
        },
      );

      // Send JSON with null value
      streamController.add('{"data":null}');
      await Future.delayed(Duration(milliseconds: 10));
      streamController.close();
      await Future.delayed(Duration(milliseconds: 10));

      // Verify the stream emitted the value and closed
      expect(emittedValues.length, 1,
          reason: 'Null stream should emit exactly once');
      expect(emittedValues[0], null, reason: 'Null stream should emit null');
      expect(streamClosed, true,
          reason: 'Null stream should close after emitting');

      // Also verify the future works
      final nullValue = await nullStream.future;
      expect(nullValue, null);
    });

    test('Multiple atomic streams can be subscribed to simultaneously',
        () async {
      final streamController = StreamController<String>();
      final parser = JsonStreamParser(streamController.stream);

      final boolStream = parser.getBooleanProperty('active');
      final numberStream = parser.getNumberProperty('count');
      final nullStream = parser.getNullProperty('data');

      // Subscribe to all streams
      final boolValues = <bool>[];
      final numberValues = <num>[];
      final nullValues = <Object?>[];

      boolStream.stream.listen((value) {
        print('Bool emitted: $value');
        boolValues.add(value);
      });

      numberStream.stream.listen((value) {
        print('Number emitted: $value');
        numberValues.add(value);
      });

      nullStream.stream.listen((value) {
        print('Null emitted: $value');
        nullValues.add(value);
      });

      // Send JSON with all three types
      streamController.add('{"active":false,"count":99,"data":null}');
      await Future.delayed(Duration(milliseconds: 10));
      streamController.close();
      await Future.delayed(Duration(milliseconds: 10));

      // Verify all streams emitted their values
      expect(boolValues, [false],
          reason: 'Boolean stream should emit false');
      expect(numberValues, [99], reason: 'Number stream should emit 99');
      expect(nullValues, [null], reason: 'Null stream should emit null');
    });

    test('Atomic streams in nested objects work correctly', () async {
      final streamController = StreamController<String>();
      final parser = JsonStreamParser(streamController.stream);

      final nestedBool = parser.getBooleanProperty('config.enabled');
      final nestedNumber = parser.getNumberProperty('config.timeout');

      final boolValues = <bool>[];
      final numberValues = <num>[];

      nestedBool.stream.listen((value) {
        print('Nested bool emitted: $value');
        boolValues.add(value);
      });

      nestedNumber.stream.listen((value) {
        print('Nested number emitted: $value');
        numberValues.add(value);
      });

      // Send JSON with nested values
      streamController.add('{"config":{"enabled":true,"timeout":30}}');
      await Future.delayed(Duration(milliseconds: 10));
      streamController.close();
      await Future.delayed(Duration(milliseconds: 10));

      // Verify nested streams emitted their values
      expect(boolValues, [true],
          reason: 'Nested boolean stream should emit true');
      expect(numberValues, [30],
          reason: 'Nested number stream should emit 30');
    });

    test('Atomic streams in arrays work correctly', () async {
      final streamController = StreamController<String>();
      final parser = JsonStreamParser(streamController.stream);

      final firstBool = parser.getBooleanProperty('flags[0]');
      final secondBool = parser.getBooleanProperty('flags[1]');
      final firstNumber = parser.getNumberProperty('numbers[0]');

      final firstBoolValues = <bool>[];
      final secondBoolValues = <bool>[];
      final numberValues = <num>[];

      firstBool.stream.listen((value) {
        print('First bool emitted: $value');
        firstBoolValues.add(value);
      });

      secondBool.stream.listen((value) {
        print('Second bool emitted: $value');
        secondBoolValues.add(value);
      });

      firstNumber.stream.listen((value) {
        print('Number emitted: $value');
        numberValues.add(value);
      });

      // Send JSON with arrays
      streamController.add('{"flags":[true,false],"numbers":[123,456]}');
      await Future.delayed(Duration(milliseconds: 10));
      streamController.close();
      await Future.delayed(Duration(milliseconds: 10));

      // Verify array element streams emitted their values
      expect(firstBoolValues, [true],
          reason: 'First boolean should emit true');
      expect(secondBoolValues, [false],
          reason: 'Second boolean should emit false');
      expect(numberValues, [123], reason: 'First number should emit 123');
    });

    test('Atomic stream with chunked JSON delivery', () async {
      final streamController = StreamController<String>();
      final parser = JsonStreamParser(streamController.stream);

      final numberStream = parser.getNumberProperty('value');
      final emittedValues = <num>[];

      numberStream.stream.listen((value) {
        print('Number emitted: $value');
        emittedValues.add(value);
      });

      // Send JSON in chunks to test that it still works
      streamController.add('{"val');
      await Future.delayed(Duration(milliseconds: 10));
      streamController.add('ue":1');
      await Future.delayed(Duration(milliseconds: 10));
      streamController.add('23}');
      await Future.delayed(Duration(milliseconds: 10));
      streamController.close();
      await Future.delayed(Duration(milliseconds: 10));

      // Verify the stream emitted the complete value
      expect(emittedValues.length, 1,
          reason: 'Number stream should emit exactly once');
      expect(emittedValues[0], 123,
          reason: 'Number stream should emit complete value 123');
    });
  });
}


