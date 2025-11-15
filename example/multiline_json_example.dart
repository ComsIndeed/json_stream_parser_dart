import 'package:streaming_json_parser/json_stream_parser.dart';

/// Example demonstrating parsing of multiline JSON strings.
/// This is especially useful when working with triple-quoted strings in Dart.
void main() async {
  // Using triple-quoted string syntax creates actual newline characters
  // This was previously buggy but is now fixed!
  final json = '''
{
  "status": "success",
  "data": {
    "id": 123,
    "name": "Sample Item",
    "description": "This is a sample item from the API response.",
    "attributes": {
      "color": "red",
      "size": "large",
      "weight": "1.5kg"
    }
  },
  "message": "Item retrieved successfully."
}
''';

  print('Parsing multiline JSON...\n');

  // Create a character stream from the JSON string
  final stream = Stream.fromIterable(json.split(''));
  final parser = JsonStreamParser(stream);

  // Subscribe to properties as they become available
  parser.getStringProperty("status").stream.listen((status) {
    print('Status: $status');
  });

  parser.getNumberProperty("data.id").future.then((id) {
    print('ID: $id');
  });

  parser.getStringProperty("data.name").future.then((name) {
    print('Name: $name');
  });

  parser.getStringProperty("data.attributes.color").future.then((color) {
    print('Color: $color');
  });

  parser.getStringProperty("message").future.then((message) {
    print('Message: $message');
  });

  // Wait for the root map to complete
  final rootMap = await parser.getMapProperty("").future;
  print('\n✅ Parsing complete!');
  print('Full parsed object: $rootMap');
}
