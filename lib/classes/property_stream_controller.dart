import 'package:json_stream_parser/classes/property_stream.dart';

abstract class PropertyStreamController {
  abstract final PropertyStream propertyStream;
  bool _isClosed = false;
  bool get isClosed => _isClosed;

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

class StringPropertyStreamController extends PropertyStreamController {
  @override
  late final StringPropertyStream propertyStream;

  void addChunk(String chunk) {
    throw UnimplementedError();
  }

  StringPropertyStreamController() {
    propertyStream = StringPropertyStream(controller: this);
  }
}

class MapPropertyStreamController extends PropertyStreamController {
  @override
  late final MapPropertyStream propertyStream;

  void addChunk(String chunk) {
    throw UnimplementedError();
  }

  MapPropertyStreamController() {
    propertyStream = MapPropertyStream(controller: this);
  }
}

class ListPropertyStreamController extends PropertyStreamController {
  @override
  late final ListPropertyStream propertyStream;

  ListPropertyStreamController() {
    propertyStream = ListPropertyStream(controller: this);
  }
}

class NumberPropertyStreamController extends PropertyStreamController {
  @override
  late final NumberPropertyStream propertyStream;

  void complete(num number) {
    throw UnimplementedError();
  }

  NumberPropertyStreamController() {
    propertyStream = NumberPropertyStream(controller: this);
  }
}

class BooleanPropertyStreamController extends PropertyStreamController {
  @override
  late final BooleanPropertyStream propertyStream;

  void complete(bool value) {
    throw UnimplementedError();
  }

  BooleanPropertyStreamController() {
    propertyStream = BooleanPropertyStream(controller: this);
  }
}

class NullPropertyStreamController extends PropertyStreamController {
  @override
  late final NullPropertyStream propertyStream;

  void complete() {
    throw UnimplementedError();
  }

  NullPropertyStreamController() {
    propertyStream = NullPropertyStream(controller: this);
  }
}
