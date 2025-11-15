import 'dart:async';
import 'package:json_stream_parser/json_stream_parser.dart';

/// Example demonstrating:
/// 1. Setting onElement callbacks on nested lists via getListProperty()
/// 2. Proper disposal of the parser to prevent memory leaks
void main() async {
  print('=== Nested List onElement Callback Example ===\n');
  await nestedListExample();

  print('\n=== Parser Disposal Example ===\n');
  await disposalExample();
}

/// Demonstrates setting onElement callbacks on nested lists
Future<void> nestedListExample() async {
  final json = '''
  {
    "departments": [
      {
        "name": "Engineering",
        "employees": [
          {"id": 1, "name": "Alice"},
          {"id": 2, "name": "Bob"}
        ]
      },
      {
        "name": "Marketing",
        "employees": [
          {"id": 3, "name": "Carol"},
          {"id": 4, "name": "David"}
        ]
      }
    ]
  }
  ''';

  final controller = StreamController<String>();
  final parser = JsonStreamParser(controller.stream);

  // Get the departments list and set onElement callback
  final departmentsList = parser.getListProperty(
    'departments',
    onElement: (deptStream, deptIndex) {
      print('📁 Department $deptIndex discovered!');

      if (deptStream is MapPropertyStream) {
        // Get department name
        deptStream.getStringProperty('name').future.then((name) {
          print('   Department name: $name');
        });

        // Get employees list with its own onElement callback
        deptStream.getListProperty(
          'employees',
          onElement: (empStream, empIndex) {
            print(
                '   👤 Employee $empIndex discovered in department $deptIndex');

            if (empStream is MapPropertyStream) {
              empStream.getStringProperty('name').future.then((empName) {
                print('      Employee name: $empName');
              });
            }
          },
        );
      }
    },
  );

  // Stream the JSON
  controller.add(json);
  await controller.close();

  // Wait for completion
  await departmentsList.future;

  // Clean up
  await parser.dispose();
  print('✓ Parser disposed successfully');
}

/// Demonstrates proper parser disposal
Future<void> disposalExample() async {
  final json = '{"title": "My Document", "version": 1.5, "published": true}';

  final controller = StreamController<String>();
  final parser = JsonStreamParser(controller.stream);

  // Subscribe to properties
  final titleStream = parser.getStringProperty('title');
  final versionStream = parser.getNumberProperty('version');
  final publishedStream = parser.getBooleanProperty('published');

  // Listen to the title stream chunks
  titleStream.stream.listen((chunk) {
    print('Title chunk received: "$chunk"');
  });

  // Stream the JSON
  controller.add(json);
  await controller.close();

  // Wait for all properties to complete
  final title = await titleStream.future;
  final version = await versionStream.future;
  final published = await publishedStream.future;

  print('\nFinal values:');
  print('  Title: $title');
  print('  Version: $version');
  print('  Published: $published');

  // Dispose the parser to clean up resources
  await parser.dispose();
  print('\n✓ Parser disposed - all resources cleaned up');
}
