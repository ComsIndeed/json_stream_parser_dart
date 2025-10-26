import 'package:json_stream_parser/classes/property_stream_controller.dart';

abstract class PropertyStream {
  final PropertyStreamController _controller;

  PropertyStream({required PropertyStreamController controller})
    : _controller = controller;
}

///
/// "WHAT STUFF WOULD BE EXPOSED FROM THE STREAMERS?"
///

class StringPropertyStream extends PropertyStream {
  StringPropertyStream({required super.controller});
}

class NumberPropertyStream extends PropertyStream {
  NumberPropertyStream({required super.controller});
}

class NullPropertyStream extends PropertyStream {
  NullPropertyStream({required super.controller});
}

class BooleanPropertyStream extends PropertyStream {
  BooleanPropertyStream({required super.controller});
}

class ListPropertyStream extends PropertyStream {
  ListPropertyStream({required super.controller});
}

class MapPropertyStream extends PropertyStream {
  MapPropertyStream({required super.controller});
}
