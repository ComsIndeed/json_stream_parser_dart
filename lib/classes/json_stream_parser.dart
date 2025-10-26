import 'dart:async';

import 'package:json_stream_parser/classes/property_delegates/list_property_delegate.dart';
import 'package:json_stream_parser/classes/property_delegates/map_property_delegate.dart';
import 'package:json_stream_parser/classes/property_delegates/property_delegate.dart';
import 'package:json_stream_parser/classes/property_stream.dart';
import 'package:json_stream_parser/classes/property_stream_controller.dart';

///
/// BASE PARSER HANDLING THE DELEGATES AND PROPERTY STREAMS
/// [ ] RESPONSIBLE FOR CREATING THE ROOT DELEGATE AND PROVIDING METHODS TO DESCENDANT DELEGATES
/// [ ] RESPONSIBLE FOR EXPOSING METHODS TO GET PROPERTY STREAMS
/// [ ] RESPONSIBLE FOR FEEDING CHUNKS TO THE ROOT DELEGATE
/// [ ] RESPONSIBLE FOR SIGNALLING THE END OF A CHUNK TO THE ROOT DELEGATE
///

class JsonStreamParser {
  JsonStreamParser(Stream<String> stream) : _stream = stream {
    _stream.listen(_parseChunk);
    _controller = JsonStreamParserController(
      addPropertyChunk: addPropertyChunk,
    );
  }

  // * Exposeds
  void getProperty<T>(String path) {}

  // * Controller methods
  void addPropertyChunk({required String path, required String chunk}) {}

  // * Fields
  final Stream<String> _stream;
  late final JsonStreamParserController _controller;

  // * Memories
  final Map<String, PropertyStreamController> _propertyControllers = {};

  // * States
  PropertyDelegate? _rootDelegate;

  // * Helpers
  void _parseChunk(String chunk) {
    for (final character in chunk.split('')) {
      if (_rootDelegate != null) {
        _rootDelegate!.addCharacter(character);
        continue;
      }

      if (character == '{') {
        _rootDelegate = MapPropertyDelegate(
          propertyPath: '',
          parserController: _controller,
        );
        _rootDelegate!.addCharacter(character);
      }

      if (character == "[") {
        _rootDelegate = ListPropertyDelegate(
          propertyPath: '',
          parserController: _controller,
        );
        _rootDelegate!.addCharacter(character);
      }

      continue;
    }

    _rootDelegate?.onChunkEnd();
  }
}

class JsonStreamParserController {
  JsonStreamParserController({required this.addPropertyChunk});

  final void Function({required String path, required String chunk})
  addPropertyChunk;
}
