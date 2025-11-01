import 'dart:async';

import 'package:json_stream_parser/classes/json_stream_parser.dart';

abstract class PropertyStream<T> {
  final Future<T> _future;

  Future<T> get future => _future;
  final JsonStreamParserController _parserController;

  PropertyStream({
    required Future<T> future,
    required JsonStreamParserController parserController,
  }) : _future = future,
       _parserController = parserController;
}

///
/// "WHAT STUFF WOULD BE EXPOSED FROM THE STREAMERS?"
///

class StringPropertyStream extends PropertyStream<String> {
  StringPropertyStream({
    required super.future,
    required Stream<String> stream,
    required super.parserController,
  }) : _stream = stream;

  final Stream<String> _stream;
  Stream<String> get stream => _stream;
}

class NumberPropertyStream extends PropertyStream<num> {
  NumberPropertyStream({
    required super.future,
    required Stream<num> stream,
    required super.parserController,
  }) : _stream = stream;

  final Stream<num> _stream;
  Stream<num> get stream => _stream;
}

class NullPropertyStream extends PropertyStream<Null> {
  NullPropertyStream({
    required super.future,
    required Stream<Null> stream,
    required super.parserController,
  }) : _stream = stream;

  final Stream<Null> _stream;
  Stream<Null> get stream => _stream;
}

class BooleanPropertyStream extends PropertyStream<bool> {
  BooleanPropertyStream({
    required super.future,
    required Stream<bool> stream,
    required super.parserController,
  }) : _stream = stream;

  final Stream<bool> _stream;
  Stream<bool> get stream => _stream;
}

class ListPropertyStream extends PropertyStream<List<Object?>> {
  ListPropertyStream({required super.future, required super.parserController});

  void onElement(void Function(int, Object?) handleElement) {
    throw UnimplementedError();
  }

  StringPropertyStream getStringProperty(String propertyPath) {
    return _parserController
            .getPropertyStreamController(propertyPath)
            .propertyStream
        as StringPropertyStream;
  }

  BooleanPropertyStream getBooleanProperty(String propertyPath) {
    return _parserController
            .getPropertyStreamController(propertyPath)
            .propertyStream
        as BooleanPropertyStream;
  }

  NumberPropertyStream getNumberProperty(String propertyPath) {
    return _parserController
            .getPropertyStreamController(propertyPath)
            .propertyStream
        as NumberPropertyStream;
  }

  NullPropertyStream getNullProperty(String propertyPath) {
    return _parserController
            .getPropertyStreamController(propertyPath)
            .propertyStream
        as NullPropertyStream;
  }

  MapPropertyStream getMapProperty(String propertyPath) {
    return _parserController
            .getPropertyStreamController(propertyPath)
            .propertyStream
        as MapPropertyStream;
  }

  ListPropertyStream getListProperty(String propertyPath) {
    return _parserController
            .getPropertyStreamController(propertyPath)
            .propertyStream
        as ListPropertyStream;
  }
}

class MapPropertyStream extends PropertyStream<Map<String, Object?>> {
  MapPropertyStream({required super.future, required super.parserController});

  StringPropertyStream getStringProperty(String propertyPath) {
    return _parserController
            .getPropertyStreamController(propertyPath)
            .propertyStream
        as StringPropertyStream;
  }

  BooleanPropertyStream getBooleanProperty(String propertyPath) {
    return _parserController
            .getPropertyStreamController(propertyPath)
            .propertyStream
        as BooleanPropertyStream;
  }

  NumberPropertyStream getNumberProperty(String propertyPath) {
    return _parserController
            .getPropertyStreamController(propertyPath)
            .propertyStream
        as NumberPropertyStream;
  }

  NullPropertyStream getNullProperty(String propertyPath) {
    return _parserController
            .getPropertyStreamController(propertyPath)
            .propertyStream
        as NullPropertyStream;
  }

  MapPropertyStream getMapProperty(String propertyPath) {
    return _parserController
            .getPropertyStreamController(propertyPath)
            .propertyStream
        as MapPropertyStream;
  }

  ListPropertyStream getListProperty(String propertyPath) {
    return _parserController
            .getPropertyStreamController(propertyPath)
            .propertyStream
        as ListPropertyStream;
  }
}
