import 'package:json_stream_parser/classes/property_stream.dart';

abstract class PropertyStreamController {
  abstract final PropertyStream propertyStream;
  bool _isClosed = false;
  bool get isClosed => _isClosed;

  void close() {
    _isClosed = true;
  }
}

///
/// ! PROPERTY CONTROLLERS
/// "WHAT STUFF SHOULD WE BE ABLE TO INPUT INTO THE STREAMERS?"
///

class StringPropertyStreamController extends PropertyStreamController {
  @override
  late final StringPropertyStream propertyStream;

  void addChunk(String chunk) {}

  StringPropertyStreamController() {
    propertyStream = StringPropertyStream(controller: this);
  }
}

class MapPropertyStreamController extends PropertyStreamController {
  @override
  late final MapPropertyStream propertyStream;

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

  NumberPropertyStreamController() {
    propertyStream = NumberPropertyStream(controller: this);
  }
}

class BooleanPropertyStreamController extends PropertyStreamController {
  @override
  late final BooleanPropertyStream propertyStream;

  BooleanPropertyStreamController() {
    propertyStream = BooleanPropertyStream(controller: this);
  }
}

class NullPropertyStreamController extends PropertyStreamController {
  @override
  late final NullPropertyStream propertyStream;

  NullPropertyStreamController() {
    propertyStream = NullPropertyStream(controller: this);
  }
}
