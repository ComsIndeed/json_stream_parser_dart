import 'package:json_stream_parser/classes/json_stream_parser.dart';
import 'package:test/test.dart';
import 'package:json_stream_parser/utilities/stream_text_in_chunks.dart';

/// Enable verbose logging to debug test execution
const bool verbose = false;

void main() {
  group('Boolean Property Tests', () {
    test('true value', () async {
      if (verbose) print('\n[TEST] True value');

      final json = '{"active":true}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 3,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final activeStream = parser.getBooleanProperty("active");

      // For atomic values, stream should emit once
      final emittedValue = await activeStream.stream.first;
      if (verbose) print('[EMITTED] $emittedValue');

      // Verify future resolves to the same value
      final finalValue = await activeStream.future;
      if (verbose) print('[FINAL] $finalValue');

      expect(emittedValue, equals(true));
      expect(finalValue, equals(true));
    });

    test('false value', () async {
      if (verbose) print('\n[TEST] False value');

      final json = '{"disabled":false}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 4,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final disabledStream = parser.getBooleanProperty("disabled");

      final emittedValue = await disabledStream.stream.first;
      if (verbose) print('[EMITTED] $emittedValue');

      final finalValue = await disabledStream.future;
      if (verbose) print('[FINAL] $finalValue');

      expect(emittedValue, equals(false));
      expect(finalValue, equals(false));
    });

    test('nested boolean access', () async {
      if (verbose) print('\n[TEST] Nested boolean access');

      final json = '{"settings":{"enabled":true}}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final enabledStream = parser.getBooleanProperty("settings.enabled");

      final emittedValue = await enabledStream.stream.first;
      if (verbose) print('[EMITTED] $emittedValue');

      final finalValue = await enabledStream.future;
      if (verbose) print('[FINAL] $finalValue');

      expect(emittedValue, equals(true));
      expect(finalValue, equals(true));
    });

    test('deeply nested boolean access', () async {
      if (verbose) print('\n[TEST] Deeply nested boolean access');

      final json = '{"app":{"config":{"features":{"darkMode":false}}}}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 6,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final darkModeStream = parser.getBooleanProperty(
        "app.config.features.darkMode",
      );

      final emittedValue = await darkModeStream.stream.first;
      if (verbose) print('[EMITTED] $emittedValue');

      final finalValue = await darkModeStream.future;
      if (verbose) print('[FINAL] $finalValue');

      expect(emittedValue, equals(false));
      expect(finalValue, equals(false));
    });

    test('multiple boolean properties', () async {
      if (verbose) print('\n[TEST] Multiple boolean properties');

      final json = '{"flag1":true,"flag2":false,"flag3":true}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final flag1Stream = parser.getBooleanProperty("flag1");
      final flag2Stream = parser.getBooleanProperty("flag2");
      final flag3Stream = parser.getBooleanProperty("flag3");

      final flag1 = await flag1Stream.future;
      final flag2 = await flag2Stream.future;
      final flag3 = await flag3Stream.future;

      if (verbose) {
        print('[FINAL] flag1: $flag1');
        print('[FINAL] flag2: $flag2');
        print('[FINAL] flag3: $flag3');
      }

      expect(flag1, equals(true));
      expect(flag2, equals(false));
      expect(flag3, equals(true));
    });
  });
}
