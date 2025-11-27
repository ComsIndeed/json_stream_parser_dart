import 'dart:async';
import 'package:llm_json_stream/llm_json_stream.dart';

/// Example demonstrating the shorthand syntax methods for JsonStreamParser,
/// MapPropertyStream, and ListPropertyStream.
///
/// Shorthand methods provide a more concise way to access JSON properties:
/// - .str() instead of .getStringProperty()
/// - .number() instead of .getNumberProperty()
/// - .boolean() instead of .getBooleanProperty()
/// - .nil() instead of .getNullProperty()
/// - .map() instead of .getMapProperty()
/// - .list() instead of .getListProperty()
void main() async {
  print('=== Shorthand Syntax Example ===\n');

  // Example 1: Basic shorthand usage with JsonStreamParser
  await basicShorthandExample();

  // Example 2: Chaining shorthand methods with MapPropertyStream
  await chainingExample();

  // Example 3: Using shorthand with ListPropertyStream
  await listShorthandExample();

  print('\n=== All examples completed ===');
}

Future<void> basicShorthandExample() async {
  print('--- Example 1: Basic Shorthand with JsonStreamParser ---');

  final controller = StreamController<String>();
  final parser = JsonStreamParser(controller.stream);

  // Using shorthand methods instead of full names
  final title = parser.str('title'); // Instead of getStringProperty
  final count = parser.number('count'); // Instead of getNumberProperty
  final isActive = parser.boolean('isActive'); // Instead of getBooleanProperty
  final config = parser.map('config'); // Instead of getMapProperty
  final tags = parser.list('tags'); // Instead of getListProperty

  // Send JSON data
  controller.add('''{
    "title": "Hello World",
    "count": 42,
    "isActive": true,
    "config": {"theme": "dark"},
    "tags": ["new", "featured"]
  }''');
  controller.close();

  // Await the results
  print('Title: ${await title.future}');
  print('Count: ${await count.future}');
  print('Is Active: ${await isActive.future}');
  print('Config: ${await config.future}');
  print('Tags: ${await tags.future}');

  await parser.dispose();
  print('');
}

Future<void> chainingExample() async {
  print('--- Example 2: Chaining Shorthand Methods ---');

  final controller = StreamController<String>();
  final parser = JsonStreamParser(controller.stream);

  // Chain shorthand methods for nested access
  final user = parser.map('user'); // Get user map
  final name = user.str('name'); // Get name from user
  final age = user.number('age'); // Get age from user
  final isVerified = user.boolean('verified'); // Get verified status
  final profile = user.map('profile'); // Get nested profile map
  final bio = profile.str('bio'); // Get bio from profile

  controller.add('''{
    "user": {
      "name": "Alice",
      "age": 30,
      "verified": true,
      "profile": {
        "bio": "Software Developer"
      }
    }
  }''');
  controller.close();

  // Await the results
  print('Name: ${await name.future}');
  print('Age: ${await age.future}');
  print('Verified: ${await isVerified.future}');
  print('Bio: ${await bio.future}');

  await parser.dispose();
  print('');
}

Future<void> listShorthandExample() async {
  print('--- Example 3: Shorthand with Lists ---');

  final controller = StreamController<String>();
  final parser = JsonStreamParser(controller.stream);

  // Get a list and use shorthand methods within the onElement callback
  final items = parser.list('items');

  final collectedData = <String>[];

  items.onElement((element, index) {
    if (element is MapPropertyStream) {
      // Use shorthand methods on the map elements
      final name = element.str('name');
      final price = element.number('price');
      final available = element.boolean('available');

      // Collect the data
      Future.wait<Object?>([name.future, price.future, available.future])
          .then((values) {
        collectedData.add(
            'Item $index: ${values[0]}, \$${values[1]}, Available: ${values[2]}');
      });
    }
  });

  controller.add('''{
    "items": [
      {"name": "Widget", "price": 9.99, "available": true},
      {"name": "Gadget", "price": 19.99, "available": false}
    ]
  }''');
  controller.close();

  await items.future;
  await Future.delayed(Duration(milliseconds: 50)); // Wait for callbacks

  print('Collected items:');
  for (final item in collectedData) {
    print('  $item');
  }

  await parser.dispose();
  print('');
}
