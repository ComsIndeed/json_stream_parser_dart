import 'dart:async';

import 'package:json_stream_parser/classes/json_stream_parser.dart';
import 'package:json_stream_parser/classes/property_stream_controller.dart';

abstract class PropertyStream<T> {
  final Future<T> _future;

  Future<T> get future => _future;
  final JsonStreamParserController _parserController;

  PropertyStream({
    required Future<T> future,
    required JsonStreamParserController parserController,
  })  : _future = future,
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

class ListPropertyStream<T extends Object?> extends PropertyStream<List<T>> {
  final String _propertyPath;

  ListPropertyStream({
    required super.future,
    required super.parserController,
    required String propertyPath,
  }) : _propertyPath = propertyPath;

  void onElement(
    void Function(PropertyStream propertyStream, int index) callback,
  ) {
    // Add callback to the controller's list, not our local copy
    final controller =
        _parserController.getPropertyStreamController(_propertyPath)
            as ListPropertyStreamController<T>;
    controller.addOnElementCallback(callback);
  }

  StringPropertyStream getStringProperty(String key) {
    // For array indices like "[0]", don't add a dot separator
    final fullPath = _propertyPath.isEmpty
        ? key
        : (key.startsWith('[') ? '$_propertyPath$key' : '$_propertyPath.$key');
    return _parserController.getPropertyStream(fullPath, String)
        as StringPropertyStream;
  }

  BooleanPropertyStream getBooleanProperty(String key) {
    final fullPath = _propertyPath.isEmpty
        ? key
        : (key.startsWith('[') ? '$_propertyPath$key' : '$_propertyPath.$key');
    return _parserController.getPropertyStream(fullPath, bool)
        as BooleanPropertyStream;
  }

  NumberPropertyStream getNumberProperty(String key) {
    final fullPath = _propertyPath.isEmpty
        ? key
        : (key.startsWith('[') ? '$_propertyPath$key' : '$_propertyPath.$key');
    return _parserController.getPropertyStream(fullPath, num)
        as NumberPropertyStream;
  }

  NullPropertyStream getNullProperty(String key) {
    final fullPath = _propertyPath.isEmpty
        ? key
        : (key.startsWith('[') ? '$_propertyPath$key' : '$_propertyPath.$key');
    return _parserController.getPropertyStream(fullPath, Null)
        as NullPropertyStream;
  }

  MapPropertyStream getMapProperty(String key) {
    final fullPath = _propertyPath.isEmpty
        ? key
        : (key.startsWith('[') ? '$_propertyPath$key' : '$_propertyPath.$key');
    return _parserController.getPropertyStream(fullPath, Map)
        as MapPropertyStream;
  }

  ListPropertyStream<E> getListProperty<E extends Object?>(String key) {
    final fullPath = _propertyPath.isEmpty
        ? key
        : (key.startsWith('[') ? '$_propertyPath$key' : '$_propertyPath.$key');
    return _parserController.getPropertyStream(fullPath, List)
        as ListPropertyStream<E>;
  }
}

class MapPropertyStream extends PropertyStream<Map<String, Object?>> {
  final String _propertyPath;

  MapPropertyStream({
    required super.future,
    required super.parserController,
    required String propertyPath,
  }) : _propertyPath = propertyPath;

  StringPropertyStream getStringProperty(String key) {
    final fullPath = _propertyPath.isEmpty ? key : '$_propertyPath.$key';
    return _parserController.getPropertyStream(fullPath, String)
        as StringPropertyStream;
  }

  BooleanPropertyStream getBooleanProperty(String key) {
    final fullPath = _propertyPath.isEmpty ? key : '$_propertyPath.$key';
    return _parserController.getPropertyStream(fullPath, bool)
        as BooleanPropertyStream;
  }

  NumberPropertyStream getNumberProperty(String key) {
    final fullPath = _propertyPath.isEmpty ? key : '$_propertyPath.$key';
    return _parserController.getPropertyStream(fullPath, num)
        as NumberPropertyStream;
  }

  NullPropertyStream getNullProperty(String key) {
    final fullPath = _propertyPath.isEmpty ? key : '$_propertyPath.$key';
    return _parserController.getPropertyStream(fullPath, Null)
        as NullPropertyStream;
  }

  MapPropertyStream getMapProperty(String key) {
    final fullPath = _propertyPath.isEmpty ? key : '$_propertyPath.$key';
    return _parserController.getPropertyStream(fullPath, Map)
        as MapPropertyStream;
  }

  ListPropertyStream<E> getListProperty<E extends Object?>(String key) {
    final fullPath = _propertyPath.isEmpty ? key : '$_propertyPath.$key';
    return _parserController.getPropertyStream(fullPath, List)
        as ListPropertyStream<E>;
  }
}
