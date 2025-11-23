# LLM JSON Stream

[![Tests Passing](https://img.shields.io/badge/tests-338%20passing-brightgreen)]()
[![Dart](https://img.shields.io/badge/dart-%3E%3D3.0.0-blue)]()
[![pub package](https://img.shields.io/pub/v/llm_json_stream.svg)](https://pub.dev/packages/llm_json_stream)

**Build ChatGPT-style streaming UIs in Flutter** - Parse JSON reactively as LLM responses arrive, character-by-character.

![Hero demo showing a Flutter app with streaming text appearing word-by-word in real-time, with the title "LLM JSON Stream Parser is Great!".](https://raw.githubusercontent.com/ComsIndeed/llm_json_stream/main/assets/demo/hero.gif)


Visit the live demo at: **https://comsindeed.github.io/json_stream_parser_demo/**

### Basic Usage

```dart
import 'package:llm_json_stream/json_stream_parser.dart';

void main() async {
  final stream = AI.sendMessage("Generate me JSON with ...");
  
  final parser = JsonStreamParser(stream);
  
  // Subscribe to specific properties
  final titleStream = parser.getStringProperty("title");
  final itemsStream = parser.getListProperty("items");
  
  // React to values as they complete
  titleStream.stream.listen((chunk) {
    print("Title chunk: $chunk");
  });

  // Await full values when needed
  final items = await itemsStream.future;
  print("Full items list received: $items");
}
```

## The Problem

When streaming JSON from LLM APIs (OpenAI, Claude, Gemini), you receive incomplete chunks:

![LLM JSON chunks arriving incomplete: Chunk 1: {\"title\": \"My G, Chunk 2: reat Blog Po, Chunk 3: st\", \"items\": [, Chunk 4: {\"id\": 1, \"n, Chunk 5: ame\": \"Item 1\"}, Chunk 6: ]} - showing how traditional JSON parsers break on partial objects](https://raw.githubusercontent.com/ComsIndeed/llm_json_stream/main/assets/demo/problem.gif)

<!-- **What happens:**
```dart
// Chunk 1: {"title": "My G
// Chunk 2: reat Blog Po
// Chunk 3: st", "items": [
// Chunk 4: {"id": 1, "n
// Chunk 5: ame": "Item 1"}
// Chunk 6: ]}
``` -->

Standard parsers like `jsonDecode()` can't handle this. You're forced to either:

- **Wait for the entire response** (slow, high latency, defeats streaming)
- **Display raw chunks** (broken text like `{"title": "My G` in your UI)
- **Build a custom parser** (complex, error-prone, time-consuming)

## The Solution

LLM JSON Stream parses JSON **character-by-character** as it arrives, letting you build reactive UIs that update instantly.

![Side-by-side comparison. LEFT: "Traditional Approach" - Loading spinner, then suddenly all content appears at once. RIGHT: "With LLM JSON Stream" - Content streams in smoothly, text appears word-by-word.](https://raw.githubusercontent.com/ComsIndeed/llm_json_stream/main/assets/demo/comparison.gif)

## Key Features

### 1. Streaming String Values

Display text as the LLM generates it, creating a responsive "typing" effect.

![Streaming string property example](https://raw.githubusercontent.com/ComsIndeed/llm_json_stream/main/assets/demo/string-property-stream-2.gif)


```dart
// Create an instance
final parser = JsonStreamParser(llmStream);

// Access the `title` property as a streaming string
final titleProperty = parser.getStringProperty('title');

// Listen for incremental chunks as they arrive
titleProp.stream.listen((chunk) {
  print('Title chunk: $chunk');
});
```

**What happens**

- Each fragment of the JSON containing the `title` field triggers a callback.
- The `stream` prints incremental pieces

This demonstrates how `getStringProperty().stream` lets your UI update character‑by‑character while still providing a convenient way to get the final value.  

### 2. Reactive Lists

Add list items to your UI **the moment they start parsing** - before their content even arrives.

![Reactive list example](https://raw.githubusercontent.com/ComsIndeed/llm_json_stream/main/assets/demo/list-onElement-string-streams.gif)

```dart
parser.list('tags').onElement((tag, index) {  
  // Fires IMMEDIATELY when "[{" is detected
  setState(() {
    tags.add(ArticleCard(index: index)); // Add placeholder
  });
  
  // Fill in content as it arrives
  tag.asMap.str('title').stream.listen((chunk) {
    setState(() => tags[index].title += chunk);
  });
});
```

**The magic:** Traditional parsers wait for complete objects before updating your list, causing jarring jumps. This parser lets you add elements instantly and populate them reactively.

### 3. 🔀 Dual Stream & Future API

Choose the right tool for each property:

![Split screen showing two properties from same JSON. LEFT is a stream showing incremental text updates. RIGHT is a future](https://raw.githubusercontent.com/ComsIndeed/llm_json_stream/main/assets/demo/dual-comparison.gif)

```dart
// Stream for incremental updates
parser.str('email').stream.listen((chunk) {
  displayText += chunk; // Real-time updates
});

// Future for atomic values
final id = await parser.number('id').future;
final isPublished = await parser.bool('published').future;
```

---

## API Overview

### Parser Creation

```dart
final parser = JsonStreamParser(streamFromLLM);
```

### Short Aliases (Recommended)

```dart
parser.str(path)      // String property
parser.number(path)   // Number property
parser.bool(path)     // Boolean property
parser.list(path)     // List property
parser.map(path)      // Map (object) property
```

### Long Form (For Clarity)

```dart
parser.getStringProperty(path)
parser.getNumberProperty(path)
parser.getBooleanProperty(path)
parser.getListProperty(path)
parser.getMapProperty(path)
parser.getNullProperty(path)
```

### Smart Casts

Clean up nested property access:

```dart
// Instead of checking types manually
if (element is MapPropertyStream) {
  element.getStringProperty('name')...
}

// Use smart casts
element.asMap.str('name').stream.listen(...);
```

**Available casts:** `.asMap`, `.asList`, `.asStr`, `.asNum`, `.asBool`

---

## Path Syntax

Access nested properties with dot notation or array indices:

![Various path examples with code and JSON side by side. Highlight how each path resolves. Examples: `"user.name"`, `"items[0].title"`, `"data.users[2].profile.email"`. Show the parser successfully extracting each value as JSON streams in.](https://raw.githubusercontent.com/ComsIndeed/llm_json_stream/main/assets/demo/deep-future.gif)

```dart
parser.str('title')                      // Root property
parser.str('user.name')                  // Nested property
parser.str('items[0].title')             // Array element
parser.number('data.users[2].age')       // Deep nesting
```

### Chainable API

For better type safety and readability:

```dart
final user = parser.map('user');
final name = user.str('name');
final email = user.str('email');
final age = user.number('age');
```

<!-- ---

## Common Patterns

### Pattern 1: Streaming Chat Response

```dart
parser.str('message').stream.listen((chunk) {
  setState(() => chatMessage += chunk);
});

await parser.str('message').future; // Wait for completion
setState(() => isGenerating = false);
```

<GIF: Flutter chat interface showing a message appearing word-by-word with a blinking cursor, then the cursor disappearing when complete. Show the code and JSON streaming.</GIF>

### Pattern 2: Progressive List Loading

```dart
final results = parser.list('results');

results.onElement((item, index) {
  // Add placeholder immediately
  setState(() => items.add(LoadingCard(index: index)));
  
  // Replace with real content when ready
  item.asMap.str('title').future.then((title) {
    setState(() => items[index] = ContentCard(title: title));
  });
});
```

<GIF: Flutter ListView showing cards appearing one by one with loading shimmer, then filling with actual content. Show smooth animation with no jittering. Display code alongside.</GIF>

### Pattern 3: Mixed Stream and Future

```dart
// Stream the main content
parser.str('article').stream.listen((chunk) {
  setState(() => articleText += chunk);
});

// Await metadata
final metadata = await parser.map('metadata').future;
final author = await parser.str('metadata.author').future;
final publishDate = await parser.str('metadata.date').future;

// Use metadata immediately
setState(() {
  authorName = author;
  date = publishDate;
});
```

<GIF: Flutter app showing article text streaming in the center while metadata (author, date, tags) appears immediately once complete at the top. Show how different properties complete at different times.</GIF>

---

## LLM Provider Examples

### OpenAI

```dart
final stream = openai.chat.completions.create(
  model: 'gpt-4',
  messages: messages,
  stream: true,
);

final jsonStream = stream.map((chunk) => 
  chunk.choices.first.delta.content ?? ''
);

final parser = JsonStreamParser(jsonStream);
```

### Anthropic Claude

```dart
final stream = anthropic.messages.stream(
  model: 'claude-3-opus',
  messages: messages,
);

final jsonStream = stream.map((event) => event.delta?.text ?? '');
final parser = JsonStreamParser(jsonStream);
```

### Google Gemini

```dart
final response = model.generateContentStream(prompt);
final jsonStream = response.map((chunk) => 
  chunk.text ?? ''
);

final parser = JsonStreamParser(jsonStream);
```

---

## Advanced Features

### Nested List Handling

Set callbacks on nested lists in two ways:

```dart
// Option 1: Set callback when getting the list
final items = parser.list('items', onElement: (item, index) {
  print('Item $index started');
});

// Option 2: Set callback after
final items = parser.list('items');
items.onElement((item, index) {
  print('Item $index started');
});
```

<GIF: Show nested structure like `{"departments": [{"name": "Engineering", "employees": [...]}]}` streaming in, with Flutter UI showing departments appearing, then employees appearing within each department. Show the onElement callbacks firing at each level.</GIF>

### Resource Cleanup

Always dispose the parser when done:

```dart
final parser = JsonStreamParser(stream);

// Use parser...
await parser.str('title').future;

// Clean up
await parser.dispose();
```

### Edge Cases

The parser handles:

- ✅ Escape sequences (`\"`, `\\`, `\n`, etc.)
- ✅ Unicode characters
- ✅ Scientific notation (`1.5e10`)
- ✅ Multiline JSON with whitespace
- ✅ Deeply nested structures
- ✅ Large responses (tested with 10,000+ element arrays)

<GIF: Show JSON with special characters: `{"message": "She said \"Hello\"\nNew line"}` streaming in and being correctly parsed. Display the escaped characters in the JSON and the properly decoded output.</GIF>

---

## Performance

<GIF: Performance comparison chart showing: Traditional parsing (flat line then sudden spike at end), LLM JSON Stream (smooth diagonal line rising steadily). X-axis: Time, Y-axis: Content Displayed. Emphasize lower perceived latency.</GIF>

| Metric | Traditional | LLM JSON Stream |
|--------|------------|-----------------|
| First content visible | 2-5s | 0.1s |
| Perceived latency | High | Low |
| UI updates | 1 (at end) | Continuous |
| User experience | Loading... | Smooth streaming |

---

## Complete Example

```dart
import 'package:llm_json_stream/json_stream_parser.dart';

void main() async {
  // Simulate LLM streaming response
  final llmStream = Stream.fromIterable([
    '{"title": "How to',
    ' Build Amazing',
    ' Apps", "sections": [',
    '{"heading": "Introduction",',
    ' "content": "Welcome..."}, ',
    '{"heading": "Getting Started",',
    ' "content": "First..."}',
    ']}'
  ]);

  final parser = JsonStreamParser(llmStream);

  // Stream the title
  parser.str('title').stream.listen((chunk) {
    print('Title chunk: $chunk');
  });

  // Handle sections as they arrive
  parser.list('sections').onElement((section, index) {
    print('Section $index started!');
    
    section.asMap.str('heading').stream.listen((chunk) {
      print('  Heading: $chunk');
    });
    
    section.asMap.str('content').stream.listen((chunk) {
      print('  Content: $chunk');
    });
  });

  // Wait for completion
  await parser.list('sections').future;
  print('All sections received!');
  
  // Cleanup
  await parser.dispose();
}
```

<GIF: Show this exact code running in a terminal with colored output showing the incremental updates as JSON chunks arrive. Make it visually clear how the callbacks fire as data streams in.</GIF>

--- -->

## Installation

```yaml
dependencies:
  llm_json_stream: ^0.2.2
```

Then run:
```bash
dart pub get
# or
flutter pub get
```

---

## API Reference

### JsonStreamParser

| Method | Returns | Description |
|--------|---------|-------------|
| `str(path)` | `StringPropertyStream` | Get string property |
| `number(path)` | `NumberPropertyStream` | Get number property |
| `bool(path)` | `BooleanPropertyStream` | Get boolean property |
| `list(path)` | `ListPropertyStream` | Get list property |
| `map(path)` | `MapPropertyStream` | Get map property |
| `dispose()` | `Future<void>` | Clean up resources |

### PropertyStream API

All property streams provide:

- `.stream` - Stream of values/chunks as they arrive
- `.future` - Future that completes with the final value

### ListPropertyStream Special

```dart
void onElement(void Function(PropertyStream element, int index) callback)
```

Fires when each array element **starts** parsing (before completion).

---

## Contributing

Contributions are welcome! Please:

1. Check existing [issues](https://github.com/ComsIndeed/llm_json_stream/issues)
2. Open an issue before major changes
3. Ensure tests pass (`dart test`)
4. Follow existing code style

---

## Support

- 📖 [API Documentation](https://pub.dev/documentation/llm_json_stream/latest/)
- 🐛 [Issue Tracker](https://github.com/ComsIndeed/llm_json_stream/issues)
- 💬 [Discussions](https://github.com/ComsIndeed/llm_json_stream/discussions)
- ⭐ [GitHub Repository](https://github.com/ComsIndeed/llm_json_stream)

---

## License

MIT License - see [LICENSE](LICENSE) file for details.

---

## Acknowledgments

Built with ❤️ for the Flutter and Dart community. Special thanks to all contributors and early adopters providing feedback.

**If this package helped you build something cool, consider:**
- ⭐ Starring the repo
- 📝 Writing about your use case
- 🐛 Reporting bugs
- 💡 Suggesting features

---

**Status:** ⚠️ Early release (v0.2.1) - API may evolve based on feedback. 338 tests passing. Production-ready for adventurous developers!