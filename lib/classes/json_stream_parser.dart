import 'package:json_stream_parser/classes/property_delegates/list_property_delegate.dart';
import 'package:json_stream_parser/classes/property_delegates/map_property_delegate.dart';
import 'package:json_stream_parser/classes/property_delegates/property_delegate.dart';
import 'package:json_stream_parser/classes/property_stream.dart';

class JsonStreamParser {
  JsonStreamParser(Stream<String> stream) : _stream = stream {
    _stream.listen(_parseChunk);
  }

  // * Exposeds
  void getProperty() {}

  // * Fields
  final Stream<String> _stream;

  // * Memories
  final Map<String, PropertyStream> _properties = {};

  // * States

  // * Helpers
  final _controller = JsonStreamParserController();

  void _parseChunk(String chunk) {
    for (final character in chunk.split('')) {
      switch (character) {
        case '{':
          final delegate = MapPropertyDelegate(
            propertyPath: "",
            controller: _controller,
          );
          _properties[delegate.propertyPath] = MapPropertyStream(delegate);
          break;
        case '[':
          final delegate = ListPropertyDelegate(
            propertyPath: "",
            controller: _controller,
          );
          _properties[delegate.propertyPath] = ListPropertyStream(delegate);
          break;
        default:
          break;
      }
    }
  }
}

class JsonStreamParserController {}
