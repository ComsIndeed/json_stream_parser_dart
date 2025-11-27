import 'dart:async';

import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:test/test.dart';

/// Comprehensive tests for getting full values of maps and lists
/// Tests various chunk sizes, intervals, and nesting levels

const bool verbose = false;
const testTimeout = Duration(seconds: 10);

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
  // Different chunk sizes to test
  final chunkSizes = [1, 3, 5, 10, 20, 50];

  // Different intervals to test
  final intervals = [
    Duration.zero,
    Duration(milliseconds: 1),
    Duration(milliseconds: 10),
    Duration(milliseconds: 50),
    Duration(milliseconds: 100),
    Duration(milliseconds: 200),
  ];

  group('Simple Map Retrieval - Various Configurations', () {
    for (final chunkSize in chunkSizes) {
      for (final interval in intervals) {
        test(
            'simple map - chunk=$chunkSize, interval=${interval.inMilliseconds}ms',
            () async {
          final json = '{"name":"Alice","age":30,"active":true}';

          final stream = streamTextInChunks(
            text: json,
            chunkSize: chunkSize,
            interval: interval,
          );
          final parser = JsonStreamParser(stream);

          final mapStream = parser.getMapProperty("");
          final map = await mapStream.future.withTestTimeout();

          if (verbose) print('[RESULT] $map');

          expect(map, isA<Map>());
          expect(map['name'], equals('Alice'));
          expect(map['age'], equals(30));
          expect(map['active'], equals(true));
          expect(map.length, equals(3));
        });
      }
    }
  });

  group('Simple List Retrieval - Various Configurations', () {
    for (final chunkSize in chunkSizes) {
      for (final interval in intervals) {
        test(
            'simple list - chunk=$chunkSize, interval=${interval.inMilliseconds}ms',
            () async {
          final json = '{"numbers":[1,2,3,4,5]}';

          final stream = streamTextInChunks(
            text: json,
            chunkSize: chunkSize,
            interval: interval,
          );
          final parser = JsonStreamParser(stream);

          final listStream = parser.getListProperty("numbers");
          final list = await listStream.future.withTestTimeout();

          if (verbose) print('[RESULT] $list');

          expect(list, isA<List>());
          expect(list, equals([1, 2, 3, 4, 5]));
          expect(list.length, equals(5));
        });
      }
    }
  });

  group('Nested Map Retrieval - Various Configurations', () {
    for (final chunkSize in [3, 5, 10]) {
      for (final interval in [Duration.zero, Duration(milliseconds: 10)]) {
        test(
            'nested map - chunk=$chunkSize, interval=${interval.inMilliseconds}ms',
            () async {
          final json =
              '{"user":{"name":"Bob","age":25,"address":{"city":"NYC","zip":"10001"}}}';

          final stream = streamTextInChunks(
            text: json,
            chunkSize: chunkSize,
            interval: interval,
          );
          final parser = JsonStreamParser(stream);

          final userStream = parser.getMapProperty("user");
          final addressStream = parser.getMapProperty("user.address");

          final user = await userStream.future.withTestTimeout();
          final address = await addressStream.future.withTestTimeout();

          if (verbose) {
            print('[USER] $user');
            print('[ADDRESS] $address');
          }

          expect(user, isA<Map>());
          expect(user['name'], equals('Bob'));
          expect(user['age'], equals(25));
          expect(user['address'], isA<Map>());

          expect(address, isA<Map>());
          expect(address['city'], equals('NYC'));
          expect(address['zip'], equals('10001'));
        });
      }
    }
  });

  group('List of Objects Retrieval - Various Configurations', () {
    for (final chunkSize in [3, 5, 10, 20]) {
      for (final interval in [
        Duration.zero,
        Duration(milliseconds: 5),
        Duration(milliseconds: 20)
      ]) {
        test(
            'list of objects - chunk=$chunkSize, interval=${interval.inMilliseconds}ms',
            () async {
          final json =
              '{"items":[{"id":1,"name":"Item1"},{"id":2,"name":"Item2"},{"id":3,"name":"Item3"}]}';

          final stream = streamTextInChunks(
            text: json,
            chunkSize: chunkSize,
            interval: interval,
          );
          final parser = JsonStreamParser(stream);

          final item0Stream = parser.getMapProperty("items[0]");
          final item1Stream = parser.getMapProperty("items[1]");
          final item2Stream = parser.getMapProperty("items[2]");
          final listStream = parser.getListProperty("items");

          final item0 = await item0Stream.future.withTestTimeout();
          final item1 = await item1Stream.future.withTestTimeout();
          final item2 = await item2Stream.future.withTestTimeout();
          final list = await listStream.future.withTestTimeout();

          if (verbose) {
            print('[ITEM0] $item0');
            print('[ITEM1] $item1');
            print('[ITEM2] $item2');
            print('[LIST] $list');
          }

          expect(item0, equals({'id': 1, 'name': 'Item1'}));
          expect(item1, equals({'id': 2, 'name': 'Item2'}));
          expect(item2, equals({'id': 3, 'name': 'Item3'}));

          expect(list, isA<List>());
          expect(list.length, equals(3));
        });
      }
    }
  });

  group('Nested Lists Retrieval - Various Configurations', () {
    for (final chunkSize in [3, 7, 15]) {
      for (final interval in [Duration.zero, Duration(milliseconds: 10)]) {
        test(
            'nested lists - chunk=$chunkSize, interval=${interval.inMilliseconds}ms',
            () async {
          final json = '{"matrix":[[1,2,3],[4,5,6],[7,8,9]]}';

          final stream = streamTextInChunks(
            text: json,
            chunkSize: chunkSize,
            interval: interval,
          );
          final parser = JsonStreamParser(stream);

          final matrixStream = parser.getListProperty("matrix");
          final row0Stream = parser.getListProperty("matrix[0]");
          final row1Stream = parser.getListProperty("matrix[1]");
          final row2Stream = parser.getListProperty("matrix[2]");

          final matrix = await matrixStream.future.withTestTimeout();
          final row0 = await row0Stream.future.withTestTimeout();
          final row1 = await row1Stream.future.withTestTimeout();
          final row2 = await row2Stream.future.withTestTimeout();

          if (verbose) {
            print('[MATRIX] $matrix');
            print('[ROW0] $row0');
            print('[ROW1] $row1');
            print('[ROW2] $row2');
          }

          expect(matrix, isA<List>());
          expect(matrix.length, equals(3));

          expect(row0, equals([1, 2, 3]));
          expect(row1, equals([4, 5, 6]));
          expect(row2, equals([7, 8, 9]));
        });
      }
    }
  });

  group('Complex Nested Structures - Various Configurations', () {
    for (final chunkSize in [5, 10, 25]) {
      for (final interval in [Duration.zero, Duration(milliseconds: 5)]) {
        test(
            'complex structure - chunk=$chunkSize, interval=${interval.inMilliseconds}ms',
            () async {
          final json =
              '{"users":[{"name":"Alice","tags":["admin","user"],"meta":{"role":"owner"}},{"name":"Bob","tags":["user"],"meta":{"role":"member"}}]}';

          final stream = streamTextInChunks(
            text: json,
            chunkSize: chunkSize,
            interval: interval,
          );
          final parser = JsonStreamParser(stream);

          final user0Stream = parser.getMapProperty("users[0]");
          final user1Stream = parser.getMapProperty("users[1]");
          final tags0Stream = parser.getListProperty("users[0].tags");
          final tags1Stream = parser.getListProperty("users[1].tags");
          final meta0Stream = parser.getMapProperty("users[0].meta");
          final meta1Stream = parser.getMapProperty("users[1].meta");

          final user0 = await user0Stream.future.withTestTimeout();
          final user1 = await user1Stream.future.withTestTimeout();
          final tags0 = await tags0Stream.future.withTestTimeout();
          final tags1 = await tags1Stream.future.withTestTimeout();
          final meta0 = await meta0Stream.future.withTestTimeout();
          final meta1 = await meta1Stream.future.withTestTimeout();

          if (verbose) {
            print('[USER0] $user0');
            print('[USER1] $user1');
            print('[TAGS0] $tags0');
            print('[TAGS1] $tags1');
            print('[META0] $meta0');
            print('[META1] $meta1');
          }

          expect(user0, isA<Map>());
          expect(user0['name'], equals('Alice'));
          expect(user0['tags'], isA<List>());
          expect(user0['meta'], isA<Map>());

          expect(user1, isA<Map>());
          expect(user1['name'], equals('Bob'));
          expect(user1['tags'], isA<List>());
          expect(user1['meta'], isA<Map>());

          expect(tags0, equals(['admin', 'user']));
          expect(tags1, equals(['user']));

          expect(meta0, equals({'role': 'owner'}));
          expect(meta1, equals({'role': 'member'}));
        });
      }
    }
  });

  group('Large Map Retrieval - Various Configurations', () {
    for (final chunkSize in [5, 15, 30]) {
      for (final interval in [Duration.zero, Duration(milliseconds: 10)]) {
        test(
            'large map (10 keys) - chunk=$chunkSize, interval=${interval.inMilliseconds}ms',
            () async {
          final json =
              '{"k1":"v1","k2":"v2","k3":"v3","k4":"v4","k5":"v5","k6":"v6","k7":"v7","k8":"v8","k9":"v9","k10":"v10"}';

          final stream = streamTextInChunks(
            text: json,
            chunkSize: chunkSize,
            interval: interval,
          );
          final parser = JsonStreamParser(stream);

          final mapStream = parser.getMapProperty("");
          final map = await mapStream.future.withTestTimeout();

          if (verbose) print('[RESULT] $map');

          expect(map, isA<Map>());
          expect(map.length, equals(10));
          for (int i = 1; i <= 10; i++) {
            expect(map['k$i'], equals('v$i'));
          }
        });
      }
    }
  });

  group('Large List Retrieval - Various Configurations', () {
    for (final chunkSize in [5, 15, 30]) {
      for (final interval in [Duration.zero, Duration(milliseconds: 10)]) {
        test(
            'large list (20 items) - chunk=$chunkSize, interval=${interval.inMilliseconds}ms',
            () async {
          final json =
              '{"nums":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]}';

          final stream = streamTextInChunks(
            text: json,
            chunkSize: chunkSize,
            interval: interval,
          );
          final parser = JsonStreamParser(stream);

          final listStream = parser.getListProperty("nums");
          final list = await listStream.future.withTestTimeout();

          if (verbose) print('[RESULT] $list');

          expect(list, isA<List>());
          expect(list.length, equals(20));
          for (int i = 0; i < 20; i++) {
            expect(list[i], equals(i + 1));
          }
        });
      }
    }
  });

  group('Array of Large Objects - Various Configurations', () {
    for (final chunkSize in [10, 20, 40]) {
      for (final interval in [Duration.zero, Duration(milliseconds: 5)]) {
        test(
            'array of large objects - chunk=$chunkSize, interval=${interval.inMilliseconds}ms',
            () async {
          final json =
              '{"products":[{"id":1,"name":"Product1","price":99.99,"stock":50,"tags":["new","featured"]},{"id":2,"name":"Product2","price":49.99,"stock":100,"tags":["sale"]},{"id":3,"name":"Product3","price":149.99,"stock":25,"tags":["premium","featured"]}]}';

          final stream = streamTextInChunks(
            text: json,
            chunkSize: chunkSize,
            interval: interval,
          );
          final parser = JsonStreamParser(stream);

          final prod0Stream = parser.getMapProperty("products[0]");
          final prod1Stream = parser.getMapProperty("products[1]");
          final prod2Stream = parser.getMapProperty("products[2]");

          final prod0 = await prod0Stream.future.withTestTimeout();
          final prod1 = await prod1Stream.future.withTestTimeout();
          final prod2 = await prod2Stream.future.withTestTimeout();

          if (verbose) {
            print('[PROD0] $prod0');
            print('[PROD1] $prod1');
            print('[PROD2] $prod2');
          }

          expect(prod0, isA<Map>());
          expect(prod0['id'], equals(1));
          expect(prod0['name'], equals('Product1'));
          expect(prod0['price'], equals(99.99));
          expect(prod0['stock'], equals(50));
          expect(prod0['tags'], equals(['new', 'featured']));

          expect(prod1, isA<Map>());
          expect(prod1['id'], equals(2));
          expect(prod1['name'], equals('Product2'));
          expect(prod1['price'], equals(49.99));
          expect(prod1['stock'], equals(100));
          expect(prod1['tags'], equals(['sale']));

          expect(prod2, isA<Map>());
          expect(prod2['id'], equals(3));
          expect(prod2['name'], equals('Product3'));
          expect(prod2['price'], equals(149.99));
          expect(prod2['stock'], equals(25));
          expect(prod2['tags'], equals(['premium', 'featured']));
        });
      }
    }
  });

  group('Deep Nesting - Various Configurations', () {
    for (final chunkSize in [5, 15]) {
      for (final interval in [Duration.zero, Duration(milliseconds: 10)]) {
        test(
            'deep nesting (5 levels) - chunk=$chunkSize, interval=${interval.inMilliseconds}ms',
            () async {
          final json = '{"a":{"b":{"c":{"d":{"e":"value"}}}}}';

          final stream = streamTextInChunks(
            text: json,
            chunkSize: chunkSize,
            interval: interval,
          );
          final parser = JsonStreamParser(stream);

          final aStream = parser.getMapProperty("a");
          final bStream = parser.getMapProperty("a.b");
          final cStream = parser.getMapProperty("a.b.c");
          final dStream = parser.getMapProperty("a.b.c.d");

          final a = await aStream.future.withTestTimeout();
          final b = await bStream.future.withTestTimeout();
          final c = await cStream.future.withTestTimeout();
          final d = await dStream.future.withTestTimeout();

          if (verbose) {
            print('[A] $a');
            print('[B] $b');
            print('[C] $c');
            print('[D] $d');
          }

          expect(a, isA<Map>());
          expect(b, isA<Map>());
          expect(c, isA<Map>());
          expect(d, isA<Map>());
          expect(d['e'], equals('value'));
        });
      }
    }
  });

  group('Mixed Type Arrays - Various Configurations', () {
    for (final chunkSize in [3, 8, 16]) {
      for (final interval in [Duration.zero, Duration(milliseconds: 10)]) {
        test(
            'mixed types - chunk=$chunkSize, interval=${interval.inMilliseconds}ms',
            () async {
          final json =
              '{"data":["text",123,true,null,{"key":"value"},[1,2,3]]}';

          final stream = streamTextInChunks(
            text: json,
            chunkSize: chunkSize,
            interval: interval,
          );
          final parser = JsonStreamParser(stream);

          final listStream = parser.getListProperty("data");
          final objStream = parser.getMapProperty("data[4]");
          final arrStream = parser.getListProperty("data[5]");

          final list = await listStream.future.withTestTimeout();
          final obj = await objStream.future.withTestTimeout();
          final arr = await arrStream.future.withTestTimeout();

          if (verbose) {
            print('[LIST] $list');
            print('[OBJ] $obj');
            print('[ARR] $arr');
          }

          expect(list, isA<List>());
          expect(list.length, equals(6));
          expect(list[0], equals('text'));
          expect(list[1], equals(123));
          expect(list[2], equals(true));
          expect(list[3], isNull);

          expect(obj, equals({'key': 'value'}));
          expect(arr, equals([1, 2, 3]));
        });
      }
    }
  });

  group('Empty Structures - Various Configurations', () {
    for (final chunkSize in [2, 5, 10]) {
      for (final interval in [Duration.zero, Duration(milliseconds: 10)]) {
        test(
            'empty map and list - chunk=$chunkSize, interval=${interval.inMilliseconds}ms',
            () async {
          final json = '{"emptyMap":{},"emptyList":[]}';

          final stream = streamTextInChunks(
            text: json,
            chunkSize: chunkSize,
            interval: interval,
          );
          final parser = JsonStreamParser(stream);

          final mapStream = parser.getMapProperty("emptyMap");
          final listStream = parser.getListProperty("emptyList");

          final map = await mapStream.future.withTestTimeout();
          final list = await listStream.future.withTestTimeout();

          if (verbose) {
            print('[MAP] $map');
            print('[LIST] $list');
          }

          expect(map, isA<Map>());
          expect(map.isEmpty, isTrue);

          expect(list, isA<List>());
          expect(list.isEmpty, isTrue);
        });
      }
    }
  });

  group('Whitespace Handling - Various Configurations', () {
    for (final chunkSize in [3, 7, 15]) {
      for (final interval in [Duration.zero, Duration(milliseconds: 10)]) {
        test(
            'with whitespace - chunk=$chunkSize, interval=${interval.inMilliseconds}ms',
            () async {
          final json = '''
          {
            "user": {
              "name": "Charlie",
              "items": [
                { "id": 1 },
                { "id": 2 }
              ]
            }
          }
          ''';

          final stream = streamTextInChunks(
            text: json,
            chunkSize: chunkSize,
            interval: interval,
          );
          final parser = JsonStreamParser(stream);

          final userStream = parser.getMapProperty("user");
          final itemsStream = parser.getListProperty("user.items");
          final item0Stream = parser.getMapProperty("user.items[0]");

          final user = await userStream.future.withTestTimeout();
          final items = await itemsStream.future.withTestTimeout();
          final item0 = await item0Stream.future.withTestTimeout();

          if (verbose) {
            print('[USER] $user');
            print('[ITEMS] $items');
            print('[ITEM0] $item0');
          }

          expect(user, isA<Map>());
          expect(user['name'], equals('Charlie'));

          expect(items, isA<List>());
          expect(items.length, equals(2));

          expect(item0, equals({'id': 1}));
        });
      }
    }
  });

  group('Map Values at Different Nesting Levels', () {
    for (final chunkSize in [3, 10, 25]) {
      for (final interval in [Duration.zero, Duration(milliseconds: 10)]) {
        test(
            'maps as values - chunk=$chunkSize, interval=${interval.inMilliseconds}ms',
            () async {
          final json =
              '{"config":{"db":{"host":"localhost","port":5432},"cache":{"ttl":300}}}';

          final stream = streamTextInChunks(
            text: json,
            chunkSize: chunkSize,
            interval: interval,
          );
          final parser = JsonStreamParser(stream);

          // Get maps at different nesting levels
          final rootStream = parser.getMapProperty("");
          final configStream = parser.getMapProperty("config");
          final dbStream = parser.getMapProperty("config.db");
          final cacheStream = parser.getMapProperty("config.cache");

          final root = await rootStream.future.withTestTimeout();
          final config = await configStream.future.withTestTimeout();
          final db = await dbStream.future.withTestTimeout();
          final cache = await cacheStream.future.withTestTimeout();

          if (verbose) {
            print('[ROOT] $root');
            print('[CONFIG] $config');
            print('[DB] $db');
            print('[CACHE] $cache');
          }

          // Verify root contains everything
          expect(root, isA<Map>());
          expect(root['config'], isA<Map>());

          // Verify config contains nested maps
          expect(config, isA<Map>());
          expect(config['db'], isA<Map>());
          expect(config['cache'], isA<Map>());

          // Verify leaf maps have correct values
          expect(db, equals({'host': 'localhost', 'port': 5432}));
          expect(cache, equals({'ttl': 300}));
        });
      }
    }
  });

  group('List Values at Different Nesting Levels', () {
    for (final chunkSize in [3, 10, 25]) {
      for (final interval in [Duration.zero, Duration(milliseconds: 10)]) {
        test(
            'lists as values - chunk=$chunkSize, interval=${interval.inMilliseconds}ms',
            () async {
          final json = '{"data":{"numbers":[1,2,3],"nested":[[4,5],[6,7]]}}';

          final stream = streamTextInChunks(
            text: json,
            chunkSize: chunkSize,
            interval: interval,
          );
          final parser = JsonStreamParser(stream);

          // Get lists at different nesting levels
          final rootStream = parser.getMapProperty("");
          final dataStream = parser.getMapProperty("data");
          final numbersStream = parser.getListProperty("data.numbers");
          final nestedStream = parser.getListProperty("data.nested");
          final nested0Stream = parser.getListProperty("data.nested[0]");
          final nested1Stream = parser.getListProperty("data.nested[1]");

          final root = await rootStream.future.withTestTimeout();
          final data = await dataStream.future.withTestTimeout();
          final numbers = await numbersStream.future.withTestTimeout();
          final nested = await nestedStream.future.withTestTimeout();
          final nested0 = await nested0Stream.future.withTestTimeout();
          final nested1 = await nested1Stream.future.withTestTimeout();

          if (verbose) {
            print('[ROOT] $root');
            print('[DATA] $data');
            print('[NUMBERS] $numbers');
            print('[NESTED] $nested');
          }

          // Verify root contains data map with lists
          expect(root, isA<Map>());
          expect(root['data'], isA<Map>());

          // Verify data map contains lists
          expect(data, isA<Map>());
          expect(data['numbers'], isA<List>());
          expect(data['nested'], isA<List>());

          // Verify list values
          expect(numbers, equals([1, 2, 3]));
          expect(nested, isA<List>());
          expect(nested.length, equals(2));
          expect(nested[0], isA<List>());
          expect(nested[1], isA<List>());

          // Verify nested list values
          expect(nested0, equals([4, 5]));
          expect(nested1, equals([6, 7]));
        });
      }
    }
  });

  group('Mixed Map and List Values in Parent Structures', () {
    for (final chunkSize in [5, 15]) {
      for (final interval in [Duration.zero, Duration(milliseconds: 10)]) {
        test(
            'parent contains map and list children - chunk=$chunkSize, interval=${interval.inMilliseconds}ms',
            () async {
          final json =
              '{"user":{"profile":{"name":"Alice"},"roles":["admin","user"]}}';

          final stream = streamTextInChunks(
            text: json,
            chunkSize: chunkSize,
            interval: interval,
          );
          final parser = JsonStreamParser(stream);

          // Get parent that contains both map and list
          final userStream = parser.getMapProperty("user");
          final profileStream = parser.getMapProperty("user.profile");
          final rolesStream = parser.getListProperty("user.roles");

          final user = await userStream.future.withTestTimeout();
          final profile = await profileStream.future.withTestTimeout();
          final roles = await rolesStream.future.withTestTimeout();

          if (verbose) {
            print('[USER] $user');
            print('[PROFILE] $profile');
            print('[ROLES] $roles');
          }

          // Verify user contains both map and list
          expect(user, isA<Map>());
          expect(user['profile'], isA<Map>());
          expect(user['roles'], isA<List>());

          // Verify child values
          expect(profile, equals({'name': 'Alice'}));
          expect(roles, equals(['admin', 'user']));
        });
      }
    }
  });

  group('List Contains Maps and Lists at Various Depths', () {
    for (final chunkSize in [5, 15]) {
      for (final interval in [Duration.zero, Duration(milliseconds: 10)]) {
        test(
            'list with mixed complex children - chunk=$chunkSize, interval=${interval.inMilliseconds}ms',
            () async {
          final json =
              '{"items":[{"id":1,"tags":["a","b"]},{"id":2,"tags":["c"]}]}';

          final stream = streamTextInChunks(
            text: json,
            chunkSize: chunkSize,
            interval: interval,
          );
          final parser = JsonStreamParser(stream);

          // Get list and its complex children
          final itemsStream = parser.getListProperty("items");
          final item0Stream = parser.getMapProperty("items[0]");
          final item1Stream = parser.getMapProperty("items[1]");
          final tags0Stream = parser.getListProperty("items[0].tags");
          final tags1Stream = parser.getListProperty("items[1].tags");

          final items = await itemsStream.future.withTestTimeout();
          final item0 = await item0Stream.future.withTestTimeout();
          final item1 = await item1Stream.future.withTestTimeout();
          final tags0 = await tags0Stream.future.withTestTimeout();
          final tags1 = await tags1Stream.future.withTestTimeout();

          if (verbose) {
            print('[ITEMS] $items');
            print('[ITEM0] $item0');
            print('[ITEM1] $item1');
          }

          // Verify list contains maps with nested lists
          expect(items, isA<List>());
          expect(items.length, equals(2));
          expect(items[0], isA<Map>());
          expect(items[1], isA<Map>());

          // Verify each map contains correct data including nested list
          expect(item0['id'], equals(1));
          expect(item0['tags'], isA<List>());
          expect(item0['tags'], equals(['a', 'b']));

          expect(item1['id'], equals(2));
          expect(item1['tags'], isA<List>());
          expect(item1['tags'], equals(['c']));

          // Verify nested lists
          expect(tags0, equals(['a', 'b']));
          expect(tags1, equals(['c']));
        });
      }
    }
  });

  group('Deep Nesting - Map and List Values at 4+ Levels', () {
    for (final chunkSize in [5, 20]) {
      for (final interval in [Duration.zero, Duration(milliseconds: 10)]) {
        test(
            'deeply nested structures - chunk=$chunkSize, interval=${interval.inMilliseconds}ms',
            () async {
          final json = '{"a":{"b":{"c":{"d":[1,2,3],"e":{"f":"value"}}}}}';

          final stream = streamTextInChunks(
            text: json,
            chunkSize: chunkSize,
            interval: interval,
          );
          final parser = JsonStreamParser(stream);

          // Get structures at various depths
          final aStream = parser.getMapProperty("a");
          final bStream = parser.getMapProperty("a.b");
          final cStream = parser.getMapProperty("a.b.c");
          final dStream = parser.getListProperty("a.b.c.d");
          final eStream = parser.getMapProperty("a.b.c.e");

          final a = await aStream.future.withTestTimeout();
          final b = await bStream.future.withTestTimeout();
          final c = await cStream.future.withTestTimeout();
          final d = await dStream.future.withTestTimeout();
          final e = await eStream.future.withTestTimeout();

          if (verbose) {
            print('[A] $a');
            print('[B] $b');
            print('[C] $c');
            print('[D] $d');
            print('[E] $e');
          }

          // Verify each level contains correct nested structure
          expect(a, isA<Map>());
          expect(a['b'], isA<Map>());

          expect(b, isA<Map>());
          expect(b['c'], isA<Map>());

          expect(c, isA<Map>());
          expect(c['d'], isA<List>());
          expect(c['e'], isA<Map>());

          expect(d, equals([1, 2, 3]));
          expect(e, equals({'f': 'value'}));
        });
      }
    }
  });
}


