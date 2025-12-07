# Utilities

Helper functions for testing and development.

## streamTextInChunks

A utility function that simulates streaming by breaking a string into chunks 
with optional delays between them. Useful for testing your streaming JSON handling.

```dart
import 'package:llm_json_stream/llm_json_stream.dart';

void main() async {
  final json = '{"name": "Alice", "age": 30}';
  
  // Stream with 5-character chunks, 100ms delay between chunks
  final stream = streamTextInChunks(
    json,
    chunkSize: 5,
    interval: Duration(milliseconds: 100),
  );
  
  final parser = JsonStreamParser(stream);
  final name = await parser.getStringProperty('name').future;
  print(name); // "Alice"
}
```

### Parameters

- **`text`**: The complete text to stream
- **`chunkSize`**: Number of characters per chunk (default: 10)
- **`interval`**: Delay between chunks (default: 10ms)

This is especially useful for:

- Unit testing streaming behavior
- Simulating LLM responses locally
- Debugging chunk boundary issues
