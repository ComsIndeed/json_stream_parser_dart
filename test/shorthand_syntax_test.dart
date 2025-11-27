import 'dart:async';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:test/test.dart';

void main() {
  group('JsonStreamParser Shorthand Syntax', () {
    test('.str() returns StringPropertyStream with correct type', () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      // Use shorthand syntax
      final titleStream = parser.str('title');

      // Verify it's the correct type
      expect(titleStream, isA<StringPropertyStream>());

      // Verify .stream works
      expect(titleStream.stream, isA<Stream<String>>());

      // Set up stream listener BEFORE sending data
      final chunks = <String>[];
      titleStream.stream.listen(chunks.add);

      // Send JSON data
      controller.add('{"title": "Hello');
      await Future.delayed(Duration(milliseconds: 10));
      controller.add(' World"}');
      controller.close();

      // Verify the future completes with full value
      final result = await titleStream.future;
      expect(result, 'Hello World');
      expect(chunks, isNotEmpty);
      expect(chunks.join(''), 'Hello World');

      await parser.dispose();
    });

    test('.number() returns NumberPropertyStream with correct type', () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      // Use shorthand syntax
      final ageStream = parser.number('age');

      // Verify it's the correct type
      expect(ageStream, isA<NumberPropertyStream>());

      // Verify .stream works
      expect(ageStream.stream, isA<Stream<num>>());

      // Send JSON data
      controller.add('{"age": 42}');
      controller.close();

      // Verify the future completes with correct value
      final result = await ageStream.future;
      expect(result, 42);

      await parser.dispose();
    });

    test('.boolean() returns BooleanPropertyStream with correct type',
        () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      // Use shorthand syntax
      final isActiveStream = parser.boolean('isActive');

      // Verify it's the correct type
      expect(isActiveStream, isA<BooleanPropertyStream>());

      // Verify .stream works
      expect(isActiveStream.stream, isA<Stream<bool>>());

      // Send JSON data
      controller.add('{"isActive": true}');
      controller.close();

      // Verify the future completes with correct value
      final result = await isActiveStream.future;
      expect(result, true);

      await parser.dispose();
    });

    test('.nil() returns NullPropertyStream with correct type', () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      // Use shorthand syntax
      final nullStream = parser.nil('nullValue');

      // Verify it's the correct type
      expect(nullStream, isA<NullPropertyStream>());

      // Verify .stream works
      expect(nullStream.stream, isA<Stream<Null>>());

      // Send JSON data
      controller.add('{"nullValue": null}');
      controller.close();

      // Verify the future completes with null
      final result = await nullStream.future;
      expect(result, null);

      await parser.dispose();
    });

    test('.map() returns MapPropertyStream with correct type', () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      // Use shorthand syntax
      final userStream = parser.map('user');

      // Verify it's the correct type
      expect(userStream, isA<MapPropertyStream>());

      // Send JSON data
      controller.add('{"user": {"name": "Alice", "age": 30}}');
      controller.close();

      // Verify the future completes with correct value
      final result = await userStream.future;
      expect(result, {'name': 'Alice', 'age': 30});

      await parser.dispose();
    });

    test('.list() returns ListPropertyStream with correct type', () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      // Use shorthand syntax
      final itemsStream = parser.list('items');

      // Verify it's the correct type
      expect(itemsStream, isA<ListPropertyStream>());

      // Send JSON data
      controller.add('{"items": [1, 2, 3]}');
      controller.close();

      // Verify the future completes with correct value
      final result = await itemsStream.future;
      expect(result, [1, 2, 3]);

      await parser.dispose();
    });

    test('Shorthand methods work with nested paths', () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      // Use shorthand syntax with nested paths
      final nameStream = parser.str('user.name');
      final ageStream = parser.number('user.age');

      controller.add('{"user": {"name": "Bob", "age": 25}}');
      controller.close();

      final name = await nameStream.future;
      final age = await ageStream.future;

      expect(name, 'Bob');
      expect(age, 25);

      await parser.dispose();
    });
  });

  group('MapPropertyStream Shorthand Syntax', () {
    test('.str() works on MapPropertyStream', () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      // Get a map and use shorthand on it
      final userMap = parser.map('user');
      final nameStream = userMap.str('name');

      // Verify type
      expect(nameStream, isA<StringPropertyStream>());

      controller.add('{"user": {"name": "Charlie"}}');
      controller.close();

      final result = await nameStream.future;
      expect(result, 'Charlie');

      await parser.dispose();
    });

    test('.number() works on MapPropertyStream', () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      final userMap = parser.map('user');
      final ageStream = userMap.number('age');

      expect(ageStream, isA<NumberPropertyStream>());

      controller.add('{"user": {"age": 35}}');
      controller.close();

      final result = await ageStream.future;
      expect(result, 35);

      await parser.dispose();
    });

    test('.boolean() works on MapPropertyStream', () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      final userMap = parser.map('user');
      final isActiveStream = userMap.boolean('isActive');

      expect(isActiveStream, isA<BooleanPropertyStream>());

      controller.add('{"user": {"isActive": false}}');
      controller.close();

      final result = await isActiveStream.future;
      expect(result, false);

      await parser.dispose();
    });

    test('.map() works on MapPropertyStream for nested maps', () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      final userMap = parser.map('user');
      final profileMap = userMap.map('profile');

      expect(profileMap, isA<MapPropertyStream>());

      controller.add('{"user": {"profile": {"bio": "Hello"}}}');
      controller.close();

      final result = await profileMap.future;
      expect(result, {'bio': 'Hello'});

      await parser.dispose();
    });

    test('.list() works on MapPropertyStream', () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      final userMap = parser.map('user');
      final tagsStream = userMap.list('tags');

      expect(tagsStream, isA<ListPropertyStream>());

      controller.add('{"user": {"tags": ["admin", "user"]}}');
      controller.close();

      final result = await tagsStream.future;
      expect(result, ['admin', 'user']);

      await parser.dispose();
    });

    test('Chained shorthand methods work on MapPropertyStream', () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      final userMap = parser.map('user');
      final profileMap = userMap.map('profile');
      final bioStream = profileMap.str('bio');

      expect(bioStream, isA<StringPropertyStream>());

      controller.add('{"user": {"profile": {"bio": "Developer"}}}');
      controller.close();

      final result = await bioStream.future;
      expect(result, 'Developer');

      await parser.dispose();
    });
  });

  group('ListPropertyStream Shorthand Syntax', () {
    test('.str() works on list elements via onElement callback', () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      final itemsStream = parser.list('items');
      final names = <String>[];

      itemsStream.onElement((element, index) {
        if (element is MapPropertyStream) {
          final nameStream = element.str('name');
          nameStream.future.then((name) => names.add(name));
        }
      });

      controller.add('{"items": [{"name": "Item1"}, {"name": "Item2"}]}');
      controller.close();

      await itemsStream.future;
      await Future.delayed(Duration(milliseconds: 50));

      expect(names, ['Item1', 'Item2']);

      await parser.dispose();
    });

    test('.number() works on list elements', () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      final itemsStream = parser.list('items');
      final prices = <num>[];

      itemsStream.onElement((element, index) {
        if (element is MapPropertyStream) {
          final priceStream = element.number('price');
          priceStream.future.then((price) => prices.add(price));
        }
      });

      controller.add('{"items": [{"price": 10.5}, {"price": 20}]}');
      controller.close();

      await itemsStream.future;
      await Future.delayed(Duration(milliseconds: 50));

      expect(prices, [10.5, 20]);

      await parser.dispose();
    });

    test('.boolean() works on list elements', () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      final itemsStream = parser.list('items');
      final statuses = <bool>[];

      itemsStream.onElement((element, index) {
        if (element is MapPropertyStream) {
          final activeStream = element.boolean('active');
          activeStream.future.then((active) => statuses.add(active));
        }
      });

      controller.add('{"items": [{"active": true}, {"active": false}]}');
      controller.close();

      await itemsStream.future;
      await Future.delayed(Duration(milliseconds: 50));

      expect(statuses, [true, false]);

      await parser.dispose();
    });

    test('.map() works on list elements for nested objects', () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      final itemsStream = parser.list('items');
      final metadataList = <Map<String, Object?>>[];

      itemsStream.onElement((element, index) {
        if (element is MapPropertyStream) {
          final metaStream = element.map('metadata');
          metaStream.future.then((meta) => metadataList.add(meta));
        }
      });

      controller.add(
          '{"items": [{"metadata": {"key": "val1"}}, {"metadata": {"key": "val2"}}]}');
      controller.close();

      await itemsStream.future;
      await Future.delayed(Duration(milliseconds: 50));

      expect(metadataList, [
        {'key': 'val1'},
        {'key': 'val2'}
      ]);

      await parser.dispose();
    });

    test('.list() works on nested lists', () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      final itemsStream = parser.list('items');
      final nestedLists = <List<Object?>>[];

      itemsStream.onElement((element, index) {
        if (element is MapPropertyStream) {
          final tagsStream = element.list('tags');
          tagsStream.future.then((tags) => nestedLists.add(tags));
        }
      });

      controller.add('{"items": [{"tags": ["a", "b"]}, {"tags": ["c"]}]}');
      controller.close();

      await itemsStream.future;
      await Future.delayed(Duration(milliseconds: 50));

      expect(nestedLists, [
        ['a', 'b'],
        ['c']
      ]);

      await parser.dispose();
    });

    test('Direct index access with shorthand methods', () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      // Access list element by index using shorthand
      final firstItemMap = parser.map('items[0]');
      final nameStream = firstItemMap.str('name');

      expect(nameStream, isA<StringPropertyStream>());

      controller.add('{"items": [{"name": "FirstItem"}]}');
      controller.close();

      final result = await nameStream.future;
      expect(result, 'FirstItem');

      await parser.dispose();
    });
  });

  group('Type Safety with Shorthand Methods', () {
    test('Typed property streams maintain their types', () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      final str = parser.str('text');
      final numStream = parser.number('count');
      final boolStream = parser.boolean('flag');
      final map = parser.map('object');
      final list = parser.list('array');

      // Type checks
      expect(str, isA<StringPropertyStream>());
      expect(numStream, isA<NumberPropertyStream>());
      expect(boolStream, isA<BooleanPropertyStream>());
      expect(map, isA<MapPropertyStream>());
      expect(list, isA<ListPropertyStream>());

      controller.add(
          '{"text": "hi", "count": 1, "flag": true, "object": {}, "array": []}');
      controller.close();

      // Verify futures have correct types
      expect(await str.future, isA<String>());
      expect(await numStream.future, isA<num>());
      expect(await boolStream.future, isA<bool>());
      expect(await map.future, isA<Map<String, Object?>>());
      expect(await list.future, isA<List<Object?>>());

      await parser.dispose();
    });

    test('Stream types are correct for shorthand methods', () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      final str = parser.str('text');
      final numStream = parser.number('count');
      final boolStream = parser.boolean('flag');

      // Stream type checks
      expect(str.stream, isA<Stream<String>>());
      expect(numStream.stream, isA<Stream<num>>());
      expect(boolStream.stream, isA<Stream<bool>>());

      controller.add('{"text": "hi", "count": 1, "flag": true}');
      controller.close();

      // Wait for parsing to complete before disposing
      await str.future;
      await numStream.future;
      await boolStream.future;

      await parser.dispose();
    });
  });

  group('Mixed Usage - Shorthand and Full Method Names', () {
    test('Can mix shorthand and full method names', () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      // Mix shorthand and full names
      final title = parser.str('title');
      final count = parser.getNumberProperty('count');
      final isActive = parser.boolean('isActive');
      final user = parser.getMapProperty('user');

      controller.add(
          '{"title": "Test", "count": 5, "isActive": true, "user": {"name": "X"}}');
      controller.close();

      expect(await title.future, 'Test');
      expect(await count.future, 5);
      expect(await isActive.future, true);
      expect(await user.future, {'name': 'X'});

      await parser.dispose();
    });

    test('Shorthand methods are equivalent to full method names', () async {
      final controller1 = StreamController<String>();
      final controller2 = StreamController<String>();

      final parser1 = JsonStreamParser(controller1.stream);
      final parser2 = JsonStreamParser(controller2.stream);

      // Use shorthand
      final stream1 = parser1.str('name');
      // Use full name
      final stream2 = parser2.getStringProperty('name');

      // Both should have the same type
      expect(stream1.runtimeType, stream2.runtimeType);

      controller1.add('{"name": "Test1"}');
      controller2.add('{"name": "Test2"}');
      controller1.close();
      controller2.close();

      expect(await stream1.future, 'Test1');
      expect(await stream2.future, 'Test2');

      await parser1.dispose();
      await parser2.dispose();
    });
  });

  group('Complex Nested Structures with Shorthand', () {
    test('Deep nesting with all shorthand methods', () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      final data = parser.map('data');
      final users = data.list('users');

      final collectedNames = <String>[];

      users.onElement((element, index) {
        if (element is MapPropertyStream) {
          final profile = element.map('profile');
          final name = profile.str('name');
          name.future.then((n) => collectedNames.add(n));
        }
      });

      controller.add(
          '{"data": {"users": [{"profile": {"name": "Alice"}}, {"profile": {"name": "Bob"}}]}}');
      controller.close();

      await users.future;
      await Future.delayed(Duration(milliseconds: 50));

      expect(collectedNames, ['Alice', 'Bob']);

      await parser.dispose();
    });

    test('Complex mixed types with shorthand syntax', () async {
      final controller = StreamController<String>();
      final parser = JsonStreamParser(controller.stream);

      final config = parser.map('config');
      final name = config.str('name');
      final version = config.number('version');
      final enabled = config.boolean('enabled');
      final features = config.list('features');
      final metadata = config.map('metadata');

      controller.add('''
        {
          "config": {
            "name": "MyApp",
            "version": 2.5,
            "enabled": true,
            "features": ["auth", "storage"],
            "metadata": {"author": "Dev"}
          }
        }
      ''');
      controller.close();

      expect(await name.future, 'MyApp');
      expect(await version.future, 2.5);
      expect(await enabled.future, true);
      expect(await features.future, ['auth', 'storage']);
      expect(await metadata.future, {'author': 'Dev'});

      await parser.dispose();
    });
  });
}


