# Observability

Monitor and debug the parsing process with logging callbacks.

## ParseEvent

The `ParseEvent` class represents a parsing event with:

- **`type`**: The event type (see `ParseEventType`)
- **`propertyPath`**: The JSON path where the event occurred
- **`message`**: A human-readable description
- **`data`**: Optional additional data

## Event Types

`ParseEventType` includes:

| Type | Description |
|------|-------------|
| `rootStart` | Root JSON object/array started |
| `mapKeyDiscovered` | New object key found |
| `listElementStart` | New array element started |
| `propertyStart` | Property parsing began |
| `propertyComplete` | Property parsing finished |
| `stringChunk` | String chunk emitted |
| `yapFiltered` | Trailing text was filtered out |
| `error` | Parsing error occurred |

## Usage

### Global Logging

```dart
final parser = JsonStreamParser(stream, onLog: (event) {
  print('[${event.type}] ${event.propertyPath}: ${event.message}');
});
```

### Property-Specific Logging

```dart
parser.getMapProperty('user').onLog((event) {
  // Only receives events for 'user' and its descendants
  print('User event: ${event.type}');
});
```

## Example Output

```
[rootStart] : Root object started
[mapKeyDiscovered] : Discovered key "name"
[propertyStart] name: Started parsing string
[stringChunk] name: Emitted chunk "Alice"
[propertyComplete] name: Completed with value "Alice"
[yapFiltered] : Yap filter triggered
```
