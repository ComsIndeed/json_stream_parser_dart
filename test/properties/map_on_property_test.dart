import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:test/test.dart';

void main() {
  group('MapPropertyStream.onProperty', () {
    test('fires callback for each property in a map', () async {
      final input = '{"name":"Alice","age":30,"active":true}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final mapStream = parser.getMapProperty('');
      final discoveredProperties = <String>[];
      final propertyTypes = <String, Type>{};

      mapStream.onProperty((property, key) {
        discoveredProperties.add(key);
        propertyTypes[key] = property.runtimeType;
        print('Discovered property: $key (type: ${property.runtimeType})');
      });

      final result = await mapStream.future.timeout(Duration(seconds: 2));

      expect(result, equals({'name': 'Alice', 'age': 30, 'active': true}));
      expect(discoveredProperties, equals(['name', 'age', 'active']));
      expect(propertyTypes['name'], equals(StringPropertyStream));
      expect(propertyTypes['age'], equals(NumberPropertyStream));
      expect(propertyTypes['active'], equals(BooleanPropertyStream));
    });

    test('allows subscribing to property stream in callback', () async {
      final input = '{"title":"Hello World"}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 3,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final mapStream = parser.getMapProperty('');
      final stringChunks = <String>[];

      mapStream.onProperty((property, key) {
        if (property is StringPropertyStream) {
          property.stream.listen((chunk) {
            print('String chunk for $key: $chunk');
            stringChunks.add(chunk);
          });
        }
      });

      await mapStream.future.timeout(Duration(seconds: 2));

      // Check that we received string chunks
      expect(stringChunks, isNotEmpty);
      // The accumulated chunks should equal the full string
      expect(stringChunks.join(''), equals('Hello World'));
    });

    test('works with nested maps', () async {
      final input = '{"user":{"name":"Bob","address":{"city":"NYC"}}}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 8,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final rootMap = parser.getMapProperty('');
      final userMap = parser.getMapProperty('user');
      final addressMap = parser.getMapProperty('user.address');

      final rootProps = <String>[];
      final userProps = <String>[];
      final addressProps = <String>[];

      rootMap.onProperty((_, key) {
        print('Root property: $key');
        rootProps.add(key);
      });

      userMap.onProperty((_, key) {
        print('User property: $key');
        userProps.add(key);
      });

      addressMap.onProperty((_, key) {
        print('Address property: $key');
        addressProps.add(key);
      });

      final result = await rootMap.future.timeout(Duration(seconds: 2));

      expect(
          result,
          equals({
            'user': {
              'name': 'Bob',
              'address': {'city': 'NYC'}
            }
          }));
      expect(rootProps, equals(['user']));
      expect(userProps, equals(['name', 'address']));
      expect(addressProps, equals(['city']));
    });

    test('fires before property value is complete', () async {
      final input =
          '{"message":"This is a long message that streams in slowly"}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 10,
        interval: Duration(milliseconds: 20),
      );
      final parser = JsonStreamParser(stream);

      final mapStream = parser.getMapProperty('');
      var callbackFiredTime = DateTime.now();
      var futureCompleteTime = DateTime.now();

      mapStream.onProperty((property, key) {
        callbackFiredTime = DateTime.now();
        print('Property $key discovered at $callbackFiredTime');
      });

      await mapStream.future.timeout(Duration(seconds: 3));
      futureCompleteTime = DateTime.now();
      print('Future completed at $futureCompleteTime');

      // The callback should fire before the future completes
      expect(callbackFiredTime.isBefore(futureCompleteTime), isTrue);
    });

    test('handles maps with list properties', () async {
      final input = '{"items":[1,2,3],"names":["a","b"]}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 6,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final mapStream = parser.getMapProperty('');
      final discoveredTypes = <String, Type>{};

      mapStream.onProperty((property, key) {
        discoveredTypes[key] = property.runtimeType;
        print('Property $key is type ${property.runtimeType}');
      });

      final result = await mapStream.future.timeout(Duration(seconds: 2));

      expect(
          result,
          equals({
            'items': [1, 2, 3],
            'names': ['a', 'b']
          }));
      expect(discoveredTypes['items'], equals(ListPropertyStream<Object?>));
      expect(discoveredTypes['names'], equals(ListPropertyStream<Object?>));
    });

    test('multiple callbacks can be registered', () async {
      final input = '{"x":1,"y":2}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final mapStream = parser.getMapProperty('');
      final callback1Props = <String>[];
      final callback2Props = <String>[];

      mapStream.onProperty((_, key) {
        callback1Props.add('cb1:$key');
      });

      mapStream.onProperty((_, key) {
        callback2Props.add('cb2:$key');
      });

      await mapStream.future.timeout(Duration(seconds: 2));

      expect(callback1Props, equals(['cb1:x', 'cb1:y']));
      expect(callback2Props, equals(['cb2:x', 'cb2:y']));
    });

    test('onProperty and stream work together', () async {
      final input = '{"a":1,"b":2,"c":3}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 4,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final mapStream = parser.getMapProperty('');
      final onPropertyKeys = <String>[];
      final streamSnapshots = <Map<String, dynamic>>[];

      mapStream.onProperty((_, key) {
        onPropertyKeys.add(key);
      });

      mapStream.stream.listen((snapshot) {
        streamSnapshots.add(Map.from(snapshot));
      });

      final result = await mapStream.future.timeout(Duration(seconds: 2));

      expect(result, equals({'a': 1, 'b': 2, 'c': 3}));
      expect(onPropertyKeys, equals(['a', 'b', 'c']));
      // Stream should have emitted snapshots as the map was built
      expect(streamSnapshots.isNotEmpty, isTrue);
      // Final snapshot should have all keys (values may still be completing)
      expect(streamSnapshots.last.keys.toSet(), equals({'a', 'b', 'c'}));
    });
  });
}
