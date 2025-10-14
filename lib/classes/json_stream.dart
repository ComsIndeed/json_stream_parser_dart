// ignore_for_file: prefer_final_fields

import 'package:json_stream_parser/classes/property_stream.dart';

class JsonStream {
  JsonStream(Stream<String> stream) : _stream = stream {
    _stream.listen(_parse);
  }

  // * Public Method
  PropertyStream<T> getProperty<T>(String path) {
    return _getOrCreatePropertyStream<T>(path);
  }

  // * The addresses of objects
  Map<String, PropertyStream> _propertyStreams = {};

  PropertyStream<T> _getOrCreatePropertyStream<T>(
    String path, {
    dynamic object,
  }) {
    final PropertyStream newStream = switch (T) {
      const (String) => StringPropertyStream(_stream),
      const (bool) => BooleanPropertyStream(object as bool),
      const (Null) => NullPropertyStream(),
      const (num) => NumberPropertyStream(_stream),
      const (Map) => MapPropertyStream(_stream),
      const (List) => ListPropertyStream(_stream),
      _ => throw Exception("Unsupported property type: $T"),
    };

    return _propertyStreams.putIfAbsent(path, () => newStream)
        as PropertyStream<T>;
  }

  // * Internal States
  final Stream<String> _stream;
  var state = JsonStreamParserState.inNothing;
  bool skipUntilComma = false;
  String _topLevelKey = "";
  String _previousCharacter = "";
  String _buffer = "";
  bool _inValue = false;

  void _parse(String chunk) {
    String chunkBuffer = "";
    for (final character in chunk.split("")) {
      // Start of json
      if (character == '{' && _previousCharacter == "") {
        chunkBuffer += character;

        // Start of key string
      } else if (character == '"' && state == JsonStreamParserState.inNothing) {
        state = JsonStreamParserState.inKey;
        chunkBuffer += character;

        // Character key
      } else if (character != '"' && state == JsonStreamParserState.inKey) {
        chunkBuffer += character;
        _buffer += character;

        // End of key string
      } else if (character == '"' && state == JsonStreamParserState.inKey) {
        chunkBuffer += character;
        _topLevelKey = _buffer;

        // Switch to inValue mode
      } else if (character == ':') {
        chunkBuffer += character;
        state = JsonStreamParserState.inValue;

        // Start of string value
      } else if (character == '"' && state == JsonStreamParserState.inValue) {
        // CALL STRING PROPERTY STREAM

        // True value
      } else if (character == 't') {
        // CALL TRUE PROPERTY STREAM
        skipUntilComma = true;

        // False value
      } else if (character == 'f') {
        // CALL FALSE PROPERTY STREAM

        // Null value
        skipUntilComma = true;
      } else if (character == 'n') {
        // CALL NULL PROPERTY STREAM
        skipUntilComma = true;
      } else if (character == '{') {
        // ???
      } else if (character == '}') {
        // relevant flush? or let the miniparser handle it?
      } else if (character == '[') {
        // ???
      } else if (character == ']') {
        // relevant flush? or just let comma do it to keep logic clean. or let the miniparser handle it?
      } else if (character == ',') {
        chunkBuffer += character;
        skipUntilComma = false;
        // This may also be where a relevant flush must happen
      }

      _previousCharacter = character;
    }
    // when does the flushing of accumulated chunks happen
  }
}

enum JsonStreamParserState { inNothing, inKey, inValue, inList }
