import 'dart:async';
import 'package:llm_json_stream/json_stream_parser.dart';

/// Example demonstrating how to use JsonStreamParser for parsing streaming JSON.
///
/// This simulates an LLM streaming response that generates JSON progressively.
/// The parser allows you to subscribe to specific properties and receive values
/// as they complete in the stream.
void main() async {
  print('JSON Stream Parser Example\n');

  // Example 1: Basic property subscription
  await basicExample();

  print('\n---\n');

  // Example 2: Nested objects
  await nestedExample();

  print('\n---\n');

  // Example 3: Arrays and dynamic elements
  await arrayExample();
}

/// Example 1: Subscribe to properties as they complete in the stream
Future<void> basicExample() async {
  print('Example 1: Basic Property Subscription');

  // Simulate an LLM streaming this JSON:
  // {"status": "success", "name": "Alice", "age": 30}
  final jsonStream = _simulateStream(
    '{"status": "success", "name": "Alice", "age": 30}',
    chunkSize: 5,
  );

  final parser = JsonStreamParser(jsonStream);

  // Subscribe to properties - these will fire as soon as each property completes
  parser.getStringProperty('status').stream.listen((status) {
    print('  Status: $status');
  });

  parser.getStringProperty('name').stream.listen((name) {
    print('  Name: $name');
  });

  // You can also await the complete value
  final age = await parser.getNumberProperty('age').future;
  print('  Age: $age');
}

/// Example 2: Access nested properties with chainable API
Future<void> nestedExample() async {
  print('Example 2: Nested Objects');

  // Simulate streaming: {"user": {"name": "Bob", "email": "bob@example.com"}}
  final jsonStream = _simulateStream(
    '{"user": {"name": "Bob", "email": "bob@example.com"}, "message": "Hello"}',
    chunkSize: 8,
  );

  final parser = JsonStreamParser(jsonStream);

  // Option 1: Direct path notation
  final nameStream = parser.getStringProperty('user.name');
  nameStream.stream.listen((name) {
    print('  User name (direct path): $name');
  });

  // Option 2: Chainable API
  final userMap = parser.getMapProperty('user');
  final emailStream = userMap.getStringProperty('email');

  final email = await emailStream.future;
  print('  User email (chained): $email');

  final message = await parser.getStringProperty('message').future;
  print('  Message: $message');
}

/// Example 3: Work with arrays using onElement callback
Future<void> arrayExample() async {
  print('Example 3: Arrays and Dynamic Elements');

  // Simulate streaming: {"items": [{"id": 1, "name": "Item 1"}, {"id": 2, "name": "Item 2"}]}
  final jsonStream = _simulateStream(
    '{"items": [{"id": 1, "name": "Item 1"}, {"id": 2, "name": "Item 2"}]}',
    chunkSize: 10,
  );

  final parser = JsonStreamParser(jsonStream);

  // Get the items array
  final itemsStream = parser.getListProperty('items');

  // "Arm the trap" - this callback fires immediately when each element is discovered
  itemsStream.onElement((element, index) {
    print('  Found element at index $index');

    // Subscribe to properties of this element before it's even parsed
    if (element is MapPropertyStream) {
      element.getNumberProperty('id').future.then((id) {
        print('    -> Item $index ID: $id');
      });

      element.getStringProperty('name').stream.listen((name) {
        print('    -> Item $index Name: $name');
      });
    }
  });

  // You can also await the complete array
  final items = await itemsStream.future;
  print('  Complete array: $items');
}

/// Helper function to simulate a streaming response
///
/// In a real application, this would be your LLM API stream
Stream<String> _simulateStream(String text, {int chunkSize = 1}) async* {
  for (var i = 0; i < text.length; i += chunkSize) {
    final end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
    final chunk = text.substring(i, end);
    yield chunk;
    // Small delay to simulate streaming
    await Future.delayed(Duration(milliseconds: 10));
  }
}
