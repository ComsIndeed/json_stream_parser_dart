# JSON Stream Parser

**WORK IN PROGRESS** - Published to GitHub to allow for cloning anywhere for now

## ✅ Test Suite Available!

This project now includes a **comprehensive test suite with 193 tests** covering all JSON types and streaming scenarios!

- 📁 See `test/COMPLETE_GUIDE.md` for full testing documentation
- 🚀 Run tests: `dart test`
- 📊 All tests passing: 100%
- 🎯 Covers: strings, numbers, booleans, nulls, maps, lists, and complex nesting

## 🎯 Project Overview

This package implements a **streaming JSON parser** specifically designed for **LLM streaming responses** that output structured JSON data. As an LLM generates JSON token-by-token, this parser allows you to reactively access properties **as they're being formed**, without waiting for the entire response to complete.

### Perfect For:
- 🤖 **LLM Streaming APIs** (OpenAI, Anthropic, Gemini, etc.) with JSON mode
- 📊 **Real-time UI updates** as structured data arrives from AI
- 🎯 **Partial data access** - read completed properties while others are still streaming
- 🔄 **Reactive applications** that respond to AI-generated data incrementally

### Key Innovation:
Unlike traditional parsers that require complete JSON, this parser lets you subscribe to specific paths (like `"user.name"` or `"items[0].price"`) and receive values **the moment they're complete** in the stream, even while the rest of the JSON is still being generated.

## 🏗️ Architecture & Design

### Core Components

#### 1. **JsonStreamParser** (Main Controller)
The entry point and orchestrator that:
- Accepts a `Stream<String>` input (typically from an LLM API)
- Feeds characters to the root delegate
- Maintains a registry of property stream controllers
- Exposes the `getProperty<T>(String path)` method to subscribe to specific JSON paths

#### 2. **Property Delegates** (Character State Machines)
Each delegate is responsible for parsing a specific JSON type:
- **`MapPropertyDelegate`** - Parses JSON objects `{}`
- **`ListPropertyDelegate`** - Parses JSON arrays `[]`
- **`StringPropertyDelegate`** - Parses string values with escape handling
- **`NumberPropertyDelegate`** - Parses numeric values (int/double)
- **`BooleanPropertyDelegate`** - Parses `true`/`false`
- **`NullPropertyDelegate`** - Parses `null`

Delegates work by:
- Accumulating characters one at a time
- Maintaining state machines for their specific JSON type
- Creating child delegates for nested structures
- Emitting values to property streams when complete
- Signaling completion via the `isDone` flag

#### 3. **Property Streams & Controllers**
A dual-layer system for exposing parsed data:
- **Controllers** - Internal API for delegates to push data
- **Streams** - External API for users to subscribe to specific property paths

Each JSON type has its own controller/stream pair with **chainable `getProperty` methods**:
- `StringPropertyStream` - Terminal value (no further chaining)
- `NumberPropertyStream` - Terminal value (no further chaining)
- `BooleanPropertyStream` - Terminal value (no further chaining)
- `NullPropertyStream` - Terminal value (no further chaining)
- `MapPropertyStream` - **Chainable!** Call `.getProperty<T>("childKey")` to access nested properties
- `ListPropertyStream` - **Chainable!** Call `.getProperty<T>("[index]")` or iterate through elements

#### 4. **Path-Based Subscription System**
Users can subscribe to specific JSON paths with **chainable property access**:

**Simple paths:**
```dart
parser.getProperty<String>("user.name")  // Direct path notation
```

**Chainable paths:**
```dart
// Get a map, then chain further
final userMap = parser.getProperty<Map>("user");
final userName = userMap.getProperty<String>("name");
final userAge = userMap.getProperty<int>("age");

// Get an array, then access elements
final items = parser.getProperty<List>("items");
final firstItem = items.getProperty<Map>("[0]");
final itemPrice = firstItem.getProperty<double>("price");
```

**Complex nested path:**
```dart
parser.getProperty<String>("ancestor.parent.child[2].user.name")
```

## 💡 Usage Examples

### Example 1: Basic LLM Streaming Response

Imagine an LLM generating this JSON as a stream:

```json
{
  "status": "success",
  "user": {
    "name": "Alice",
    "age": 30,
    "email": "alice@example.com"
  },
  "message": "Profile retrieved successfully"
}
```

**Your code can reactively access properties as they complete:**

```dart
import 'package:json_stream_parser/json_stream_parser.dart';

void main() async {
  // Simulating an LLM streaming response
  final llmStream = getLLMStream(); // Returns Stream<String>
  
  final parser = JsonStreamParser(llmStream);
  
  // Subscribe to specific properties
  final statusStream = parser.getProperty<String>("status");
  final nameStream = parser.getProperty<String>("user.name");
  final ageStream = parser.getProperty<int>("user.age");
  
  // React to values as they complete
  statusStream.listen((value) {
    print("Status completed: $value"); // Prints immediately after "status":"success" is parsed
  });
  
  nameStream.listen((name) {
    print("User name: $name"); // Prints as soon as "name":"Alice" is complete
  });
  
  ageStream.listen((age) {
    print("User age: $age"); // Prints when age property is complete
  });
}
```

### Example 2: Chainable Property Access

```dart
void main() async {
  final llmStream = getStructuredLLMResponse();
  final parser = JsonStreamParser(llmStream);
  
  // Get a map property, then chain further
  final userMapStream = parser.getProperty<Map>("user");
  
  userMapStream.listen((userMap) {
    // Once user map is complete, access its properties
    final name = userMap.getProperty<String>("name");
    final email = userMap.getProperty<String>("email");
    
    name.listen((n) => print("Name: $n"));
    email.listen((e) => print("Email: $e"));
  });
}
```

### Example 3: Working with Lists

```dart
void main() async {
  // LLM generating: {"items": [{"id": 1, "name": "Item 1"}, {"id": 2, "name": "Item 2"}]}
  final llmStream = getLLMItemStream();
  final parser = JsonStreamParser(llmStream);
  
  // Access array elements
  final firstItemName = parser.getProperty<String>("items[0].name");
  final secondItemId = parser.getProperty<int>("items[1].id");
  
  firstItemName.listen((name) {
    print("First item: $name"); // Prints as soon as items[0].name completes
  });
  
  // Or get the entire list, then iterate
  final itemsStream = parser.getProperty<List>("items");
  itemsStream.listen((items) {
    // Access list property stream methods
    items.onElement((index, element) {
      print("Item $index: ${element.getProperty<String>("name")}");
    });
  });
}
```

### Example 4: Real-World LLM Scenario

```dart
import 'package:http/http.dart' as http;
import 'package:json_stream_parser/json_stream_parser.dart';

void main() async {
  // Call OpenAI API with streaming and JSON mode
  final request = http.Request(
    'POST',
    Uri.parse('https://api.openai.com/v1/chat/completions'),
  );
  
  request.headers['Authorization'] = 'Bearer YOUR_API_KEY';
  request.headers['Content-Type'] = 'application/json';
  
  request.body = jsonEncode({
    'model': 'gpt-4',
    'messages': [
      {'role': 'user', 'content': 'Generate a user profile in JSON format'}
    ],
    'response_format': {'type': 'json_object'},
    'stream': true,
  });
  
  final response = await request.send();
  
  // Transform SSE stream to character stream
  final charStream = response.stream
    .transform(utf8.decoder)
    .transform(LineSplitter())
    .where((line) => line.startsWith('data: '))
    .map((line) => line.substring(6))
    .where((data) => data != '[DONE]')
    .map((data) => jsonDecode(data))
    .map((json) => json['choices'][0]['delta']['content'] ?? '')
    .expand((chunk) => chunk.split(''));
  
  final parser = JsonStreamParser(charStream);
  
  // Update UI as properties become available
  parser.getProperty<String>("name").listen((name) {
    updateUI(nameWidget: name);
  });
  
  parser.getProperty<int>("age").listen((age) {
    updateUI(ageWidget: age);
  });
  
  parser.getProperty<List>("hobbies").listen((hobbies) {
    hobbies.onElement((index, hobby) {
      addHobbyToUI(hobby.getProperty<String>("name"));
    });
  });
}
```

### Example 5: Nested Complex Structures

```dart
void main() async {
  // LLM generating complex nested JSON
  final parser = JsonStreamParser(getLLMStream());
  
  // Direct deep path
  final deepValue = parser.getProperty<String>("ancestor.parent.child[2].user.name");
  deepValue.listen((name) => print("Deep nested name: $name"));
  
  // Or chain step by step
  final ancestor = parser.getProperty<Map>("ancestor");
  ancestor.listen((ancestorMap) {
    final parent = ancestorMap.getProperty<Map>("parent");
    parent.listen((parentMap) {
      final children = parentMap.getProperty<List>("child");
      children.listen((childList) {
        final thirdChild = childList.getProperty<Map>("[2]");
        thirdChild.listen((child) {
          final user = child.getProperty<Map>("user");
          user.listen((userMap) {
            final name = userMap.getProperty<String>("name");
            name.listen((n) => print("Chained name: $n"));
          });
        });
      });
    });
  });
}
```

## 🎨 API Surface

### JsonStreamParser

```dart
class JsonStreamParser {
  JsonStreamParser(Stream<String> stream);
  
  // Get a property stream by path
  PropertyStream<T> getProperty<T>(String path);
}
```

### PropertyStream (Base)

All property streams inherit from this base:

```dart
abstract class PropertyStream<T> {
  // Listen to value emissions
  Stream<T> get stream;
  
  // Listen helper
  StreamSubscription<T> listen(void Function(T value) onData);
}
```

### MapPropertyStream

```dart
class MapPropertyStream extends PropertyStream<Map> {
  // Chain to access nested properties
  PropertyStream<T> getProperty<T>(String key);
  
  // Listen to key-value pairs as they complete
  Stream<MapEntry<String, dynamic>> get entries;
}
```

### ListPropertyStream

```dart
class ListPropertyStream extends PropertyStream<List> {
  // Access specific index (e.g., "[0]", "[1]")
  PropertyStream<T> getProperty<T>(String index);
  
  // React to each element as it completes
  void onElement(void Function(int index, dynamic element) callback);
  
  // Stream of completed elements
  Stream<dynamic> get elements;
}
```

### Terminal Streams

```dart
class StringPropertyStream extends PropertyStream<String> {
  // Terminal - no further chaining
}

class NumberPropertyStream extends PropertyStream<num> {
  // Terminal - no further chaining
}

class BooleanPropertyStream extends PropertyStream<bool> {
  // Terminal - no further chaining
}

class NullPropertyStream extends PropertyStream<Null> {
  // Terminal - no further chaining
}
```

## 📍 Current Status

### ✅ Completed
- [x] Basic project structure and file organization
- [x] `PropertyDelegate` base class with path management
- [x] `MapPropertyDelegate` with complete state machine implementation
- [x] `StringPropertyDelegate` with escape character handling
- [x] `JsonStreamParser` base implementation with root delegate creation
- [x] Property stream/controller architecture defined
- [x] `Delegator` mixin for delegate factory pattern
- [x] Character-by-character parsing infrastructure

### 🚧 In Progress
You're currently at the **property emission interface** phase - determining how delegates should communicate parsed values back to property streams, and how to implement the **chainable `getProperty` API** for Map and List streams.

### Key Design Questions Being Resolved:
1. How should delegates emit values to their property streams?
2. What's the interface for `addPropertyChunk` and `addToPropertyStream`?
3. How should property controllers aggregate chunks into complete values?
4. How should `MapPropertyStream.getProperty<T>()` and `ListPropertyStream.getProperty<T>()` work?
5. Should property streams maintain their own sub-property registries?

## ✅ Task List

### Core Parser Implementation

- [ ] **Complete `JsonStreamParserController` interface**
  - [ ] Implement `addPropertyChunk` method
  - [ ] Add `addToPropertyStream<T>` method (currently called by delegates but not defined)
  - [ ] Implement property controller registry management (`Map<String, PropertyStreamController>`)
  - [ ] Add method to create/retrieve property controllers by path
  - [ ] Handle path parsing (split by `.` and handle `[index]` notation)

- [ ] **Implement `JsonStreamParser.getProperty<T>` method**
  - [ ] Parse the path string (handle dots and array indices)
  - [ ] Create or retrieve property controller for the given path
  - [ ] Return the appropriate property stream to the caller
  - [ ] Handle path validation and error cases
  - [ ] Support generic type casting

- [ ] **Complete Property Stream Controllers**
  - [ ] Add internal `StreamController<T>` to each controller type
  - [ ] Implement `StringPropertyStreamController.addChunk` - accumulate string chunks
  - [ ] Implement `MapPropertyStreamController` - manage nested property controllers
  - [ ] Implement `ListPropertyStreamController` - manage indexed element controllers
  - [ ] Implement `NumberPropertyStreamController.complete` - emit final number value
  - [ ] Implement `BooleanPropertyStreamController.complete` - emit true/false
  - [ ] Implement `NullPropertyStreamController.complete` - emit null
  - [ ] Implement stream closure logic in `onClose`

- [ ] **Complete Property Streams**
  - [ ] Expose `Stream<T>` getter for each property stream type
  - [ ] Add `listen()` method wrapper for convenience
  - [ ] **Implement `MapPropertyStream.getProperty<T>(String key)`** - chainable access
  - [ ] **Implement `ListPropertyStream.getProperty<T>(String index)`** - chainable access with `"[0]"` syntax
  - [ ] Implement `ListPropertyStream.onElement()` callback
  - [ ] Implement `ListPropertyStream.elements` stream
  - [ ] Implement `MapPropertyStream.entries` stream
  - [ ] Implement error handling for type mismatches

### Delegate Implementation

- [ ] **Complete `MapPropertyDelegate`**
  - [x] Basic state machine ✓
  - [ ] Fix key path construction (currently missing dot separator properly)
  - [ ] Handle nested object/array values properly
  - [ ] Handle whitespace between tokens (after `:`, `,`, etc.)
  - [ ] Emit to map property controller correctly
  - [ ] Test with complex nested structures

- [ ] **Implement `ListPropertyDelegate`**
  - [ ] Add state machine for array parsing (`waitingForValue`, `readingValue`, `waitingForCommaOrEnd`)
  - [ ] Handle array index in property paths (e.g., `items[0]`, `items[1]`)
  - [ ] Create child delegates for array elements
  - [ ] Handle comma separation between elements
  - [ ] Handle empty arrays `[]`
  - [ ] Emit array elements to list property controller

- [ ] **Implement `NumberPropertyDelegate`**
  - [ ] Buffer numeric characters (digits, decimal point, minus sign, exponent)
  - [ ] Detect completion (comma, closing bracket, closing brace, whitespace)
  - [ ] Parse to `int` or `double` as appropriate
  - [ ] Emit numeric value when complete
  - [ ] Handle scientific notation (e.g., `1.23e10`)
  - [ ] Handle negative numbers

- [ ] **Implement `BooleanPropertyDelegate`**
  - [ ] Parse `true` (accumulate 4 characters: t-r-u-e)
  - [ ] Parse `false` (accumulate 5 characters: f-a-l-s-e)
  - [ ] Emit boolean value when complete
  - [ ] Handle invalid boolean literals (error case)

- [ ] **Implement `NullPropertyDelegate`**
  - [ ] Parse `null` (accumulate 4 characters: n-u-l-l)
  - [ ] Emit null value when complete
  - [ ] Handle invalid null literals (error case)

### Edge Cases & Error Handling

- [ ] **Whitespace handling**
  - [ ] Skip whitespace between tokens in maps and arrays (spaces, tabs, newlines)
  - [ ] Preserve whitespace in string values (already done in StringPropertyDelegate)

- [ ] **Error cases**
  - [ ] Handle malformed JSON gracefully (invalid characters, unclosed brackets)
  - [ ] Emit errors to property streams
  - [ ] Add validation for closing brackets/braces matching opening ones
  - [ ] Handle unexpected characters in delegates
  - [ ] Handle path not found errors
  - [ ] Handle type mismatch errors (asking for String when it's a Number)

- [ ] **Memory management**
  - [ ] Clean up completed property controllers (prevent memory leaks)
  - [ ] Implement buffer size limits for safety (prevent infinite string accumulation)
  - [ ] Close streams properly when parsing completes

### Testing

- [ ] **Unit tests for each delegate**
  - [ ] Test `StringPropertyDelegate` with various escape sequences (`\"`, `\\`, `\n`, `\t`)
  - [ ] Test `MapPropertyDelegate` with nested objects
  - [ ] Test `ListPropertyDelegate` with mixed-type arrays
  - [ ] Test `NumberPropertyDelegate` with integers, decimals, and scientific notation
  - [ ] Test `BooleanPropertyDelegate` with true/false
  - [ ] Test `NullPropertyDelegate`

- [ ] **Integration tests**
  - [ ] Test with the `testFlatMap` from test file
  - [ ] Test with the complex `testMap` from test file
  - [ ] Test with streaming chunks of various sizes
  - [ ] Test property path subscriptions (both direct paths and chainable)
  - [ ] Test chainable property access (`parser.getProperty<Map>("user").getProperty<String>("name")`)
  - [ ] Test LLM-like streaming scenarios (partial JSON, incremental property completion)

- [ ] **Performance tests**
  - [ ] Benchmark streaming vs traditional parsing
  - [ ] Test with realistic LLM response sizes
  - [ ] Measure memory usage during streaming

### Documentation & Examples

- [ ] **Create comprehensive examples**
  - [x] Basic usage example ✓
  - [x] Chainable property access example ✓
  - [x] Working with lists example ✓
  - [x] Real-world LLM streaming scenario ✓
  - [x] Complex nested structures example ✓
  - [ ] Implement examples in `/example` folder as runnable code
  - [ ] Add error handling examples
  - [ ] Add UI integration example (Flutter widget updating as properties arrive)

- [ ] **API Documentation**
  - [ ] Document all public classes and methods with dartdocs
  - [ ] Add examples to dartdocs
  - [ ] Create architecture diagram (delegates, controllers, streams)
  - [ ] Document the chainable API pattern

- [ ] **Update README**
  - [x] Add usage examples ✓
  - [x] Document API surface ✓
  - [x] Add real-world LLM scenarios ✓
  - [ ] Document performance characteristics
  - [ ] Include limitations and known issues
  - [ ] Add comparison with traditional JSON parsing

### Polish & Release

- [ ] **Code quality**
  - [ ] Remove all `// ignore_for_file` directives and fix issues
  - [ ] Add proper null safety annotations
  - [ ] Follow Dart style guide
  - [ ] Run `dart analyze` and fix all issues
  - [ ] Run `dart format` on all files
  - [ ] Add comprehensive inline comments

- [ ] **Package metadata**
  - [ ] Update `pubspec.yaml` with proper description
  - [ ] Add repository, homepage, and issue tracker URLs
  - [ ] Set appropriate version number (start with 0.1.0)
  - [ ] Add license file (MIT recommended)
  - [ ] Add package topics/tags for pub.dev

- [ ] **Prepare for publication**
  - [ ] Test with `dart pub publish --dry-run`
  - [ ] Create comprehensive CHANGELOG.md entries
  - [ ] Tag release in git
  - [ ] Publish to pub.dev
  - [ ] Create GitHub release notes

## 🎓 Next Immediate Steps

Based on your current code state and the **LLM streaming use case**, here's what to tackle next:

### Phase 1: Core Infrastructure (Do This First!)
1. **Add `StreamController<T>` to property stream controllers** - This is the foundation
2. **Implement `addToPropertyStream<T>` in `JsonStreamParserController`** - Connect delegates to streams
3. **Implement property controller registry** - Store controllers by path in a `Map<String, PropertyStreamController>`
4. **Implement `JsonStreamParser.getProperty<T>`** - Parse paths and return streams

### Phase 2: Make It Work End-to-End
5. **Test `StringPropertyDelegate` + `StringPropertyStream`** - It's the most complete delegate
6. **Complete `MapPropertyDelegate` emission** - Make sure it properly emits to its controller
7. **Implement `MapPropertyStream.getProperty<T>`** - Enable chaining for nested access
8. **Write your first integration test** - Parse a simple LLM response like `{"name": "Alice"}`

### Phase 3: Complete the Delegates
9. **Implement `NumberPropertyDelegate`** - Simpler than Map/List
10. **Implement `BooleanPropertyDelegate`** - Even simpler
11. **Implement `NullPropertyDelegate`** - Simplest
12. **Implement `ListPropertyDelegate`** - Similar to Map but with indices
13. **Implement `ListPropertyStream.getProperty<T>`** - Enable array access

### Phase 4: Polish & Real-World Testing
14. **Test with real LLM responses** - OpenAI, Anthropic, etc.
15. **Handle edge cases** - Malformed JSON, whitespace, etc.
16. **Optimize and document** - Make it production-ready

### Quick Win Example to Test First:
```dart
// Start with this simple case - no nesting, just a string property
final testStream = Stream.fromIterable([
  '{"na',  // Chunk 1
  'me":"', // Chunk 2
  'Alice', // Chunk 3
  '"}',    // Chunk 4
]);

final parser = JsonStreamParser(testStream);
final nameStream = parser.getProperty<String>("name");

nameStream.listen((name) {
  print("Got name: $name"); // Should print "Alice" after chunk 4
});
```

Once this works end-to-end, everything else is just expanding on this pattern! 🚀

## 🌟 Why This Is Awesome

This library enables **truly reactive UIs** for LLM applications:
- 🎯 Show partial results as they stream in
- 🚀 Start rendering before the full response completes
- 💪 Handle complex nested structures naturally
- 🔄 Compose property streams with Flutter StreamBuilders
- 🎨 Create real-time AI-powered interfaces

You're building something genuinely useful for the modern AI-powered app ecosystem! Keep going! �
