import 'dart:async';

import 'package:json_stream_parser/classes/json_stream_parser.dart';
import 'package:json_stream_parser/classes/property_stream.dart';
import 'package:test/test.dart';
import 'package:json_stream_parser/utilities/stream_text_in_chunks.dart';

/// Enable verbose logging to debug test execution
const bool verbose = false;

/// Test timeout - fail if not done within this duration
const testTimeout = Duration(seconds: 5);

/// Helper to add timeout to futures
extension FutureTimeout<T> on Future<T> {
  Future<T> withTestTimeout() => timeout(
    testTimeout,
    onTimeout: () => throw TimeoutException(
      'Test timed out after ${testTimeout.inSeconds} seconds',
      testTimeout,
    ),
  );
}

void main() {
  group('List Property Tests', () {
    test('simple list - get entire list', () async {
      if (verbose) print('\n[TEST] Simple list');

      final json = '{"numbers":[1,2,3]}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 3,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final numbersStream = parser.getListProperty("numbers");
      final numbers = await numbersStream.future.withTestTimeout();

      if (verbose) print('[FINAL] $numbers');

      expect(numbers, isA<List>());
      expect(numbers, equals([1, 2, 3]));
      expect(numbers.length, equals(3));
    });

    test('list of strings', () async {
      if (verbose) print('\n[TEST] List of strings');

      final json = '{"names":["Alice","Bob","Charlie"]}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final namesStream = parser.getListProperty("names");
      final names = await namesStream.future.withTestTimeout();

      if (verbose) print('[FINAL] $names');

      expect(names, equals(['Alice', 'Bob', 'Charlie']));
    });

    test('array index access - simple', () async {
      if (verbose) print('\n[TEST] Array index access');

      final json = '{"items":["first","second","third"]}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 4,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final firstStream = parser.getStringProperty("items[0]");
      final secondStream = parser.getStringProperty("items[1]");
      final thirdStream = parser.getStringProperty("items[2]");

      final first = await firstStream.future.withTestTimeout();
      final second = await secondStream.future.withTestTimeout();
      final third = await thirdStream.future.withTestTimeout();

      if (verbose) {
        print('[FINAL] items[0]: $first');
        print('[FINAL] items[1]: $second');
        print('[FINAL] items[2]: $third');
      }

      expect(first, equals('first'));
      expect(second, equals('second'));
      expect(third, equals('third'));
    });

    test('array of objects - access nested property', () async {
      if (verbose) print('\n[TEST] Array of objects');

      final json =
          '{"items":[{"name":"Item1","price":10},{"name":"Item2","price":20}]}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 8,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final firstNameStream = parser.getStringProperty("items[0].name");
      final firstPriceStream = parser.getNumberProperty("items[0].price");
      final secondNameStream = parser.getStringProperty("items[1].name");
      final secondPriceStream = parser.getNumberProperty("items[1].price");

      final firstName = await firstNameStream.future.withTestTimeout();
      final firstPrice = await firstPriceStream.future.withTestTimeout();
      final secondName = await secondNameStream.future.withTestTimeout();
      final secondPrice = await secondPriceStream.future.withTestTimeout();

      if (verbose) {
        print('[FINAL] items[0].name: $firstName');
        print('[FINAL] items[0].price: $firstPrice');
        print('[FINAL] items[1].name: $secondName');
        print('[FINAL] items[1].price: $secondPrice');
      }

      expect(firstName, equals('Item1'));
      expect(firstPrice, equals(10));
      expect(secondName, equals('Item2'));
      expect(secondPrice, equals(20));
    });

    test('empty array', () async {
      if (verbose) print('\n[TEST] Empty array');

      final json = '{"empty":[]}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 3,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final emptyStream = parser.getListProperty("empty");
      final empty = await emptyStream.future.withTestTimeout();

      if (verbose) print('[FINAL] $empty');

      expect(empty, isA<List>());
      expect(empty.isEmpty, isTrue);
    });

    test('nested arrays', () async {
      if (verbose) print('\n[TEST] Nested arrays');

      final json = '{"matrix":[[1,2],[3,4],[5,6]]}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      // Access elements in nested arrays
      final val00Stream = parser.getNumberProperty("matrix[0][0]");
      final val01Stream = parser.getNumberProperty("matrix[0][1]");
      final val10Stream = parser.getNumberProperty("matrix[1][0]");
      final val11Stream = parser.getNumberProperty("matrix[1][1]");

      final val00 = await val00Stream.future.withTestTimeout();
      final val01 = await val01Stream.future.withTestTimeout();
      final val10 = await val10Stream.future.withTestTimeout();
      final val11 = await val11Stream.future.withTestTimeout();

      if (verbose) {
        print('[FINAL] matrix[0][0]: $val00');
        print('[FINAL] matrix[0][1]: $val01');
        print('[FINAL] matrix[1][0]: $val10');
        print('[FINAL] matrix[1][1]: $val11');
      }

      expect(val00, equals(1));
      expect(val01, equals(2));
      expect(val10, equals(3));
      expect(val11, equals(4));
    });

    test('mixed-type array', () async {
      if (verbose) print('\n[TEST] Mixed-type array');

      final json = '{"mixed":["text",42,true,null]}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 4,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final textStream = parser.getStringProperty("mixed[0]");
      final numStream = parser.getNumberProperty("mixed[1]");
      final boolStream = parser.getBooleanProperty("mixed[2]");
      final nullStream = parser.getNullProperty("mixed[3]");

      final text = await textStream.future.withTestTimeout();
      final numValue = await numStream.future.withTestTimeout();
      final boolValue = await boolStream.future.withTestTimeout();
      final nullVal = await nullStream.future.withTestTimeout();

      if (verbose) {
        print('[FINAL] mixed[0]: $text');
        print('[FINAL] mixed[1]: $numValue');
        print('[FINAL] mixed[2]: $boolValue');
        print('[FINAL] mixed[3]: $nullVal');
      }

      expect(text, equals('text'));
      expect(numValue, equals(42));
      expect(boolValue, equals(true));
      expect(nullVal, isNull);
    });

    test('chainable property access - get list then chain', () async {
      if (verbose) print('\n[TEST] Chainable list access');

      final json = '{"data":[10,20,30]}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 4,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      // Get list first
      final dataStream = parser.getListProperty("data");
      final data = await dataStream.future.withTestTimeout();

      if (verbose) print('[GOT LIST] data: $data');

      // Chain to access specific indices
      final firstStream = dataStream.getNumberProperty("[0]");
      final secondStream = dataStream.getNumberProperty("[1]");
      final thirdStream = dataStream.getNumberProperty("[2]");

      final first = await firstStream.future.withTestTimeout();
      final second = await secondStream.future.withTestTimeout();
      final third = await thirdStream.future.withTestTimeout();

      if (verbose) {
        print('[CHAINED] [0]: $first');
        print('[CHAINED] [1]: $second');
        print('[CHAINED] [2]: $third');
      }

      expect(first, equals(10));
      expect(second, equals(20));
      expect(third, equals(30));
    });

    test('list iteration with onElement', () async {
      if (verbose) print('\n[TEST] List iteration with onElement');

      final json = '{"colors":["red","green","blue"]}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final colorsStream = parser.getListProperty("colors");

      // Collect elements as they're emitted
      final elements = <String>[];
      colorsStream.onElement((element, index) async {
        if (verbose)
          print('[ELEMENT] [$index]: $element (type: ${element.runtimeType})');
        final value = await (element as StringPropertyStream).future;
        if (verbose) print('[ELEMENT VALUE] [$index]: $value');
        elements.add(value);
      });

      // Wait for list to complete
      await colorsStream.future.withTestTimeout();

      if (verbose) print('[ALL ELEMENTS] $elements');

      expect(elements, equals(['red', 'green', 'blue']));
    });

    test('deeply nested structure with lists and maps', () async {
      if (verbose) print('\n[TEST] Complex nested structure');

      final json =
          '{"users":[{"name":"Alice","tags":["admin","user"]},{"name":"Bob","tags":["user"]}]}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 10,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      // Access deeply nested properties
      final alice = parser.getStringProperty("users[0].name");
      final aliceTag1 = parser.getStringProperty("users[0].tags[0]");
      final aliceTag2 = parser.getStringProperty("users[0].tags[1]");
      final bob = parser.getStringProperty("users[1].name");
      final bobTag1 = parser.getStringProperty("users[1].tags[0]");

      expect(await alice.future, equals('Alice'));
      expect(await aliceTag1.future, equals('admin'));
      expect(await aliceTag2.future, equals('user'));
      expect(await bob.future, equals('Bob'));
      expect(await bobTag1.future, equals('user'));

      if (verbose) print('[FINAL] All nested properties verified');
    });

    test('list with whitespace', () async {
      if (verbose) print('\n[TEST] List with whitespace');

      final json = '{ "values" : [ 1 , 2 , 3 ] }';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 4,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final valuesStream = parser.getListProperty("values");
      final values = await valuesStream.future.withTestTimeout();

      if (verbose) print('[FINAL] $values');

      expect(values, equals([1, 2, 3]));
    });

    test('single element array', () async {
      if (verbose) print('\n[TEST] Single element array');

      final json = '{"single":[42]}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 3,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final singleStream = parser.getListProperty("single");
      final single = await singleStream.future.withTestTimeout();

      if (verbose) print('[FINAL] $single');

      expect(single, equals([42]));
      expect(single.length, equals(1));
    });
  });
}
