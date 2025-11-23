import 'package:llm_json_stream/classes/json_stream_parser.dart';

/// Mixin that provides property getter methods for accessing nested JSON properties.
///
/// This mixin is used by [JsonStreamParser], [MapPropertyStream], and [ListPropertyStream]
/// to provide a consistent API for accessing nested properties.
///
/// Classes using this mixin must:
/// - Implement [buildPropertyPath] to specify how property paths are constructed
/// - Provide access to [parserController] for creating property streams
mixin PropertyGetterMixin {
  /// Builds the full property path for the given [key].
  ///
  /// Each class implements this differently:
  /// - JsonStreamParser: returns the key directly
  /// - MapPropertyStream: prepends the parent path with a dot separator
  /// - ListPropertyStream: handles array indices without dots
  String buildPropertyPath(String key);

  /// The parser controller used to create and manage property streams.
  JsonStreamParserController get parserController;

  /// Gets a stream for a string property at the specified [key].
  ///
  /// Returns a [StringPropertyStream] that provides:
  /// - `.stream` - Emits string chunks as they are parsed
  /// - `.future` - Completes with the full string value
  ///
  /// Example:
  /// ```dart
  /// final titleStream = parser.getStringProperty('title');
  /// titleStream.stream.listen((chunk) => print('Chunk: $chunk'));
  /// ```
  dynamic getStringProperty(String key) {
    final fullPath = buildPropertyPath(key);
    return parserController.getPropertyStream(fullPath, String);
  }

  /// Shorthand alias for [getStringProperty].
  dynamic str(String key) => getStringProperty(key);

  /// Gets a stream for a boolean property at the specified [key].
  ///
  /// Returns a [BooleanPropertyStream] that provides:
  /// - `.stream` - Emits the boolean when complete
  /// - `.future` - Completes with the parsed boolean value
  ///
  /// Example:
  /// ```dart
  /// final isActive = await parser.getBooleanProperty('active').future;
  /// ```
  dynamic getBooleanProperty(String key) {
    final fullPath = buildPropertyPath(key);
    return parserController.getPropertyStream(fullPath, bool);
  }

  /// Shorthand alias for [getBooleanProperty].
  dynamic boolean(String key) => getBooleanProperty(key);

  /// Gets a stream for a number property at the specified [key].
  ///
  /// Returns a [NumberPropertyStream] that provides:
  /// - `.stream` - Emits the number when complete
  /// - `.future` - Completes with the parsed number value
  ///
  /// Example:
  /// ```dart
  /// final age = await parser.getNumberProperty('age').future;
  /// ```
  dynamic getNumberProperty(String key) {
    final fullPath = buildPropertyPath(key);
    return parserController.getPropertyStream(fullPath, num);
  }

  /// Shorthand alias for [getNumberProperty].
  dynamic number(String key) => getNumberProperty(key);

  /// Gets a stream for a null property at the specified [key].
  ///
  /// Returns a [NullPropertyStream] that provides:
  /// - `.stream` - Emits null when the property completes
  /// - `.future` - Completes with null
  ///
  /// Example:
  /// ```dart
  /// await parser.getNullProperty('optionalField').future;
  /// ```
  dynamic getNullProperty(String key) {
    final fullPath = buildPropertyPath(key);
    return parserController.getPropertyStream(fullPath, Null);
  }

  /// Shorthand alias for [getNullProperty].
  // Note: Can't use `null` as a method name, so we use `nil` instead
  dynamic nil(String key) => getNullProperty(key);

  /// Gets a stream for a map (object) property at the specified [key].
  ///
  /// Returns a [MapPropertyStream] that provides:
  /// - `.future` - Completes with the full parsed map
  /// - Chainable property getters to access nested properties
  ///
  /// Example:
  /// ```dart
  /// final userMap = parser.getMapProperty('user');
  /// final name = userMap.getStringProperty('name');
  /// ```
  dynamic getMapProperty(String key) {
    final fullPath = buildPropertyPath(key);
    return parserController.getPropertyStream(fullPath, Map);
  }

  /// Shorthand alias for [getMapProperty].
  dynamic map(String key) => getMapProperty(key);

  /// Gets a stream for a list (array) property at the specified [key].
  ///
  /// Returns a [ListPropertyStream] that provides:
  /// - `.future` - Completes with the full parsed list
  /// - `.onElement()` - Callback that fires when each element starts parsing
  /// - Chainable property getters to access elements
  ///
  /// The optional [onElement] callback fires immediately when a new array
  /// element is discovered, before it's fully parsed.
  ///
  /// Example:
  /// ```dart
  /// final items = parser.getListProperty('items', onElement: (element, index) {
  ///   print('New item at index $index');
  /// });
  /// ```
  dynamic getListProperty<E extends Object?>(
    String key, {
    void Function(dynamic propertyStream, int index)? onElement,
  }) {
    final fullPath = buildPropertyPath(key);

    final listStream = parserController.getPropertyStream(fullPath, List);

    if (onElement != null) {
      // Call onElement on the returned stream
      (listStream as dynamic).onElement(onElement);
    }

    return listStream;
  }

  /// Shorthand alias for [getListProperty].
  dynamic list<E extends Object?>(
    String key, {
    void Function(dynamic propertyStream, int index)? onElement,
  }) =>
      getListProperty<E>(key, onElement: onElement);
}
