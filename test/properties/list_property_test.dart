import 'dart:async';

import 'package:llm_json_stream/classes/json_stream_parser.dart';
import 'package:llm_json_stream/classes/property_stream.dart';
import 'package:test/test.dart';
import 'package:llm_json_stream/utilities/stream_text_in_chunks.dart';

/// Enable verbose logging to debug test execution
const bool verbose = true;

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

      final firstMap = parser.getMapProperty("items[0]");
      final secondMap = parser.getMapProperty("items[1]");

      final firstName = await firstNameStream.future.withTestTimeout();
      final firstPrice = await firstPriceStream.future.withTestTimeout();
      final secondName = await secondNameStream.future.withTestTimeout();
      final secondPrice = await secondPriceStream.future.withTestTimeout();

      final firstMapValue = await firstMap.future.withTestTimeout();
      final secondMapValue = await secondMap.future.withTestTimeout();

      if (true) {
        print('[FINAL] items[0].name: $firstName');
        print('[FINAL] items[0].price: $firstPrice');
        print('[FINAL] items[1].name: $secondName');
        print('[FINAL] items[1].price: $secondPrice');
        print('[FINAL] items[0] map: $firstMapValue');
        print('[FINAL] items[1] map: $secondMapValue');
      }

      expect(firstName, equals('Item1'));
      expect(firstPrice, equals(10));
      expect(secondName, equals('Item2'));
      expect(secondPrice, equals(20));
      expect(firstMapValue, equals({'name': 'Item1', 'price': 10}));
      expect(secondMapValue, equals({'name': 'Item2', 'price': 20}));
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
        if (verbose) {
          print('[ELEMENT] [$index]: $element (type: ${element.runtimeType})');
        }
        final value = await (element as StringPropertyStream).future;
        if (verbose) {
          print('[ELEMENT VALUE] [$index]: $value');
        }
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

  group('Nested List onElement Callbacks', () {
    test('onElement can be set via getListProperty on MapPropertyStream',
        () async {
      final json = '''
      {
        "user": {
          "items": [
            {"id": 1, "name": "Item 1"},
            {"id": 2, "name": "Item 2"}
          ]
        }
      }
      ''';

      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      final userMap = parser.getMapProperty('user');

      final callbackResults = <int>[];

      final itemsList = userMap.getListProperty(
        'items',
        onElement: (element, index) {
          callbackResults.add(index);
        },
      );

      // Stream the JSON
      controller.add(json);
      await controller.close();

      // Wait for the list to complete
      await itemsList.future;

      // Verify callbacks were called
      expect(callbackResults, equals([0, 1]));
    });

    test('onElement can be set via getListProperty on ListPropertyStream',
        () async {
      final json = '''
      {
        "matrix": [
          [1, 2, 3],
          [4, 5, 6],
          [7, 8, 9]
        ]
      }
      ''';

      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      final matrixList = parser.getListProperty('matrix');

      final firstRowCallbacks = <int>[];

      // Get the first row and set onElement callback on it
      final firstRow = matrixList.getListProperty(
        '[0]',
        onElement: (element, index) {
          firstRowCallbacks.add(index);
        },
      );

      // Stream the JSON
      controller.add(json);
      await controller.close();

      // Wait for the first row to complete
      await firstRow.future;

      // Verify callbacks were called for the first row
      expect(firstRowCallbacks, equals([0, 1, 2]));
    });

    test('onElement callback receives correct property stream type', () async {
      final json = '''
      {
        "data": {
          "users": [
            {"name": "Alice", "age": 30},
            {"name": "Bob", "age": 25}
          ]
        }
      }
      ''';

      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      final dataMap = parser.getMapProperty('data');

      final names = <String>[];

      dataMap.getListProperty(
        'users',
        onElement: (element, index) {
          if (element is MapPropertyStream) {
            element.getStringProperty('name').future.then((name) {
              names.add(name);
            });
          }
        },
      );

      // Stream the JSON
      controller.add(json);
      await controller.close();

      // Wait a bit for async callbacks to complete
      await Future.delayed(Duration(milliseconds: 50));

      // Verify we got the names
      expect(names, containsAll(['Alice', 'Bob']));
    });

    test('List onElement - Object Futures', () async {
      final json =
          '{"products": [{"id": 1, "name": "Widget"}, {"id": 2, "name": "Gadget"}]}';
      final stream = streamTextInChunks(
          text: json, chunkSize: 5, interval: Duration(milliseconds: 100));
      final parser = JsonStreamParser(stream);

      final List<Future<Map<String, dynamic>>> itemFutures = [];

      final listProperty = parser.getListProperty(
        "products",
        onElement: (propertyStream, index) async {
          if (verbose)
            print(
                '[CALLBACK] onElement called for index $index, stream: ${propertyStream.runtimeType}');
          final mapPropertyStream = propertyStream as MapPropertyStream;
          final future = mapPropertyStream.future.then((value) {
            if (verbose)
              print('[CALLBACK] Future resolved for index $index: $value');
            return value as Map<String, dynamic>;
          });
          itemFutures.add(future);
        },
      );

      // Wait for the list to complete
      final list = await listProperty.future.withTestTimeout();

      if (verbose) {
        print('[TEST] List completed: $list');
        print('[TEST] Number of item futures: ${itemFutures.length}');
      }

      // Verify we have 2 items
      expect(itemFutures.length, equals(2));

      // Wait for each future and verify contents
      final item1 = await itemFutures[0].withTestTimeout();
      final item2 = await itemFutures[1].withTestTimeout();

      if (verbose) {
        print('[FINAL] item1: $item1');
        print('[FINAL] item2: $item2');
      }

      expect(item1, isA<Map<String, dynamic>>());
      expect(item2, isA<Map<String, dynamic>>());
      expect(item1, {'id': 1, 'name': 'Widget'});
      expect(item2, {'id': 2, 'name': 'Gadget'});
      expect(item1['id'], equals(1));
      expect(item1['name'], equals('Widget'));
      expect(item2['id'], equals(2));
      expect(item2['name'], equals('Gadget'));
    });

    test('List onElement - Object Futures (Flutter App Scenario)', () async {
      // This test mimics exactly what happens in the Flutter app
      final json =
          '{"products": [{"id": 1, "name": "Widget"}, {"id": 2, "name": "Gadget"}]}';
      
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      final List<Future<Map<String, dynamic>>> itemFutures = [];

      // The Flutter app calls getListProperty in initState WITHOUT awaiting
      parser.getListProperty(
        "products",
        onElement: (propertyStream, index) async {
          if (verbose) print('[CALLBACK] onElement called for index $index');
          final mapPropertyStream = propertyStream as MapPropertyStream;
          // The Flutter app immediately adds the future to the list
          final future = mapPropertyStream.future.then((value) {
            if (verbose) print('[CALLBACK] Future $index resolved: $value');
            return value as Map<String, dynamic>;
          });
          itemFutures.add(future);
        },
      );

      // Now simulate the Flutter app's streaming behavior
      if (verbose) print('[TEST] Starting to stream JSON...');
      
      // Stream the JSON in chunks (simulating the Flutter app)
      final chunks = <String>[];
      for (var i = 0; i < json.length; i += 5) {
        chunks.add(json.substring(i, i + 5 > json.length ? json.length : i + 5));
      }
      
      for (final chunk in chunks) {
        controller.add(chunk);
        await Future.delayed(Duration(milliseconds: 100));
      }
      
      if (verbose) print('[TEST] Closing controller...');
      await controller.close();
      
      if (verbose) print('[TEST] Number of futures: ${itemFutures.length}');

      // Now let's try to access them - this should work eventually
      // because FutureBuilder waits for the future
      expect(itemFutures.length, equals(2));
      
      if (verbose) print('[TEST] Waiting for first future...');
      final item1 = await itemFutures[0].timeout(
        Duration(seconds: 2),
        onTimeout: () {
          if (verbose) print('[ERROR] First future timed out!');
          return <String, dynamic>{};
        },
      );
      if (verbose) print('[TEST] First item: $item1');
      
      if (verbose) print('[TEST] Waiting for second future...');
      final item2 = await itemFutures[1].timeout(
        Duration(seconds: 2),
        onTimeout: () {
          if (verbose) print('[ERROR] Second future timed out!');
          return <String, dynamic>{};
        },
      );
      if (verbose) print('[TEST] Second item: $item2');
      
      expect(item1.isNotEmpty, isTrue, reason: 'First item should not be empty');
      expect(item2.isNotEmpty, isTrue, reason: 'Second item should not be empty');
      expect(item1, {'id': 1, 'name': 'Widget'});
      expect(item2, {'id': 2, 'name': 'Gadget'});
    });

    test('List onElement - Premature Future Access Bug', () async {
      // This test checks if accessing map.future immediately returns empty map
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      MapPropertyStream? capturedStream;

      parser.getListProperty(
        "products",
        onElement: (propertyStream, index) async {
          if (verbose) print('[CALLBACK] onElement called, capturing stream');
          capturedStream = propertyStream as MapPropertyStream;
        },
      );

      // Start streaming just the opening parts
      controller.add('{"products": [');
      await Future.delayed(Duration(milliseconds: 50));
      controller.add('{"');
      await Future.delayed(Duration(milliseconds: 50));
      
      // At this point, onElement should have been called
      expect(capturedStream, isNotNull, reason: 'Stream should be captured');
      
      if (verbose) print('[TEST] Checking if future resolves immediately to empty map...');
      
      // Try to get the future - it should NOT resolve yet
      final mapFuture = capturedStream!.future;
      var resolved = false;
      var resultMap = <String, dynamic>{};
      
      // Race the future against a timeout
      await Future.any([
        mapFuture.then((value) {
          resolved = true;
          resultMap = value as Map<String, dynamic>;
          if (verbose) print('[TEST] Future resolved early with: $resultMap');
        }),
        Future.delayed(Duration(milliseconds: 200)).then((_) {
          if (verbose) print('[TEST] Future did not resolve early (good!)');
        }),
      ]);
      
      expect(resolved, isFalse, reason: 'Map future should not resolve before map is complete');
      
      // Now complete the stream
      controller.add('id": 1, "name": "Widget"}]}');
      await controller.close();
      
      // Now the future should resolve
      final finalMap = await mapFuture.timeout(Duration(seconds: 1));
      if (verbose) print('[TEST] Final map: $finalMap');
      
      expect(finalMap, {'id': 1, 'name': 'Widget'});
    });

    test('List onElement - EXACT Flutter Bug Reproduction', () async {
      // This reproduces the EXACT issue in the Flutter app
      final json =
          '{"products": [{"id": 1, "name": "Widget"}, {"id": 2, "name": "Gadget"}]}';
      
      final controller = StreamController<String>.broadcast();
      final parser = JsonStreamParser(controller.stream);

      final List<Map<String, dynamic>> items = [];

      // This is EXACTLY what the Flutter app does
      parser.getListProperty(
        "products",
        onElement: (propertyStream, index) {
          if (verbose) print('[CALLBACK] onElement called for index $index');
          final mapPropertyStream = propertyStream as MapPropertyStream;
          
          // The Flutter app calls .then() immediately
          mapPropertyStream.future.then((map) {
            if (verbose) print('[THEN] Map resolved for index $index: $map');
            items.add(map as Map<String, dynamic>);
          });
        },
      );

      if (verbose) print('[TEST] Starting to stream JSON...');
      
      // Stream the JSON
      final chunks = <String>[];
      for (var i = 0; i < json.length; i += 5) {
        chunks.add(json.substring(i, i + 5 > json.length ? json.length : i + 5));
      }
      
      for (final chunk in chunks) {
        controller.add(chunk);
        await Future.delayed(Duration(milliseconds: 10));
      }
      
      if (verbose) print('[TEST] Closing controller...');
      await controller.close();
      
      // Wait for the .then() callbacks to fire
      await Future.delayed(Duration(milliseconds: 200));
      
      if (verbose) print('[TEST] Number of items: ${items.length}');
      for (var i = 0; i < items.length; i++) {
        if (verbose) print('[TEST] Item $i: ${items[i]} (isEmpty: ${items[i].isEmpty})');
      }
      
      // This is where the bug should show up
      expect(items.length, equals(2), reason: 'Should have 2 items');
      expect(items[0].isEmpty, isFalse, reason: 'First item should NOT be empty');
      expect(items[1].isEmpty, isFalse, reason: 'Second item should NOT be empty');
      expect(items[0], {'id': 1, 'name': 'Widget'});
      expect(items[1], {'id': 2, 'name': 'Gadget'});
    });

    test('List onElement - Flutter Timing Bug (Parser before Callback)', () async {
      // Test if creating parser and THEN setting up callback causes issues
      final json =
          '{"products": [{"id": 1, "name": "Widget"}, {"id": 2, "name": "Gadget"}]}';
      
      final controller = StreamController<String>.broadcast();
      
      // Create parser FIRST (Flutter app does this)
      final parser = JsonStreamParser(controller.stream);
      
      if (verbose) print('[TEST] Parser created, waiting before setting up callback...');
      
      // Small delay to simulate setState() rebuild timing
      await Future.delayed(Duration(milliseconds: 10));
      
      final List<Map<String, dynamic>> items = [];

      // NOW set up the callback (simulating child widget initState after parent setState)
      parser.getListProperty(
        "products",
        onElement: (propertyStream, index) {
          if (verbose) print('[CALLBACK] onElement called for index $index');
          final mapPropertyStream = propertyStream as MapPropertyStream;
          
          mapPropertyStream.future.then((map) {
            if (verbose) print('[THEN] Map resolved for index $index: $map');
            items.add(map as Map<String, dynamic>);
          });
        },
      );

      if (verbose) print('[TEST] Starting to stream JSON...');
      
      // NOW start streaming (Flutter app does this after setState)
      final chunks = <String>[];
      for (var i = 0; i < json.length; i += 5) {
        chunks.add(json.substring(i, i + 5 > json.length ? json.length : i + 5));
      }
      
      for (final chunk in chunks) {
        controller.add(chunk);
        await Future.delayed(Duration(milliseconds: 10));
      }
      
      if (verbose) print('[TEST] Closing controller...');
      await controller.close();
      
      // Wait for the .then() callbacks to fire
      await Future.delayed(Duration(milliseconds: 200));
      
      if (verbose) print('[TEST] Number of items: ${items.length}');
      for (var i = 0; i < items.length; i++) {
        if (verbose) print('[TEST] Item $i: ${items[i]} (isEmpty: ${items[i].isEmpty})');
      }
      
      expect(items.length, equals(2), reason: 'Should have 2 items');
      expect(items[0].isEmpty, isFalse, reason: 'First item should NOT be empty');
      expect(items[1].isEmpty, isFalse, reason: 'Second item should NOT be empty');
      expect(items[0], {'id': 1, 'name': 'Widget'});
      expect(items[1], {'id': 2, 'name': 'Gadget'});
    });

    test('List onElement - Early Stream Close Bug', () async {
      // Test if closing stream too early causes empty maps
      final json =
          '{"products": [{"id": 1, "name": "Widget"}, {"id": 2, "name": "Gadget"}]}';
      
      final controller = StreamController<String>.broadcast();
      final parser = JsonStreamParser(controller.stream);

      final List<Map<String, dynamic>> items = [];

      parser.getListProperty(
        "products",
        onElement: (propertyStream, index) {
          if (verbose) print('[CALLBACK] onElement called for index $index');
          final mapPropertyStream = propertyStream as MapPropertyStream;
          
          mapPropertyStream.future.then((map) {
            if (verbose) print('[THEN] Map resolved for index $index: $map (isEmpty: ${(map as Map).isEmpty})');
            items.add(map as Map<String, dynamic>);
          });
        },
      );

      if (verbose) print('[TEST] Streaming JSON ALL AT ONCE...');
      
      // Add all JSON at once
      controller.add(json);
      
      if (verbose) print('[TEST] Closing controller IMMEDIATELY...');
      // Close immediately without waiting
      await controller.close();
      
      if (verbose) print('[TEST] Waiting for callbacks...');
      // Wait for the .then() callbacks to fire
      await Future.delayed(Duration(milliseconds: 500));
      
      if (verbose) print('[TEST] Number of items: ${items.length}');
      for (var i = 0; i < items.length; i++) {
        if (verbose) print('[TEST] Item $i: ${items[i]} (isEmpty: ${items[i].isEmpty})');
      }
      
      expect(items.length, equals(2), reason: 'Should have 2 items');
      
      if (items[0].isEmpty) {
        if (verbose) print('[BUG REPRODUCED!] First item is empty!');
      }
      if (items[1].isEmpty) {
        if (verbose) print('[BUG REPRODUCED!] Second item is empty!');
      }
      
      expect(items[0].isEmpty, isFalse, reason: 'First item should NOT be empty');
      expect(items[1].isEmpty, isFalse, reason: 'Second item should NOT be empty');
      expect(items[0], {'id': 1, 'name': 'Widget'});
      expect(items[1], {'id': 2, 'name': 'Gadget'});
    });

    test('List onElement - EXACT FLUTTER SCENARIO - Maps Resolve Immediately', () async {
      // This test EXACTLY mimics what the other Copilot's test shows
      final json = '{"products": [{"id": 1, "name": "Widget"}, {"id": 2, "name": "Gadget"}]}';
      
      final controller = StreamController<String>.broadcast();
      final parser = JsonStreamParser(controller.stream);

      final List<Map<String, dynamic>> items = [];

      // Set up the callback FIRST (before streaming)
      parser.getListProperty(
        "products",
        onElement: (propertyStream, index) {
          if (verbose) print('[onElement] Called for index $index');
          final mapPropertyStream = propertyStream as MapPropertyStream;
          
          // This is what the Flutter app does - call .then() immediately
          mapPropertyStream.future.then((map) {
            if (verbose) print('[.then()] Map resolved for index $index: $map (isEmpty: ${(map as Map).isEmpty})');
            items.add(map as Map<String, dynamic>);
          });
          
          if (verbose) print('[onElement] Returned (callback registered)');
        },
      );

      if (verbose) print('[TEST] Streaming entire JSON at once...');
      // Stream the entire JSON at once like the other Copilot's test
      controller.add(json);
      
      if (verbose) print('[TEST] Closing stream...');
      await controller.close();
      
      if (verbose) print('[TEST] Waiting 500ms for callbacks...');
      await Future.delayed(Duration(milliseconds: 500));
      
      if (verbose) print('[TEST] Number of items: ${items.length}');
      for (var i = 0; i < items.length; i++) {
        if (verbose) print('[TEST] Item $i: ${items[i]} (isEmpty: ${items[i].isEmpty})');
      }
      
      // If this fails, the bug is in the PARSER
      expect(items.length, equals(2), reason: 'Should have 2 items');
      expect(items[0].isEmpty, isFalse, reason: 'First map should NOT be empty - THIS IS THE BUG');
      expect(items[1].isEmpty, isFalse, reason: 'Second map should NOT be empty - THIS IS THE BUG');
    });

    test('List onElement - AWAIT in onElement callback', () async {
      // Test if AWAITING in the callback makes a difference
      final json = '{"products": [{"id": 1, "name": "Widget"}, {"id": 2, "name": "Gadget"}]}';
      
      final controller = StreamController<String>.broadcast();
      final parser = JsonStreamParser(controller.stream);

      final List<Map<String, dynamic>> items = [];

      parser.getListProperty(
        "products",
        onElement: (propertyStream, index) async {
          if (verbose) print('[onElement] Called for index $index');
          final mapPropertyStream = propertyStream as MapPropertyStream;
          
          // Try AWAITING instead of .then()
          if (verbose) print('[onElement] About to await future for index $index...');
          final map = await mapPropertyStream.future;
          if (verbose) print('[onElement] Got map for index $index: $map (isEmpty: ${map.isEmpty})');
          items.add(map as Map<String, dynamic>);
        },
      );

      if (verbose) print('[TEST] Streaming entire JSON at once...');
      controller.add(json);
      
      if (verbose) print('[TEST] Closing stream...');
      await controller.close();
      
      if (verbose) print('[TEST] Waiting 500ms...');
      await Future.delayed(Duration(milliseconds: 500));
      
      if (verbose) print('[TEST] Number of items: ${items.length}');
      for (var i = 0; i < items.length; i++) {
        if (verbose) print('[TEST] Item $i: ${items[i]} (isEmpty: ${items[i].isEmpty})');
      }
      
      expect(items.length, equals(2));
      expect(items[0].isEmpty, isFalse, reason: 'Maps should not be empty with await');
      expect(items[1].isEmpty, isFalse);
    });

    test('List onElement - Broadcast Stream (Flutter App Uses This)', () async {
      // The Flutter app uses StreamController<String>.broadcast()
      final json =
          '{"products": [{"id": 1, "name": "Widget"}, {"id": 2, "name": "Gadget"}]}';
      
      final controller = StreamController<String>.broadcast();
      final parser = JsonStreamParser(controller.stream);

      final List<Future<Map<String, dynamic>>> itemFutures = [];

      parser.getListProperty(
        "products",
        onElement: (propertyStream, index) async {
          if (verbose) print('[CALLBACK] onElement called for index $index');
          final mapPropertyStream = propertyStream as MapPropertyStream;
          final future = mapPropertyStream.future.then((value) {
            if (verbose) print('[CALLBACK] Future $index resolved: $value');
            return value as Map<String, dynamic>;
          });
          itemFutures.add(future);
        },
      );

      if (verbose) print('[TEST] Starting to stream JSON...');
      
      // Stream the JSON in chunks
      final chunks = <String>[];
      for (var i = 0; i < json.length; i += 5) {
        chunks.add(json.substring(i, i + 5 > json.length ? json.length : i + 5));
      }
      
      for (final chunk in chunks) {
        controller.add(chunk);
        await Future.delayed(Duration(milliseconds: 100));
      }
      
      if (verbose) print('[TEST] Closing controller...');
      await controller.close();
      
      if (verbose) print('[TEST] Number of futures: ${itemFutures.length}');

      expect(itemFutures.length, equals(2));
      
      if (verbose) print('[TEST] Waiting for futures...');
      final item1 = await itemFutures[0].timeout(Duration(seconds: 2));
      final item2 = await itemFutures[1].timeout(Duration(seconds: 2));
      
      if (verbose) {
        print('[TEST] First item: $item1');
        print('[TEST] Second item: $item2');
      }
      
      expect(item1, {'id': 1, 'name': 'Widget'});
      expect(item2, {'id': 2, 'name': 'Gadget'});
    });

    test('List onElement - Check for Empty Map Bug', () async {
      // This test checks if maps are completing with empty content
      final json =
          '{"products": [{"id": 1, "name": "Widget"}, {"id": 2, "name": "Gadget"}]}';
      
      final controller = StreamController<String>.broadcast();
      final parser = JsonStreamParser(controller.stream);

      final List<Map<String, dynamic>> resolvedMaps = [];

      parser.getListProperty(
        "products",
        onElement: (propertyStream, index) async {
          if (verbose) print('[CALLBACK] onElement called for index $index');
          final mapPropertyStream = propertyStream as MapPropertyStream;
          
          // Add a listener to track when and what the future resolves to
          mapPropertyStream.future.then((value) {
            final map = value as Map<String, dynamic>;
            if (verbose) print('[RESOLVED] Index $index resolved to: $map (isEmpty: ${map.isEmpty})');
            resolvedMaps.add(map);
            
            // Check if it's empty - this would be the bug!
            if (map.isEmpty) {
              if (verbose) print('[BUG FOUND!] Map $index is empty!');
            }
          });
        },
      );

      if (verbose) print('[TEST] Starting to stream JSON...');
      
      // Stream the entire JSON at once to rule out chunking issues
      controller.add(json);
      await Future.delayed(Duration(milliseconds: 100));
      
      if (verbose) print('[TEST] Closing controller...');
      await controller.close();
      
      // Wait a bit for futures to resolve
      await Future.delayed(Duration(milliseconds: 500));
      
      if (verbose) print('[TEST] Number of resolved maps: ${resolvedMaps.length}');
      
      expect(resolvedMaps.length, equals(2));
      expect(resolvedMaps[0].isEmpty, isFalse, reason: 'First map should not be empty');
      expect(resolvedMaps[1].isEmpty, isFalse, reason: 'Second map should not be empty');
      expect(resolvedMaps[0], {'id': 1, 'name': 'Widget'});
      expect(resolvedMaps[1], {'id': 2, 'name': 'Gadget'});
    });
  });
}
