import 'package:json_stream_parser/classes/json_stream_parser.dart';

abstract class PropertyDelegate {
  final String propertyPath;
  final JsonStreamParserController controller;

  PropertyDelegate(this.propertyPath, this.controller);

  String newPath(String path) =>
      propertyPath.isEmpty ? path : '$propertyPath.$path';

  void input(String character);
}

class MapPropertyDelegate {}

class StringPropertyDelegate {}

class NumberPropertyDelegate {}

class BooleanPropertyDelegate {}

class NullPropertyDelegate {}

class ListPropertyDelegate {}
