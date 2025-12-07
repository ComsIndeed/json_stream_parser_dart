# Property Streams

Property streams provide reactive access to JSON values as they are parsed.

## Overview

Each JSON value type has a corresponding property stream class:

| JSON Type | Property Stream | Key Features |
|-----------|-----------------|--------------|
| String | `StringPropertyStream` | Chunked streaming, buffered replay |
| Number | `NumberPropertyStream` | Atomic value emission |
| Boolean | `BooleanPropertyStream` | Atomic value emission |
| Null | `NullPropertyStream` | Atomic value emission |
| Array | `ListPropertyStream` | Incremental updates, `onElement` callback |
| Object | `MapPropertyStream` | Incremental updates, `onProperty` callback |

## Common API

All property streams inherit from `PropertyStream` and provide:

- **`.future`**: A `Future` that completes with the final parsed value
- **`.stream`**: A broadcast stream that emits values (buffered for late subscribers)
- **`.onLog()`**: Register callbacks for parsing events

## String Streaming

`StringPropertyStream` is special because it emits **chunks** as they arrive:

```dart
final title = parser.getStringProperty('title');

// Receive chunks as they stream in
title.stream.listen((chunk) {
  displayedText += chunk; // Build up the string incrementally
});

// Or wait for the complete value
final fullTitle = await title.future;
```

## Collection Streaming

`MapPropertyStream` and `ListPropertyStream` support reactive callbacks:

```dart
// React to new array elements
parser.getListProperty('items').onElement((element, index) {
  print('Element $index started parsing');
});

// React to new object properties  
parser.getMapProperty('user').onProperty((property, key) {
  print('Property "$key" started parsing');
});
```

## Buffered vs Unbuffered

Property streams offer two stream variants:

- **`.stream`** (recommended): Replays buffered content to late subscribers
- **`.unbufferedStream`**: Only emits new values, no replay

Use `.stream` to avoid race conditions when subscribing after parsing begins.
