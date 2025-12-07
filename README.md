<div align="center">

# LLM JSON Stream

**The streaming JSON parser for AI applications**

[![pub package](https://img.shields.io/pub/v/llm_json_stream.svg)](https://pub.dev/packages/llm_json_stream)
[![Tests](https://img.shields.io/badge/tests-504%20passing-brightgreen)]()
[![Dart](https://img.shields.io/badge/dart-%3E%3D3.0.0-blue)]()
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](LICENSE)

Parse JSON reactively as LLM responses stream in. Subscribe to properties and receive values chunk-by-chunk  as they're generated—no waiting for the complete response.

![Hero demo showing a Flutter app with streaming JSON properties being parsed and displayed in real-time](https://raw.githubusercontent.com/ComsIndeed/llm_json_stream/main/assets/demo/hero.gif)

[**Live Demo**](https://comsindeed.github.io/json_stream_parser_demo/) · [**API Docs**](https://pub.dev/documentation/llm_json_stream/latest/) · [**GitHub**](https://github.com/ComsIndeed/llm_json_stream)

</div>

## Table of Contents

- [The Problem](#the-problem)
- [The Solution](#the-solution)
- [Quick Start](#quick-start)
- [How It Works](#how-it-works)
- [Feature Highlights](#feature-highlights)
  - [Streaming Strings](#-streaming-strings)
  - [Reactive Lists](#-reactive-lists)
  - [Reactive Maps](#-reactive-maps)
  - [All JSON Types](#-all-json-types)
  - [Flexible API](#️-flexible-api)
  - [Smart Casts](#-smart-casts)
  - [Buffered vs Unbuffered Streams](#-buffered-vs-unbuffered-streams)
  - [Yap Filter](#-yap-filter-closeOnRootComplete)
  - [Observability](#-observability)
- [Complete Example](#complete-example)
- [API Reference](#api-reference)
- [Robustness](#robustness)
- [LLM Provider Setup](#llm-provider-setup)
- [Contributing](#contributing)
- [License](#license)

---

## The Problem

LLM APIs stream responses token-by-token. When the response is JSON, you get incomplete fragments:

![LLM JSON chunks arriving incomplete, showing how traditional JSON parsers break on partial objects](https://raw.githubusercontent.com/ComsIndeed/llm_json_stream/main/assets/demo/problem.gif)

**`jsonDecode()` fails on partial JSON.** Your options aren't great:

| Approach | Problem |
|----------|---------|
| Wait for complete response | High latency, defeats streaming |
| Display raw chunks | Broken JSON in your UI |
| Build a custom parser | Complex, error-prone, weeks of work |

## The Solution

LLM JSON Stream parses JSON **character-by-character** as it arrives, allowing you to subscribe to specific properties and react to their values the moment they're available.

Instead of waiting for the entire JSON response to complete, you can:
- Display text fields progressively as they stream in
- Add list items to your UI the instant they begin parsing
- Await complete values for properties that need them (like IDs or flags)

![Comparison showing traditional loading vs smooth streaming](https://raw.githubusercontent.com/ComsIndeed/llm_json_stream/main/assets/demo/comparison.gif)

---

## Quick Start

```yaml
# pubspec.yaml
dependencies:
  llm_json_stream: ^0.4.0  # Check pub.dev for latest version
```

```dart
import 'package:llm_json_stream/llm_json_stream.dart';

final parser = JsonStreamParser(llmResponseStream);

// Stream text as it types
parser.getStringProperty('message').stream.listen((chunk) {
  displayText += chunk;  // Update UI character-by-character
});

// Or get the complete value
final title = await parser.getStringProperty('title').future;

// Clean up when done
await parser.dispose();
```

---

## How It Works

### Two APIs for Every Property

Every property gives you both a **stream** (incremental updates) and a **future** (complete value):

```dart
final title = parser.getStringProperty('title');

title.stream.listen((chunk) => ...);  // Each chunk as it arrives
final complete = await title.future;   // The final value
```

| Use case | API |
|----------|-----|
| Typing effect, live updates | `.stream` |
| Atomic values (IDs, flags, counts) | `.future` |

### Path Syntax

Navigate JSON with dot notation and array indices:

```dart
parser.getStringProperty('title')                    // Root property
parser.getStringProperty('user.name')                // Nested object
parser.getStringProperty('items[0].title')           // Array element
parser.getNumberProperty('data.users[2].age')        // Deep nesting
```

---

## Feature Highlights

### 🔤 Streaming Strings

Display text as the LLM generates it, creating a smooth typing effect:

![Streaming string property example](https://raw.githubusercontent.com/ComsIndeed/llm_json_stream/main/assets/demo/string-property-stream-2.gif)

```dart
parser.getStringProperty('response').stream.listen((chunk) {
  setState(() => displayText += chunk);
});
```

### 📋 Reactive Lists

An underrated but powerful feature. Add items to your UI **the instant parsing begins**—even before their content arrives:

![Reactive list example](https://raw.githubusercontent.com/ComsIndeed/llm_json_stream/main/assets/demo/list-onElement-string-streams.gif)

```dart
parser.getListProperty('articles').onElement((article, index) {
  // Fires IMMEDIATELY when "[{" is detected
  setState(() => articles.add(ArticleCard.loading()));
  
  // Fill in content as it streams
  article.asMap.getStringProperty('title').stream.listen((chunk) {
    setState(() => articles[index].title += chunk);
  });
});
```

**Traditional parsers** wait for complete objects → jarring UI jumps.  
**This approach** → smooth loading states that populate progressively.

### 🗺️ Reactive Maps

Similar to lists, maps support an `onProperty` callback that fires when each property starts parsing:

```dart
parser.getMapProperty('user').onProperty((property, key) {
  // Fires IMMEDIATELY when a property key is discovered
  print('Property "$key" started parsing');
  
  // Subscribe to the property value as it streams
  if (property is StringPropertyStream) {
    property.stream.listen((chunk) {
      setState(() => userFields[key] = (userFields[key] ?? '') + chunk);
    });
  }
});
```

This enables building reactive forms or detail views that populate field-by-field as data arrives.

### 🎯 All JSON Types

```dart
parser.getStringProperty('name')      // String → streams chunks
parser.getNumberProperty('age')       // Number → int or double
parser.getBooleanProperty('active')   // Boolean  
parser.getNullProperty('deleted')     // Null
parser.getMapProperty('config')       // Object → Map<String, dynamic>
parser.getListProperty('tags')        // Array → List<dynamic>
```

### ⛓️ Flexible API

Navigate complex structures with a fluent interface:

```dart
// Chain getters together
final user = parser.getMapProperty('user');
final name = await user.getStringProperty('name').future;
final email = await user.getStringProperty('email').future;

// Or go deep in one line
final city = await parser.map('user').map('address').str('city').future;

// Or be normal
final age = await parser.str('user.age').future;
```

### 🎭 Smart Casts

Handle dynamic list elements with type casts:

```dart
parser.getListProperty('items').onElement((element, index) {
  element.asMap.getStringProperty('title').stream.listen(...);
  element.asMap.getNumberProperty('price').future.then(...);
});
```

Available: `.asMap`, `.asList`, `.asStr`, `.asNum`, `.asBool`, `.asNull`

### 🔄 Buffered vs Unbuffered Streams

Property streams offer two modes to handle different subscription timing scenarios:

```dart
final items = parser.getListProperty('items');

// Recommended: Buffered stream (replays latest value to new subscribers)
items.stream.listen((list) {
  // Will receive the LATEST state immediately, then continue with live updates
  // Safe for late subscriptions - no race conditions!
});

// Alternative: Unbuffered stream (live only, no replay)
items.unbufferedStream.listen((list) {
  // Only receives values emitted AFTER subscription
  // Use when you explicitly want live-only behavior
});
```

| Stream Type | Behavior | Use Case |
|-------------|----------|----------|
| `.stream` | Replays latest value, then live | **Recommended** — prevents race conditions |
| `.unbufferedStream` | Live values only, no replay | When you need live-only behavior |

**Memory efficient**: Maps and Lists only buffer the latest state (O(1) memory), not the full history. Strings buffer chunks for accumulation.

This applies to `StringPropertyStream`, `MapPropertyStream`, and `ListPropertyStream`.

### 🛑 Yap Filter (closeOnRootComplete)

Some LLMs "yap" after the JSON—adding explanatory text that can confuse downstream processing. The `closeOnRootComplete` option stops parsing the moment the root JSON object/array is complete:

```dart
final parser = JsonStreamParser(
  llmStream,
  closeOnRootComplete: true,  // Stop after root JSON completes
);

// Input: '{"data": 123} Hope this helps! Let me know if you need anything else.'
// Parser stops after '}' — the trailing text is ignored
```

This is especially useful when:
- Your LLM tends to add conversational text after JSON
- You want to minimize processing overhead
- You're building a pipeline where only the JSON matters

### 📊 Observability

Monitor parsing events in real-time with the `onLog` callback. Useful for debugging, analytics, or building parsing visualizers:

```dart
final parser = JsonStreamParser(
  llmStream,
  onLog: (event) {
    print('[${event.type}] ${event.propertyPath}: ${event.message}');
  },
);

// Output:
// [rootStart] : Started parsing root object
// [mapKeyDiscovered] : Discovered key: name
// [propertyStart] name: Started parsing property: name (type: String)
// [stringChunk] name: Received string chunk
// [propertyComplete] name: Property completed: name
// [propertyComplete] : Map completed:
```

Available event types:
- `rootStart` — Root object/array parsing began
- `mapKeyDiscovered` — A new key was found in an object
- `listElementStart` — A new element was found in an array
- `propertyStart` — Property value parsing began
- `propertyComplete` — Property value parsing completed
- `stringChunk` — String chunk received
- `yapFiltered` — Parsing stopped due to yap filter

You can also attach log listeners to specific properties:

```dart
parser.getMapProperty('user').onLog((event) {
  // Only receives events for 'user' and its descendants
  print('User event: ${event.type}');
});
```

---

## Complete Example

A realistic scenario: parsing a blog post with streaming title and reactive sections.

```dart
import 'package:llm_json_stream/llm_json_stream.dart';

void main() async {
  // Your LLM stream (OpenAI, Claude, Gemini, etc.)
  final stream = llm.streamChat("Generate a blog post as JSON");
  
  final parser = JsonStreamParser(stream);
  
  // Title streams character-by-character
  parser.getStringProperty('title').stream.listen((chunk) {
    print(chunk);  // "H" "e" "l" "l" "o" " " "W" "o" "r" "l" "d"
  });
  
  // Sections appear the moment they start
  parser.getListProperty('sections').onElement((section, index) {
    print('Section $index detected!');
    
    section.asMap.getStringProperty('heading').stream.listen((chunk) {
      print('  Heading chunk: $chunk');
    });
    
    section.asMap.getStringProperty('body').stream.listen((chunk) {
      print('  Body chunk: $chunk');
    });
  });
  
  // Wait for completion
  final allSections = await parser.getListProperty('sections').future;
  print('Done! Got ${allSections.length} sections');
  
  await parser.dispose();
}
```

---

## API Reference

### Property Methods

| Shorthand | Full Name | Returns |
|-----------|-----------|---------|
| `.str(path)` | `.getStringProperty(path)` | `StringPropertyStream` |
| `.number(path)` | `.getNumberProperty(path)` | `NumberPropertyStream` |
| `.bool(path)` | `.getBooleanProperty(path)` | `BooleanPropertyStream` |
| `.nil(path)` | `.getNullProperty(path)` | `NullPropertyStream` |
| `.map(path)` | `.getMapProperty(path)` | `MapPropertyStream` |
| `.list(path)` | `.getListProperty(path)` | `ListPropertyStream` |

### PropertyStream Interface

```dart
.stream           // Stream<T> — buffered, replays past values to new subscribers
.unbufferedStream // Stream<T> — live only, no replay (available on String, Map, List)
.future           // Future<T> — completes with final value
```

### ListPropertyStream

```dart
.onElement((element, index) => ...)  // Callback when element parsing starts
```

### MapPropertyStream

```dart
.onProperty((property, key) => ...)  // Callback when property parsing starts
```

### Smart Casts

```dart
.asMap    // → MapPropertyStream
.asList   // → ListPropertyStream  
.asStr    // → StringPropertyStream
.asNum    // → NumberPropertyStream
.asBool   // → BooleanPropertyStream
```

### Cleanup

Always dispose the parser when you're done:

```dart
await parser.dispose();
```

### Constructor Options

```dart
JsonStreamParser(
  Stream<String> stream, {
  bool closeOnRootComplete = false,  // Stop parsing after root JSON completes
  void Function(ParseEvent)? onLog,  // Global log callback for all events
});
```

---

## Robustness

Battle-tested with **504 tests**. Handles real-world edge cases:

| Category | What's Covered |
|----------|----------------|
| **Escape sequences** | `\"`, `\\`, `\n`, `\t`, `\r`, `\uXXXX` |
| **Unicode** | Emoji 🎉, CJK characters, RTL text |
| **Numbers** | Scientific notation (`1.5e10`), negative, decimals |
| **Whitespace** | Multiline JSON, arbitrary formatting |
| **Nesting** | 5+ levels deep |
| **Scale** | 10,000+ element arrays |
| **Chunk boundaries** | Any size, splitting any token |
| **LLM quirks** | Trailing commas, markdown wrappers (auto-stripped) |

---

## LLM Provider Setup

<details>
<summary><strong>OpenAI</strong></summary>

```dart
final response = await openai.chat.completions.create(
  model: 'gpt-4',
  messages: messages,
  stream: true,
);

final jsonStream = response.map((chunk) => 
  chunk.choices.first.delta.content ?? ''
);

final parser = JsonStreamParser(jsonStream);
```

</details>

<details>
<summary><strong>Anthropic Claude</strong></summary>

```dart
final stream = anthropic.messages.stream(
  model: 'claude-3-opus',
  messages: messages,
);

final jsonStream = stream.map((event) => event.delta?.text ?? '');
final parser = JsonStreamParser(jsonStream);
```

</details>

<details>
<summary><strong>Google Gemini</strong></summary>

```dart
final response = model.generateContentStream(prompt);
final jsonStream = response.map((chunk) => chunk.text ?? '');
final parser = JsonStreamParser(jsonStream);
```

</details>

---

## Contributing

Contributions welcome!

1. Check [open issues](https://github.com/ComsIndeed/llm_json_stream/issues)
2. Open an issue before major changes  
3. Run `dart test` before submitting
4. Match existing code style

### Contributor Documentation

New to the codebase? Check out the **[Contributor Documentation](./doc/CONTRIBUTING/README.md)** for:

- 📐 [Architecture Overview](./doc/CONTRIBUTING/architecture-overview.md) - System design with diagrams
- 🧩 [Core Components](./doc/CONTRIBUTING/core-components.md) - Parser, controller, and mixins
- 🔧 [Delegates](./doc/CONTRIBUTING/delegates.md) - How each JSON type is parsed
- 📡 [Property Streams & Controllers](./doc/CONTRIBUTING/property-streams-controllers.md) - Stream architecture
- ⚙️ [Mechanisms](./doc/CONTRIBUTING/mechanisms.md) - Pathing, streaming, nesting systems
- 🔄 [Data Flow](./doc/CONTRIBUTING/data-flow.md) - Complete examples with sequence diagrams

---

## License

MIT — see [LICENSE](LICENSE)

---

<div align="center">

**Made for Flutter developers building the next generation of AI-powered apps**

[⭐ Star](https://github.com/ComsIndeed/llm_json_stream) · [📦 pub.dev](https://pub.dev/packages/llm_json_stream) · [🐛 Issues](https://github.com/ComsIndeed/llm_json_stream/issues)

</div>
