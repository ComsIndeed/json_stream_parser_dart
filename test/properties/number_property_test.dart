import 'package:llm_json_stream/json_stream_parser.dart';
import 'package:test/test.dart';

import 'list_property_test.dart';

/// Enable verbose logging to debug test execution
const bool verbose = false;

void main() {
  group('Number Property Tests', () {
    test('simple integer', () async {
      if (verbose) print('\n[TEST] Simple integer');

      final json = '{"age":30}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 3,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final ageStream = parser.getNumberProperty("age");

      // For atomic values, stream should emit once
      final emittedValue = await ageStream.stream.first;
      if (verbose) print('[EMITTED] $emittedValue');

      // Verify future resolves to the same value
      final finalValue = await ageStream.future.withTestTimeout();
      if (verbose) print('[FINAL] $finalValue');

      expect(emittedValue, equals(30));
      expect(finalValue, equals(30));
    });

    test('negative integer', () async {
      if (verbose) print('\n[TEST] Negative integer');

      final json = '{"temperature":-5}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 4,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final tempStream = parser.getNumberProperty("temperature");

      final emittedValue = await tempStream.stream.first;
      if (verbose) print('[EMITTED] $emittedValue');

      final finalValue = await tempStream.future.withTestTimeout();
      if (verbose) print('[FINAL] $finalValue');

      expect(emittedValue, equals(-5));
      expect(finalValue, equals(-5));
    });

    test('decimal number', () async {
      if (verbose) print('\n[TEST] Decimal number');

      final json = '{"price":19.99}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 3,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final priceStream = parser.getNumberProperty("price");

      final emittedValue = await priceStream.stream.first;
      if (verbose) print('[EMITTED] $emittedValue');

      final finalValue = await priceStream.future.withTestTimeout();
      if (verbose) print('[FINAL] $finalValue');

      expect(emittedValue, equals(19.99));
      expect(finalValue, equals(19.99));
    });

    test('scientific notation', () async {
      if (verbose) print('\n[TEST] Scientific notation');

      final json = '{"large":1.23e10}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 4,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final largeStream = parser.getNumberProperty("large");

      final emittedValue = await largeStream.stream.first;
      if (verbose) print('[EMITTED] $emittedValue');

      final finalValue = await largeStream.future.withTestTimeout();
      if (verbose) print('[FINAL] $finalValue');

      expect(emittedValue, equals(1.23e10));
      expect(finalValue, equals(1.23e10));
    });

    test('negative scientific notation', () async {
      if (verbose) print('\n[TEST] Negative scientific notation');

      final json = '{"small":-2.5e-3}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 4,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final smallStream = parser.getNumberProperty("small");

      final emittedValue = await smallStream.stream.first;
      if (verbose) print('[EMITTED] $emittedValue');

      final finalValue = await smallStream.future.withTestTimeout();
      if (verbose) print('[FINAL] $finalValue');

      expect(emittedValue, equals(-2.5e-3));
      expect(finalValue, equals(-2.5e-3));
    });

    test('zero', () async {
      if (verbose) print('\n[TEST] Zero');

      final json = '{"count":0}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 3,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final countStream = parser.getNumberProperty("count");

      final emittedValue = await countStream.stream.first;
      if (verbose) print('[EMITTED] $emittedValue');

      final finalValue = await countStream.future.withTestTimeout();
      if (verbose) print('[FINAL] $finalValue');

      expect(emittedValue, equals(0));
      expect(finalValue, equals(0));
    });

    test('large integer', () async {
      if (verbose) print('\n[TEST] Large integer');

      final json = '{"big":9223372036854775807}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final bigStream = parser.getNumberProperty("big");

      final emittedValue = await bigStream.stream.first;
      if (verbose) print('[EMITTED] $emittedValue');

      final finalValue = await bigStream.future.withTestTimeout();
      if (verbose) print('[FINAL] $finalValue');

      expect(emittedValue, equals(9223372036854775807));
      expect(finalValue, equals(9223372036854775807));
    });

    test('nested number access', () async {
      if (verbose) print('\n[TEST] Nested number access');

      final json = '{"user":{"age":25}}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 4,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final ageStream = parser.getNumberProperty("user.age");

      final emittedValue = await ageStream.stream.first;
      if (verbose) print('[EMITTED] $emittedValue');

      final finalValue = await ageStream.future.withTestTimeout();
      if (verbose) print('[FINAL] $finalValue');

      expect(emittedValue, equals(25));
      expect(finalValue, equals(25));
    });

    test('deeply nested number access', () async {
      if (verbose) print('\n[TEST] Deeply nested number access');

      final json = '{"data":{"stats":{"count":42}}}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final countStream = parser.getNumberProperty("data.stats.count");

      final emittedValue = await countStream.stream.first;
      if (verbose) print('[EMITTED] $emittedValue');

      final finalValue = await countStream.future.withTestTimeout();
      if (verbose) print('[FINAL] $finalValue');

      expect(emittedValue, equals(42));
      expect(finalValue, equals(42));
    });

    test('decimal with trailing zeros', () async {
      if (verbose) print('\n[TEST] Decimal with trailing zeros');

      final json = '{"value":3.14000}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 3,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final valueStream = parser.getNumberProperty("value");

      final emittedValue = await valueStream.stream.first;
      if (verbose) print('[EMITTED] $emittedValue');

      final finalValue = await valueStream.future.withTestTimeout();
      if (verbose) print('[FINAL] $finalValue');

      expect(emittedValue, equals(3.14));
      expect(finalValue, equals(3.14));
    });

    test('number as num type', () async {
      if (verbose) print('\n[TEST] Number as num type');

      final json = '{"value":123.456}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 4,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final valueStream = parser.getNumberProperty("value");

      final emittedValue = await valueStream.stream.first;
      if (verbose) print('[EMITTED] $emittedValue');

      final finalValue = await valueStream.future.withTestTimeout();
      if (verbose) print('[FINAL] $finalValue');

      expect(emittedValue, equals(123.456));
      expect(finalValue, equals(123.456));
    });
  });
}


