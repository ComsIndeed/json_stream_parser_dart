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
/// ## Quick Start
///
/// ```dart
/// import 'package:llm_json_stream/llm_json_stream.dart';
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
///
/// ## Categories
///
/// - **Parser**: The main [JsonStreamParser] class
/// - **Property Streams**: [StringPropertyStream], [MapPropertyStream], [ListPropertyStream], etc.
/// - **Observability**: [ParseEvent] and [ParseEventType] for monitoring
/// - **Utilities**: Helper functions like [streamTextInChunks]
///
/// ## Documentation
///
/// For detailed architecture documentation, see the `doc/CONTRIBUTING/` folder.
library;

// Core parser
export 'src/json_stream_parser.dart' show JsonStreamParser;

// Property streams (public API)
export 'src/property_stream.dart'
    show
        PropertyStream,
        StringPropertyStream,
        NumberPropertyStream,
        BooleanPropertyStream,
        NullPropertyStream,
        MapPropertyStream,
        ListPropertyStream;

// Logging/observability
export 'src/parse_event.dart' show ParseEvent, ParseEventType;

// Utility for testing with simulated streams
export 'src/stream_text_in_chunks.dart' show streamTextInChunks;
