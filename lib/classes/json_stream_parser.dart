import 'dart:async';

import 'package:json_stream_parser/classes/property_delegates/list_property_delegate.dart';
import 'package:json_stream_parser/classes/property_delegates/map_property_delegate.dart';
import 'package:json_stream_parser/classes/property_delegates/property_delegate.dart';
import 'package:json_stream_parser/classes/property_stream.dart';

class JsonStreamParser {
  JsonStreamParser(Stream<String> stream) : _stream = stream {
    _controller = JsonStreamParserController(
      getPropertyStream: (String propertyPath) {
        return _properties[propertyPath] ?? NullPropertyStream();
      },
    );
    _stream.listen(_parseChunk);
  }

  // * Exposeds
  void getProperty() {}

  // * Fields
  final Stream<String> _stream;
  late JsonStreamParserController _controller;

  // * Memories
  final Map<String, PropertyStream> _properties = {};

  // * States
  PropertyDelegate? _rootDelegate;

  // * Helpers
  void _accumulateCharacter(String character) {}
  void _addChunkToStream() {}

  void _parseChunk(String chunk) {
    for (final character in chunk.split('')) {
      switch (character) {
        case '{':
          final delegate = MapPropertyDelegate(
            propertyPath: "",
            jsonStreamParserController: _controller,
          );
          _properties[delegate.propertyPath] = MapPropertyStream();
          _rootDelegate = delegate;
          break;
        case '[':
          final delegate = ListPropertyDelegate(
            propertyPath: "",
            jsonStreamParserController: _controller,
          );
          _properties[delegate.propertyPath] = ListPropertyStream();
          _rootDelegate = delegate;
          break;
        default:
          break;
      }
    }
    _rootDelegate?.onChunkEnd();
  }
}

class JsonStreamParserController {
  JsonStreamParserController({
    required PropertyStream Function(String) getPropertyStream,
  }) : _getPropertyStream = getPropertyStream;

  final PropertyStream Function(String) _getPropertyStream;

  PropertyStream _getPropertyStreamForType<T>() {
    if (T == String) {
      return StringPropertyStream();
    } else if (T == int || T == double) {
      return NumberPropertyStream();
    } else if (T == bool) {
      return BooleanPropertyStream();
    } else if (T == List) {
      return ListPropertyStream();
    } else if (T == Map) {
      return MapPropertyStream();
    } else if (T == Null) {
      return NullPropertyStream();
    }
    throw UnsupportedError('Unsupported type for PropertyStream: $T');
  }

  // * Exposeds

  void addToPropertyStream<T>({
    required String propertyPath,
    required T value,
  }) {
    final propertyStream = _getPropertyStream(propertyPath);
    final valuePropertyStream = _getPropertyStreamForType<T>();
    valuePropertyStream.controller.add(value);
  }
}
