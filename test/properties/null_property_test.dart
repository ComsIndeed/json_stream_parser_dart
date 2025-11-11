import 'package:json_stream_parser/classes/json_stream_parser.dart';
import 'package:test/test.dart';
import 'package:json_stream_parser/utilities/stream_text_in_chunks.dart';

/// Enable verbose logging to debug test execution
const bool verbose = false;

void main() {
  group('Null Property Tests', () {
    test('null value', () async {
      if (verbose) print('\n[TEST] Null value');

      final json = '{"value":null}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 3,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final valueStream = parser.getNullProperty("value");

      // For atomic values, stream should emit once
      final emittedValue = await valueStream.stream.first;
      if (verbose) print('[EMITTED] $emittedValue');

      // Verify future resolves to the same value
      final finalValue = await valueStream.future;
      if (verbose) print('[FINAL] $finalValue');

      expect(emittedValue, isNull);
      expect(finalValue, isNull);
    });

    test('nested null value', () async {
      if (verbose) print('\n[TEST] Nested null value');

      final json = '{"user":{"middle_name":null}}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final middleNameStream = parser.getNullProperty("user.middle_name");

      final emittedValue = await middleNameStream.stream.first;
      if (verbose) print('[EMITTED] $emittedValue');

      final finalValue = await middleNameStream.future;
      if (verbose) print('[FINAL] $finalValue');

      expect(emittedValue, isNull);
      expect(finalValue, isNull);
    });

    test('deeply nested null value', () async {
      if (verbose) print('\n[TEST] Deeply nested null value');

      final json = '{"data":{"optional":{"field":null}}}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 6,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final fieldStream = parser.getNullProperty("data.optional.field");

      final emittedValue = await fieldStream.stream.first;
      if (verbose) print('[EMITTED] $emittedValue');

      final finalValue = await fieldStream.future;
      if (verbose) print('[FINAL] $finalValue');

      expect(emittedValue, isNull);
      expect(finalValue, isNull);
    });

    test('multiple null properties', () async {
      if (verbose) print('\n[TEST] Multiple null properties');

      final json = '{"field1":null,"field2":null,"field3":null}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final field1Stream = parser.getNullProperty("field1");
      final field2Stream = parser.getNullProperty("field2");
      final field3Stream = parser.getNullProperty("field3");

      final field1 = await field1Stream.future;
      final field2 = await field2Stream.future;
      final field3 = await field3Stream.future;

      if (verbose) {
        print('[FINAL] field1: $field1');
        print('[FINAL] field2: $field2');
        print('[FINAL] field3: $field3');
      }

      expect(field1, isNull);
      expect(field2, isNull);
      expect(field3, isNull);
    });

    test('null mixed with other types', () async {
      if (verbose) print('\n[TEST] Null mixed with other types');

      final json = '{"name":"Alice","age":30,"nickname":null}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final nameStream = parser.getStringProperty("name");
      final ageStream = parser.getNumberProperty("age");
      final nicknameStream = parser.getNullProperty("nickname");

      final name = await nameStream.future;
      final age = await ageStream.future;
      final nickname = await nicknameStream.future;

      if (verbose) {
        print('[FINAL] name: $name');
        print('[FINAL] age: $age');
        print('[FINAL] nickname: $nickname');
      }

      expect(name, equals('Alice'));
      expect(age, equals(30));
      expect(nickname, isNull);
    });
  });
}
