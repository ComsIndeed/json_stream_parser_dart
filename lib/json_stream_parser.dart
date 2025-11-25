/// A streaming JSON parser optimized for LLM responses.
///
/// This library provides a [JsonStreamParser] that allows you to parse JSON
/// data as it streams in, character by character. It's specifically designed
/// for handling Large Language Model (LLM) streaming responses that output
/// structured JSON data.
///
/// ## Features
///
/// - **Reactive property access**: Subscribe to JSON properties as they complete
/// - **Path-based subscriptions**: Access nested properties with dot notation
/// - **Chainable API**: Fluent syntax for accessing nested structures
/// - **Type safety**: Typed property streams for all JSON types
/// - **Array support**: Access array elements by index and iterate dynamically
///
/// ## Usage
///
/// ```dart
/// import 'package:llm_json_stream/json_stream_parser.dart';
///
/// void main() async {
///   final parser = JsonStreamParser(streamFromLLM);
///
///   // Subscribe to specific properties
///   parser.getStringProperty('user.name').stream.listen((name) {
///     print('Name: $name');
///   });
///
///   // Wait for complete values
///   final age = await parser.getNumberProperty('user.age').future;
///   print('Age: $age');
/// }
/// ```
library;

// Core parser
export 'classes/json_stream_parser.dart' show JsonStreamParser;

// Property streams (public API)
export 'classes/property_stream.dart'
    show
        PropertyStream,
        StringPropertyStream,
        NumberPropertyStream,
        BooleanPropertyStream,
        NullPropertyStream,
        MapPropertyStream,
        ListPropertyStream;

// Utility exports (if users need to test with simulated streams)
export 'utilities/stream_text_in_chunks.dart' show streamTextInChunks;
