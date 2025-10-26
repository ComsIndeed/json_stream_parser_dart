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

  void addChunk(String chunk) {
    throw UnimplementedError();
  }

  final streamController = StreamController<String>();

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

  void addChunk(String chunk) {
    throw UnimplementedError();
  }

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

  void complete(num number) {
    throw UnimplementedError();
  }

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

  void complete(bool value) {
    throw UnimplementedError();
  }

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

  void complete() {
    throw UnimplementedError();
  }

  final streamController = StreamController<Null>();

  NullPropertyStreamController() {
    propertyStream = NullPropertyStream(
      future: completer.future,
      stream: streamController.stream,
    );
  }
}
