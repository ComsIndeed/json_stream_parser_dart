
import 'package:llm_json_stream/classes/json_stream_parser.dart';
import 'package:test/test.dart';
import 'package:llm_json_stream/utilities/stream_text_in_chunks.dart';

/// Comprehensive tests for trailing commas with all value types
///
/// Since different delegates (StringPropertyDelegate, NumberPropertyDelegate, etc.)
/// have different parsing logic, we need to test trailing commas with each type
/// as the last element in both arrays and objects.
void main() {
  group('Trailing Commas - All Value Types in Arrays', () {
    test('trailing comma after string in array', () async {
      final input = '{"items":["first","second","last",]}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 8,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final items = await parser
          .getListProperty("items")
          .future
          .timeout(Duration(seconds: 1));

      expect(items, equals(['first', 'second', 'last']));
    });

    test('trailing comma after number in array', () async {
      final input = '{"nums":[1,2,42,]}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 6,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final nums = await parser
          .getListProperty("nums")
          .future
          .timeout(Duration(seconds: 1));

      expect(nums, equals([1, 2, 42]));
    });

    test('trailing comma after decimal number in array', () async {
      final input = '{"prices":[19.99,29.99,39.99,]}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 8,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final prices = await parser
          .getListProperty("prices")
          .future
          .timeout(Duration(seconds: 1));

      expect(prices, equals([19.99, 29.99, 39.99]));
    });

    test('trailing comma after boolean true in array', () async {
      final input = '{"flags":[false,true,true,]}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 7,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final flags = await parser
          .getListProperty("flags")
          .future
          .timeout(Duration(seconds: 1));

      expect(flags, equals([false, true, true]));
    });

    test('trailing comma after boolean false in array', () async {
      final input = '{"flags":[true,true,false,]}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 7,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final flags = await parser
          .getListProperty("flags")
          .future
          .timeout(Duration(seconds: 1));

      expect(flags, equals([true, true, false]));
    });

    test('trailing comma after null in array', () async {
      final input = '{"nullable":[1,"text",null,]}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 8,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final nullable = await parser
          .getListProperty("nullable")
          .future
          .timeout(Duration(seconds: 1));

      expect(nullable, equals([1, 'text', null]));
    });

    test('trailing comma after nested object in array', () async {
      final input = '{"items":[{"a":1},{"b":2},{"c":3},]}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 10,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final items = await parser
          .getListProperty("items")
          .future
          .timeout(Duration(seconds: 1));

      expect(items.length, equals(3));
      expect(items[2], equals({'c': 3}));
    });

    test('trailing comma after nested array in array', () async {
      final input = '{"matrix":[[1,2],[3,4],[5,6],]}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 9,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final matrix = await parser
          .getListProperty("matrix")
          .future
          .timeout(Duration(seconds: 1));

      expect(matrix.length, equals(3));
      expect(matrix[2], equals([5, 6]));
    });

    test('trailing comma after empty string in array', () async {
      final input = '{"strings":["a","b","",]}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 7,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final strings = await parser
          .getListProperty("strings")
          .future
          .timeout(Duration(seconds: 1));

      expect(strings, equals(['a', 'b', '']));
    });

    test('trailing comma after zero in array', () async {
      final input = '{"nums":[1,2,0,]}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 6,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final nums = await parser
          .getListProperty("nums")
          .future
          .timeout(Duration(seconds: 1));

      expect(nums, equals([1, 2, 0]));
    });

    test('trailing comma after negative number in array', () async {
      final input = '{"nums":[10,-5,-99,]}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 7,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final nums = await parser
          .getListProperty("nums")
          .future
          .timeout(Duration(seconds: 1));

      expect(nums, equals([10, -5, -99]));
    });
  });

  group('Trailing Commas - All Value Types in Objects', () {
    test('trailing comma after string value in object', () async {
      final input = '{"a":"first","b":"second","c":"last",}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 10,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final c = await parser
          .getStringProperty("c")
          .future
          .timeout(Duration(seconds: 1));
      final root =
          await parser.getMapProperty("").future.timeout(Duration(seconds: 1));

      expect(c, equals('last'));
      expect(root, equals({'a': 'first', 'b': 'second', 'c': 'last'}));
    });

    test('trailing comma after number value in object', () async {
      final input = '{"x":10,"y":20,"z":30,}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 8,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final z = await parser
          .getNumberProperty("z")
          .future
          .timeout(Duration(seconds: 1));
      final root =
          await parser.getMapProperty("").future.timeout(Duration(seconds: 1));

      expect(z, equals(30));
      expect(root, equals({'x': 10, 'y': 20, 'z': 30}));
    });

    test('trailing comma after decimal value in object', () async {
      final input = '{"price":9.99,"tax":1.50,"total":11.49,}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 12,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final total = await parser
          .getNumberProperty("total")
          .future
          .timeout(Duration(seconds: 1));

      expect(total, equals(11.49));
    });

    test('trailing comma after boolean true value in object', () async {
      final input = '{"a":false,"b":false,"c":true,}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 9,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final c = await parser
          .getBooleanProperty("c")
          .future
          .timeout(Duration(seconds: 1));

      expect(c, equals(true));
    });

    test('trailing comma after boolean false value in object', () async {
      final input = '{"a":true,"b":true,"c":false,}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 9,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final c = await parser
          .getBooleanProperty("c")
          .future
          .timeout(Duration(seconds: 1));

      expect(c, equals(false));
    });

    test('trailing comma after null value in object', () async {
      final input = '{"a":1,"b":"text","c":null,}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 9,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final c = await parser
          .getNullProperty("c")
          .future
          .timeout(Duration(seconds: 1));

      expect(c, equals(null));
    });

    test('trailing comma after nested object value in object', () async {
      final input = '{"first":{"x":1},"second":{"y":2},"third":{"z":3},}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 15,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final third = await parser
          .getMapProperty("third")
          .future
          .timeout(Duration(seconds: 1));
      final z = await parser
          .getNumberProperty("third.z")
          .future
          .timeout(Duration(seconds: 1));

      expect(third, equals({'z': 3}));
      expect(z, equals(3));
    });

    test('trailing comma after nested array value in object', () async {
      final input = '{"a":[1],"b":[2,3],"c":[4,5,6],}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 10,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final c = await parser
          .getListProperty("c")
          .future
          .timeout(Duration(seconds: 1));

      expect(c, equals([4, 5, 6]));
    });

    test('trailing comma after empty string value in object', () async {
      final input = '{"a":"text","b":"","c":"",}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 8,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final c = await parser
          .getStringProperty("c")
          .future
          .timeout(Duration(seconds: 1));

      expect(c, equals(''));
    });

    test('trailing comma after zero value in object', () async {
      final input = '{"a":100,"b":50,"c":0,}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 8,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final c = await parser
          .getNumberProperty("c")
          .future
          .timeout(Duration(seconds: 1));

      expect(c, equals(0));
    });

    test('trailing comma after negative number value in object', () async {
      final input = '{"a":10,"b":-5,"c":-99,}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 8,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final c = await parser
          .getNumberProperty("c")
          .future
          .timeout(Duration(seconds: 1));

      expect(c, equals(-99));
    });
  });

  group('Trailing Commas - Mixed Nested Scenarios', () {
    test('object with trailing comma inside array with trailing comma',
        () async {
      final input = '{"data":[{"x":1,},{"y":2,},]}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 10,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final data = await parser
          .getListProperty("data")
          .future
          .timeout(Duration(seconds: 1));

      expect(data.length, equals(2));
      expect(data[0], equals({'x': 1}));
      expect(data[1], equals({'y': 2}));
    });

    test('array with trailing comma inside object with trailing comma',
        () async {
      final input = '{"a":[1,2,],"b":[3,4,],}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 9,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final a = await parser
          .getListProperty("a")
          .future
          .timeout(Duration(seconds: 1));
      final b = await parser
          .getListProperty("b")
          .future
          .timeout(Duration(seconds: 1));

      expect(a, equals([1, 2]));
      expect(b, equals([3, 4]));
    });

    test('deeply nested with trailing commas at every level', () async {
      final input = '{"level1":{"level2":{"level3":[1,2,3,],},},}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 12,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final level3 = await parser
          .getListProperty("level1.level2.level3")
          .future
          .timeout(Duration(seconds: 1));

      expect(level3, equals([1, 2, 3]));
    });

    test('all types with trailing commas in single array', () async {
      final input = '{"all":["str",42,true,null,{"x":1},[1,2],]}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 12,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final all = await parser
          .getListProperty("all")
          .future
          .timeout(Duration(seconds: 1));

      expect(all.length, equals(6));
      expect(all[0], equals('str'));
      expect(all[1], equals(42));
      expect(all[2], equals(true));
      expect(all[3], equals(null));
      expect(all[4], equals({'x': 1}));
      expect(all[5], equals([1, 2]));
    });

    test('all types with trailing commas in single object', () async {
      final input =
          '{"str":"text","num":42,"bool":true,"nil":null,"obj":{"x":1},"arr":[1,2],}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 15,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final str = await parser
          .getStringProperty("str")
          .future
          .timeout(Duration(seconds: 1));
      final num = await parser
          .getNumberProperty("num")
          .future
          .timeout(Duration(seconds: 1));
      final bool = await parser
          .getBooleanProperty("bool")
          .future
          .timeout(Duration(seconds: 1));
      final nil = await parser
          .getNullProperty("nil")
          .future
          .timeout(Duration(seconds: 1));
      final obj = await parser
          .getMapProperty("obj")
          .future
          .timeout(Duration(seconds: 1));
      final arr = await parser
          .getListProperty("arr")
          .future
          .timeout(Duration(seconds: 1));

      expect(str, equals('text'));
      expect(num, equals(42));
      expect(bool, equals(true));
      expect(nil, equals(null));
      expect(obj, equals({'x': 1}));
      expect(arr, equals([1, 2]));
    });
  });
}
