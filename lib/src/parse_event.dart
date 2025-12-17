/// Represents a log event from the JSON stream parser.
///
/// Log events provide visibility into the parsing process, including
/// when properties start/complete parsing, errors, and other internal events.
///
/// ## Usage
///
/// ```dart
/// final parser = JsonStreamParser(stream, onLog: (event) {
///   print('[${event.type}] ${event.propertyPath}: ${event.message}');
/// });
/// ```
///
/// ## Properties
///
/// - [type] - The type of event (see [ParseEventType])
/// - [propertyPath] - The JSON path where the event occurred
/// - [message] - Human-readable description
/// - [timestamp] - When the event occurred
/// - [data] - Optional additional data
class ParseEvent {
  /// The type of event that occurred.
  final ParseEventType type;

  /// The property path where the event occurred.
  ///
  /// Empty string for root-level events.
  final String propertyPath;

  /// A human-readable message describing the event.
  final String message;

  /// The timestamp when the event occurred.
  final DateTime timestamp;

  /// Optional additional data associated with the event.
  final Object? data;

  ParseEvent({
    required this.type,
    required this.propertyPath,
    required this.message,
    this.data,
  }) : timestamp = DateTime.now();

  @override
  String toString() {
    final pathStr = propertyPath.isEmpty ? 'root' : propertyPath;
    return '[$type] $pathStr: $message';
  }
}

/// Types of parsing events that can be logged.
///
/// These event types are used in [ParseEvent.type] to indicate what
/// kind of parsing event occurred.
enum ParseEventType {
  /// A property started being parsed.
  propertyStart,

  /// A property finished parsing successfully.
  propertyComplete,

  /// A new chunk was received for a string property.
  stringChunk,

  /// A new element started in a list.
  listElementStart,

  /// A new key was discovered in a map.
  mapKeyDiscovered,

  /// The root JSON object/array started parsing.
  rootStart,

  /// The root JSON object/array completed parsing.
  rootComplete,

  /// An error occurred during parsing.
  error,

  /// The parser was disposed.
  disposed,

  /// The yap filter triggered (extra text after JSON).
  yapFiltered,

  /// Entered thinking/reasoning tags (when skipThoughts is enabled).
  thinkingTagStart,

  /// Exited thinking/reasoning tags (when skipThoughts is enabled).
  thinkingTagEnd,
}
