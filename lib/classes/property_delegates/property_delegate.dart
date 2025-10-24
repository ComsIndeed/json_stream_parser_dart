import 'package:json_stream_parser/classes/json_stream_parser.dart';

abstract class PropertyDelegate {
  final String propertyPath;
  final JsonStreamParserController controller;

  PropertyDelegate({required this.propertyPath, required this.controller});

  String newPath(String path) =>
      propertyPath.isEmpty ? path : '$propertyPath.$path';

  void input(String character) {}
}
