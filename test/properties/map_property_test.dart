import 'package:json_stream_parser/classes/json_stream_parser.dart';
import 'package:test/test.dart';
import 'package:json_stream_parser/utilities/stream_text_in_chunks.dart';

import 'list_property_test.dart';

/// Enable verbose logging to debug test execution
const bool verbose = false;

void main() {
  group('Map Property Tests', () {
    test('simple flat map - get entire map', () async {
      if (verbose) print('\n[TEST] Simple flat map');

      final json = '{"name":"Alice","age":30}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 4,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      // Get the root map (empty string path represents root)
      final mapStream = parser.getMapProperty("");
      final nameStream = parser.getStringProperty("name");
      final ageStream = parser.getNumberProperty("age");

      final finalMap = await mapStream.future.withTestTimeout();
      final name = await nameStream.future.withTestTimeout();
      final age = await ageStream.future.withTestTimeout();

      if (verbose) print('[FINAL] Map completed, name: $name, age: $age');

      expect(finalMap, isA<Map>());
      expect(name, equals('Alice'));
      expect(age, equals(30));
    });

    test('get specific property from flat map', () async {
      if (verbose) print('\n[TEST] Get specific property from flat map');

      final json = '{"name":"Bob","age":25}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 3,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final nameStream = parser.getStringProperty("name");
      final ageStream = parser.getNumberProperty("age");

      final name = await nameStream.future.withTestTimeout();
      final age = await ageStream.future.withTestTimeout();

      if (verbose) {
        print('[FINAL] name: $name');
        print('[FINAL] age: $age');
      }

      expect(name, equals('Bob'));
      expect(age, equals(25));
    });

    test('nested map access - single level', () async {
      if (verbose) print('\n[TEST] Nested map - single level');

      final json = '{"user":{"name":"Charlie","age":35}}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      // Get nested map and its properties
      final userMapStream = parser.getMapProperty("user");
      final nameStream = parser.getStringProperty("user.name");
      final ageStream = parser.getNumberProperty("user.age");

      final userMap = await userMapStream.future.withTestTimeout();
      final name = await nameStream.future.withTestTimeout();
      final age = await ageStream.future.withTestTimeout();

      if (verbose) print('[FINAL] user map completed, name: $name, age: $age');

      expect(userMap, isA<Map>());
      expect(name, equals('Charlie'));
      expect(age, equals(35));
    });

    test('nested map access - deep path', () async {
      if (verbose) print('\n[TEST] Nested map - deep path');

      final json = '{"user":{"address":{"city":"NYC","zip":"10001"}}}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 6,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      // Access deeply nested property
      final cityStream = parser.getStringProperty("user.address.city");
      final zipStream = parser.getStringProperty("user.address.zip");

      final city = await cityStream.future.withTestTimeout();
      final zip = await zipStream.future.withTestTimeout();

      if (verbose) {
        print('[FINAL] city: $city');
        print('[FINAL] zip: $zip');
      }

      expect(city, equals('NYC'));
      expect(zip, equals('10001'));
    });

    test('very deeply nested map', () async {
      if (verbose) print('\n[TEST] Very deeply nested map');

      final json = '{"a":{"b":{"c":{"d":{"value":"deep"}}}}}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final valueStream = parser.getStringProperty("a.b.c.d.value");
      final value = await valueStream.future.withTestTimeout();

      if (verbose) print('[FINAL] value: $value');

      expect(value, equals('deep'));
    });

    test('empty map', () async {
      if (verbose) print('\n[TEST] Empty map');

      final json = '{"empty":{}}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 3,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final emptyMapStream = parser.getMapProperty("empty");
      final emptyMap = await emptyMapStream.future.withTestTimeout();

      if (verbose) print('[FINAL] empty: $emptyMap');

      expect(emptyMap, isA<Map>());
      expect(emptyMap.isEmpty, isTrue);
    });

    test('map with mixed types', () async {
      if (verbose) print('\n[TEST] Map with mixed types');

      final json = '{"string":"text","number":42,"bool":true,"null":null}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final stringStream = parser.getStringProperty("string");
      final numberStream = parser.getNumberProperty("number");
      final boolStream = parser.getBooleanProperty("bool");
      final nullStream = parser.getNullProperty("null");

      final stringVal = await stringStream.future.withTestTimeout();
      final numberVal = await numberStream.future.withTestTimeout();
      final boolVal = await boolStream.future.withTestTimeout();
      final nullVal = await nullStream.future.withTestTimeout();

      if (verbose) {
        print('[FINAL] string: $stringVal');
        print('[FINAL] number: $numberVal');
        print('[FINAL] bool: $boolVal');
        print('[FINAL] null: $nullVal');
      }

      expect(stringVal, equals('text'));
      expect(numberVal, equals(42));
      expect(boolVal, equals(true));
      expect(nullVal, isNull);
    });

    test('chainable property access - get map then chain', () async {
      if (verbose) print('\n[TEST] Chainable property access');

      final json = '{"user":{"name":"Dave","email":"dave@example.com"}}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 6,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      // Get user map first
      final userMapStream = parser.getMapProperty("user");
      final userMap = await userMapStream.future.withTestTimeout();

      if (verbose) print('[GOT MAP] user: $userMap');

      // Now chain to get properties from that map
      final nameStream = userMapStream.getStringProperty("name");
      final emailStream = userMapStream.getStringProperty("email");

      final name = await nameStream.future.withTestTimeout();
      final email = await emailStream.future.withTestTimeout();

      if (verbose) {
        print('[CHAINED] name: $name');
        print('[CHAINED] email: $email');
      }

      expect(name, equals('Dave'));
      expect(email, equals('dave@example.com'));
    });

    test('map with nested maps and mixed content', () async {
      if (verbose) print('\n[TEST] Complex nested structure');

      final json = '{"person":{"info":{"name":"Eve","age":28},"active":true}}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 7,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final nameStream = parser.getStringProperty("person.info.name");
      final ageStream = parser.getNumberProperty("person.info.age");
      final activeStream = parser.getBooleanProperty("person.active");

      final name = await nameStream.future.withTestTimeout();
      final age = await ageStream.future.withTestTimeout();
      final active = await activeStream.future.withTestTimeout();

      if (verbose) {
        print('[FINAL] name: $name');
        print('[FINAL] age: $age');
        print('[FINAL] active: $active');
      }

      expect(name, equals('Eve'));
      expect(age, equals(28));
      expect(active, equals(true));
    });

    test('multiple maps at same level', () async {
      if (verbose) print('\n[TEST] Multiple maps at same level');

      final json = '{"map1":{"a":1},"map2":{"b":2},"map3":{"c":3}}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 6,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final aStream = parser.getNumberProperty("map1.a");
      final bStream = parser.getNumberProperty("map2.b");
      final cStream = parser.getNumberProperty("map3.c");

      final a = await aStream.future.withTestTimeout();
      final b = await bStream.future.withTestTimeout();
      final c = await cStream.future.withTestTimeout();

      if (verbose) {
        print('[FINAL] a: $a');
        print('[FINAL] b: $b');
        print('[FINAL] c: $c');
      }

      expect(a, equals(1));
      expect(b, equals(2));
      expect(c, equals(3));
    });

    test('map with whitespace between tokens', () async {
      if (verbose) print('\n[TEST] Map with whitespace');

      final json = '{ "name" : "Frank" , "age" : 40 }';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final nameStream = parser.getStringProperty("name");
      final ageStream = parser.getNumberProperty("age");

      final name = await nameStream.future.withTestTimeout();
      final age = await ageStream.future.withTestTimeout();

      if (verbose) {
        print('[FINAL] name: $name');
        print('[FINAL] age: $age');
      }

      expect(name, equals('Frank'));
      expect(age, equals(40));
    });
  });
}
