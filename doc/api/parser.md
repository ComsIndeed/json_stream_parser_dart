# Parser

The core parsing engine that processes streaming JSON data character-by-character.

## JsonStreamParser

The main entry point for using this library. Create a parser by passing a `Stream<String>` 
(typically from an LLM API response) and then subscribe to properties using the getter methods.

### Key Features

- **Character-by-character parsing**: Processes JSON as it arrives, no buffering required
- **Path-based subscriptions**: Access any property using dot notation (`user.profile.name`)
- **Yap filter**: Automatically stops parsing after root JSON completes (handles trailing LLM text)
- **Observability**: Optional logging callbacks for debugging

### Example

```dart
final parser = JsonStreamParser(llmStream, closeOnRootComplete: true);

// Subscribe to a nested string property
parser.getStringProperty('user.name').stream.listen((chunk) {
  print('Name chunk: $chunk');
});

// Wait for a complete value
final age = await parser.getNumberProperty('user.age').future;

// Clean up when done
await parser.dispose();
```

See the [JsonStreamParser] class documentation for full API details.
