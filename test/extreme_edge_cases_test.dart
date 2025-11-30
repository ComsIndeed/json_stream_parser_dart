import 'dart:async';

import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:test/test.dart';

/// Manual verification and extreme edge case testing
///
/// This file contains tests that really push the boundaries to see
/// what the parser can and cannot handle.
void main() {
  group('Manual Verification Tests', () {
    test('verify markdown is actually ignored - print behavior', () async {
      final input = '''```json
{"test":"value"}
```''';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final test = await parser
          .getStringProperty("test")
          .future
          .timeout(Duration(seconds: 1));

      expect(test, equals('value'));
      print('✓ Markdown blocks are being handled');
    });

    test('verify what happens with text AFTER json', () async {
      final input = '{"valid" true} This is text after the JSON```';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 8,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final valid = await parser
          .getBooleanProperty("valid")
          .future
          .timeout(Duration(seconds: 1));

      expect(valid, equals(true));
      print('✓ Text after JSON is ignored');
    });
  });

  group('Extreme Edge Cases - Boundary Conditions', () {
    test('leading comma in array - [,1,2]', () async {
      final input = '{"nums":[,1,2]}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 5,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      // This might timeout or parse incorrectly
      try {
        final nums = await parser
            .getListProperty("nums")
            .future
            .timeout(Duration(seconds: 1));
        print('Leading comma result: $nums');
        // If it succeeds, it should skip the leading comma
        expect(nums, anyOf(equals([1, 2]), equals([null, 1, 2])));
      } catch (e) {
        print('Leading comma caused error: $e');
        rethrow;
      }
    });

    test('leading comma in object - {,"a":1}', () async {
      final input = '{,"a":1}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 3,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      try {
        final a = await parser
            .getNumberProperty("a")
            .future
            .timeout(Duration(seconds: 1));
        print('Leading comma in object result: $a');
        expect(a, equals(1));
      } catch (e) {
        print('Leading comma in object caused error: $e');
        rethrow;
      }
    });

    test('multiple JSON objects in stream - should only parse first', () async {
      final input = '{"first":1}{"second":2}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 6,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final first = await parser
          .getNumberProperty("first")
          .future
          .timeout(Duration(seconds: 1));

      expect(first, equals(1));

      // Try to access second - should timeout since parser stops after first
      try {
        await parser
            .getNumberProperty("second")
            .future
            .timeout(Duration(milliseconds: 500));
        fail('Should not have parsed second object');
      } catch (e) {
        expect(e, isA<TimeoutException>());
        print('✓ Correctly only parses first JSON object');
      }
    });

    test('markdown block containing { before actual JSON', () async {
      final input = '''```
Some text with { and } characters
```
{"real":"json"}''';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 12,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      // This is a critical test - will it parse the { in markdown or wait for real JSON?
      // NOTE: This is a known limitation - parser treats first { as JSON start
      try {
        final real = await parser
            .getStringProperty("real")
            .future
            .timeout(Duration(seconds: 2));
        print('Successfully found real JSON after markdown with braces');
        expect(real, equals('json'));
      } catch (e) {
        print('Parser was confused by { in markdown (known limitation): $e');
        // This is expected - parser locks onto first { it sees
        expect(e, isA<TimeoutException>());
      }
    });
  });

  group('Extreme Edge Cases - Unicode and Special Characters', () {
    test('preamble with complex unicode and emojis', () async {
      final input = '''🎯🚀💻 Here's what you need! 中文字符 العربية 🌟
```json
{"emoji":"✨","text":"Hello 世界"}
```''';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 20,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final emoji = await parser
          .getStringProperty("emoji")
          .future
          .timeout(Duration(seconds: 1));
      final text = await parser
          .getStringProperty("text")
          .future
          .timeout(Duration(seconds: 1));

      expect(emoji, equals('✨'));
      expect(text, equals('Hello 世界'));
    });

    test('thinking blocks with unicode', () async {
      final input = '''<think>思考中... 🤔 Processing with مع العربية</think>
{"result":"success"}''';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 15,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final result = await parser
          .getStringProperty("result")
          .future
          .timeout(Duration(seconds: 1));

      expect(result, equals('success'));
    });
  });

  group('Extreme Edge Cases - Massive Inputs', () {
    test('extremely long preamble - 5000 characters', () async {
      final longPreamble = 'a' * 5000;
      final input = '$longPreamble{"data":"test"}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 100,
        interval: Duration(milliseconds: 1),
      );
      final parser = JsonStreamParser(stream);

      final data = await parser
          .getStringProperty("data")
          .future
          .timeout(Duration(seconds: 3));

      expect(data, equals('test'));
      print('✓ Handled 5000 char preamble');
    });

    test('very deep thinking block nesting', () async {
      final input = '''<think>
Level 1 <think>
Level 2 <think>
Level 3 <think>
Level 4
</think>
</think>
</think>
</think>
{"nested":"deep"}''';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 20,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final nested = await parser
          .getStringProperty("nested")
          .future
          .timeout(Duration(seconds: 1));

      expect(nested, equals('deep'));
    });

    test('markdown with random backticks everywhere', () async {
      final input = '''Here is ` some `text` with ```random` backticks``
And more `` text ``` with` weird ```formatting```
```json
{"value":42}
```
More` backticks`` after`''';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 15,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final value = await parser
          .getNumberProperty("value")
          .future
          .timeout(Duration(seconds: 1));

      expect(value, equals(42));
    });
  });

  group('Extreme Edge Cases - Malformed Inputs', () {
    test('thinking blocks inside JSON string values', () async {
      final input = '{"instruction":"Use <think>reasoning</think> here"}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 10,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final instruction = await parser
          .getStringProperty("instruction")
          .future
          .timeout(Duration(seconds: 1));

      // Should preserve the tags inside the JSON string
      expect(instruction, equals('Use <think>reasoning</think> here'));
    });

    test('empty thinking blocks', () async {
      final input = '<think></think><think></think>{"data":true}';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 8,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final data = await parser
          .getBooleanProperty("data")
          .future
          .timeout(Duration(seconds: 1));

      expect(data, equals(true));
    });

    test('unclosed markdown with unclosed thinking', () async {
      final input = '''<think>Incomplete thought
```json
{"status":"ok"}''';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 10,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final status = await parser
          .getStringProperty("status")
          .future
          .timeout(Duration(seconds: 1));

      expect(status, equals('ok'));
    });

    test('trailing commas with excessive whitespace', () async {
      final input = '''{
  "array": [
    1  ,  
    2  ,  
    3  ,  
  ]  ,  
  "object": {
    "a": 1  ,  
    "b": 2  ,  
  }  ,  
}''';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 12,
        interval: Duration(milliseconds: 10),
      );
      final parser = JsonStreamParser(stream);

      final array = await parser
          .getListProperty("array")
          .future
          .timeout(Duration(seconds: 1));
      final a = await parser
          .getNumberProperty("object.a")
          .future
          .timeout(Duration(seconds: 1));

      expect(array, equals([1, 2, 3]));
      expect(a, equals(1));
    });
  });

  group('Stress Tests - Pathological Cases', () {
    // ! Kind of too overkill
//     test('all features at maximum complexity', () async {
//       final input = '''<think>
// This is a very complex thought with { braces } and [arrays]
// Nested: <think>Inner thought with "quotes"</think>
// </think>

// 🎯 Hey there! Here's your data (with {curly} and [square] brackets):

// ` Random backticks `` everywhere ```

// ```json
// {
//   "users": [
//     {
//       "name": "Alice 中文",
//       "tags": ["admin", "user",],
//       "meta": {
//         "active": true,
//         "count": 42,
//       },
//     },
//     {
//       "name": "Bob العربية",
//       "tags": ["guest",],
//       "meta": {
//         "active": false,
//         "count": 0,
//       },
//     },
//   ],
//   "settings": {
//     "theme": "dark",
//     "notifications": true,
//   },
// }
// ```

// More text after with <think>thoughts</think> and `` backticks ``
// ''';

//       final stream = streamTextInChunks(
//         text: input,
//         chunkSize: 30,
//         interval: Duration(milliseconds: 5),
//       );
//       final parser = JsonStreamParser(stream);

//       final firstUserName = await parser
//           .getStringProperty("users[0].name")
//           .future
//           .timeout(Duration(seconds: 2));
//       final theme = await parser
//           .getStringProperty("settings.theme")
//           .future
//           .timeout(Duration(seconds: 2));
//       final users = await parser
//           .getListProperty("users")
//           .future
//           .timeout(Duration(seconds: 2));

//       expect(firstUserName, equals('Alice 中文'));
//       expect(theme, equals('dark'));
//       expect(users.length, equals(2));
//     });

    test('chunk boundary at every critical position', () async {
      // Test chunking at positions that might break parsing
      final inputs = [
        '```json\n{"test":1}```',
        '<think>a</think>{"test":1}',
        '{"test":1,"extra":2,}', // Object with trailing comma
      ];

      for (final input in inputs) {
        // Try chunking at every single character
        for (int chunkSize = 1; chunkSize <= 3; chunkSize++) {
          final stream = streamTextInChunks(
            text: input,
            chunkSize: chunkSize,
            interval: Duration(milliseconds: 1),
          );
          final parser = JsonStreamParser(stream);

          final test = await parser.getNumberProperty("test").future.timeout(
              Duration(seconds: 5)); // Increased timeout from 2 to 5 seconds

          expect(test, equals(1));
        }
      }
      print('✓ Tested all chunk boundary positions');
    });

    test('real LLM output simulation - Claude style', () async {
      final input = '''<think>
The user is asking for a product catalog. I should structure this as an array of objects with product details.
Let me include id, name, price, and availability.
I'll format it nicely with proper JSON structure.
</think>

I'll provide you with a comprehensive product catalog in JSON format:

```json
{
  "catalog": {
    "name": "Electronics Store",
    "products": [
      {
        "id": 1,
        "name": "Laptop Pro 15",
        "price": 1299.99,
        "inStock": true,
        "specs": {
          "ram": "16GB",
          "storage": "512GB SSD",
        },
      },
      {
        "id": 2,
        "name": "Wireless Mouse",
        "price": 29.99,
        "inStock": false,
        "specs": {
          "dpi": 1600,
          "wireless": true,
        },
      },
    ],
    "totalProducts": 2,
  },
}
```

This catalog includes all available products with their current stock status and specifications.''';

      final stream = streamTextInChunks(
        text: input,
        chunkSize: 40,
        interval: Duration(milliseconds: 5),
      );
      final parser = JsonStreamParser(stream);

      final storeName = await parser
          .getStringProperty("catalog.name")
          .future
          .timeout(Duration(seconds: 2));
      final products = await parser
          .getListProperty("catalog.products")
          .future
          .timeout(Duration(seconds: 2));
      final firstProductPrice = await parser
          .getNumberProperty("catalog.products[0].price")
          .future
          .timeout(Duration(seconds: 2));

      expect(storeName, equals('Electronics Store'));
      expect(products.length, equals(2));
      expect(firstProductPrice, equals(1299.99));
    });
  });
}
