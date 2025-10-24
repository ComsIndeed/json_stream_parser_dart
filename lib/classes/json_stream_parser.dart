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

  void _parseChunk(String chunk) {}
}

class JsonStreamParserController {}
