import 'dart:async';

import 'package:json_stream_parser/classes/property_stream.dart';

abstract class PropertyStreamController<T> {
  abstract final PropertyStream propertyStream;
  bool _isClosed = false;
  bool get isClosed => _isClosed;

  Completer<T> completer = Completer<T>();

  void onClose() {
    _isClosed = true;
  }

  void complete(T value) {
    if (!_isClosed) {
      completer.complete(value);
      onClose();
    }
  }
}

///
/// ! PROPERTY CONTROLLERS
/// "WHAT STUFF SHOULD WE BE ABLE TO INPUT INTO THE STREAMERS?"
///
/// VALUE ==> PROPERTY STREAMS
///

class StringPropertyStreamController extends PropertyStreamController<String> {
  @override
  late final StringPropertyStream propertyStream;

  String _buffer = "";
  void addChunk(String chunk) {
    _buffer += chunk;
    streamController.add(chunk);
  }

  final streamController = StreamController<String>();

  @override
  /// [value] will be ignored. The stream will emit the accumulated chunks instead.
  void complete(String value) {
    if (!_isClosed) {
      completer.complete(_buffer);
      streamController.close();
      onClose();
    }
  }

  StringPropertyStreamController() {
    propertyStream = StringPropertyStream(
      stream: streamController.stream,
      future: completer.future,
    );
  }
}

class MapPropertyStreamController
    extends PropertyStreamController<Map<String, Object?>> {
  @override
  late final MapPropertyStream propertyStream;

  MapPropertyStreamController() {
    propertyStream = MapPropertyStream(future: completer.future);
  }
}

class ListPropertyStreamController
    extends PropertyStreamController<List<Object?>> {
  @override
  late final ListPropertyStream propertyStream;

  ListPropertyStreamController() {
    propertyStream = ListPropertyStream(future: completer.future);
  }
}

class NumberPropertyStreamController extends PropertyStreamController<num> {
  @override
  late final NumberPropertyStream propertyStream;

  final streamController = StreamController<num>();

  NumberPropertyStreamController() {
    propertyStream = NumberPropertyStream(
      future: completer.future,
      stream: streamController.stream,
    );
  }
}

class BooleanPropertyStreamController extends PropertyStreamController<bool> {
  @override
  late final BooleanPropertyStream propertyStream;

  final streamController = StreamController<bool>();
  BooleanPropertyStreamController() {
    propertyStream = BooleanPropertyStream(
      future: completer.future,
      stream: streamController.stream,
    );
  }
}

class NullPropertyStreamController extends PropertyStreamController<Null> {
  @override
  late final NullPropertyStream propertyStream;

  final streamController = StreamController<Null>();

  NullPropertyStreamController() {
    propertyStream = NullPropertyStream(
      future: completer.future,
      stream: streamController.stream,
    );
  }
}
