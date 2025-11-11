import 'package:json_stream_parser/classes/json_stream_parser.dart';
import 'package:test/test.dart';
import 'package:json_stream_parser/utilities/stream_text_in_chunks.dart';

import 'list_property_test.dart';

/// Enable verbose logging to debug test execution
const bool verbose = false;

// TODO: HANDLE ESCAPE SEQUENCES IN STRINGS MORE CLEARLY
// I am unsure if the test expectations should have the actual escape characters interpreted
// (e.g., \n as newline) or kept as literal sequences (e.g., \n as backslash + n).
// Otherwise, the tests are passing but may not reflect intended behavior.

void main() {
  group('String Property Tests', () {
    test('simple string value', () async {
      if (verbose) print('\n[TEST] Simple string value');

      final json = '{"name":"Alice"}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 3,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final nameStream = parser.getStringProperty("name");

      // Accumulate stream chunks
      final chunks = <String>[];
      nameStream.stream.listen((chunk) {
        if (verbose) print('[CHUNK] "$chunk"');
        chunks.add(chunk);
      });

      // Wait for completion
      final finalValue = await nameStream.future.withTestTimeout();
      if (verbose) print('[FINAL] $finalValue');

      // Verify accumulated chunks form the complete value
      expect(chunks.join(''), equals('Alice'));

      // Verify future resolves to complete value
      expect(finalValue, equals('Alice'));
    });

    test('string with escape sequences - newline', () async {
      if (verbose) print('\n[TEST] String with newline escape');

      // JSON with \n escape sequence should produce an actual newline character
      final json = '{"text":"Hello\\nWorld"}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 4,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final textStream = parser.getStringProperty("text");

      final chunks = <String>[];
      textStream.stream.listen((chunk) {
        if (verbose) print('[CHUNK] "$chunk"');
        chunks.add(chunk);
      });

      final finalValue = await textStream.future.withTestTimeout();
      if (verbose) print('[FINAL] $finalValue');

      expect(chunks.join(''), equals('Hello\nWorld'));
      expect(finalValue, equals('Hello\nWorld'));
    });

    test('string with escape sequences - tab', () async {
      if (verbose) print('\n[TEST] String with tab escape');

      // JSON with \t escape sequence should produce an actual tab character
      final json = '{"text":"Hello\\tWorld"}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 3,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final textStream = parser.getStringProperty("text");

      final chunks = <String>[];
      textStream.stream.listen((chunk) {
        if (verbose) print('[CHUNK] "$chunk"');
        chunks.add(chunk);
      });

      final finalValue = await textStream.future.withTestTimeout();
      if (verbose) print('[FINAL] $finalValue');

      expect(chunks.join(''), equals('Hello\tWorld'));
      expect(finalValue, equals('Hello\tWorld'));
    });

    test('string with escaped quotes inside', () async {
      if (verbose) print('\n[TEST] String with escaped quotes');

      // JSON with \" escape sequences should produce actual quote characters
      final json = '{"quote":"She said \\"Hi\\""}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final quoteStream = parser.getStringProperty("quote");

      final chunks = <String>[];
      quoteStream.stream.listen((chunk) {
        if (verbose) print('[CHUNK] "$chunk"');
        chunks.add(chunk);
      });

      final finalValue = await quoteStream.future.withTestTimeout();
      if (verbose) print('[FINAL] $finalValue');

      expect(chunks.join(''), equals('She said "Hi"'));
      expect(finalValue, equals('She said "Hi"'));
    });

    test('string with backslashes', () async {
      if (verbose) print('\n[TEST] String with backslashes');

      final json = '{"path":"C:\\\\Users\\\\file"}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 4,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final pathStream = parser.getStringProperty("path");

      final chunks = <String>[];
      pathStream.stream.listen((chunk) {
        if (verbose) print('[CHUNK] "$chunk"');
        chunks.add(chunk);
      });

      final finalValue = await pathStream.future.withTestTimeout();
      if (verbose) print('[FINAL] $finalValue');

      expect(chunks.join(''), equals('C:\\Users\\file'));
      expect(finalValue, equals('C:\\Users\\file'));
    });

    test('empty string', () async {
      if (verbose) print('\n[TEST] Empty string');

      final json = '{"empty":""}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 3,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final emptyStream = parser.getStringProperty("empty");

      final chunks = <String>[];
      emptyStream.stream.listen((chunk) {
        if (verbose) print('[CHUNK] "$chunk"');
        chunks.add(chunk);
      });

      final finalValue = await emptyStream.future.withTestTimeout();
      if (verbose) print('[FINAL] "$finalValue"');

      expect(chunks.join(''), equals(''));
      expect(finalValue, equals(''));
    });

    test('string with Unicode/emoji', () async {
      if (verbose) print('\n[TEST] String with Unicode');

      final json = '{"emoji":"👋🌍"}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 3,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final emojiStream = parser.getStringProperty("emoji");

      final chunks = <String>[];
      emojiStream.stream.listen((chunk) {
        if (verbose) print('[CHUNK] "$chunk"');
        chunks.add(chunk);
      });

      final finalValue = await emojiStream.future.withTestTimeout();
      if (verbose) print('[FINAL] $finalValue');

      expect(chunks.join(''), equals('👋🌍'));
      expect(finalValue, equals('👋🌍'));
    });

    test('nested string access with dot notation', () async {
      if (verbose) print('\n[TEST] Nested string access');

      final json = '{"user":{"name":"Bob"}}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 4,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final nameStream = parser.getStringProperty("user.name");

      final chunks = <String>[];
      nameStream.stream.listen((chunk) {
        if (verbose) print('[CHUNK] "$chunk"');
        chunks.add(chunk);
      });

      final finalValue = await nameStream.future.withTestTimeout();
      if (verbose) print('[FINAL] $finalValue');

      expect(chunks.join(''), equals('Bob'));
      expect(finalValue, equals('Bob'));
    });

    test('deeply nested string access', () async {
      if (verbose) print('\n[TEST] Deeply nested string access');

      final json = '{"auth":{"user":{"profile":{"name":"Charlie"}}}}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final nameStream = parser.getStringProperty("auth.user.profile.name");

      final chunks = <String>[];
      nameStream.stream.listen((chunk) {
        if (verbose) print('[CHUNK] "$chunk"');
        chunks.add(chunk);
      });

      final finalValue = await nameStream.future.withTestTimeout();
      if (verbose) print('[FINAL] $finalValue');

      expect(chunks.join(''), equals('Charlie'));
      expect(finalValue, equals('Charlie'));
    });

    test('string with multiple escape sequences', () async {
      if (verbose) print('\n[TEST] String with multiple escapes');

      final json = '{"msg":"Line1\\nLine2\\tTabbed\\r\\nLine3"}';
      if (verbose) print('[JSON] $json');

      final stream = streamTextInChunks(
        text: json,
        chunkSize: 6,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final msgStream = parser.getStringProperty("msg");

      final chunks = <String>[];
      msgStream.stream.listen((chunk) {
        if (verbose) print('[CHUNK] "$chunk"');
        chunks.add(chunk);
      });

      final finalValue = await msgStream.future.withTestTimeout();
      if (verbose) print('[FINAL] $finalValue');

      expect(chunks.join(''), equals('Line1\nLine2\tTabbed\r\nLine3'));
      expect(finalValue, equals('Line1\nLine2\tTabbed\r\nLine3'));
    });
  });
}
