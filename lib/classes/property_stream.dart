import 'dart:async';

abstract class PropertyStream<T> {
  final Future<T> _future;

  Future<T> get future => _future;

  PropertyStream({required Future<T> future}) : _future = future;
}

///
/// "WHAT STUFF WOULD BE EXPOSED FROM THE STREAMERS?"
///

class StringPropertyStream extends PropertyStream<String> {
  StringPropertyStream({required super.future, required Stream<String> stream})
    : _stream = stream;

  final Stream<String> _stream;
  Stream<String> get stream => _stream;
}

class NumberPropertyStream extends PropertyStream<num> {
  NumberPropertyStream({required super.future, required Stream<num> stream})
    : _stream = stream;

  final Stream<num> _stream;
  Stream<num> get stream => _stream;
}

class NullPropertyStream extends PropertyStream<Null> {
  NullPropertyStream({required super.future, required Stream<Null> stream})
    : _stream = stream;

  final Stream<Null> _stream;
  Stream<Null> get stream => _stream;
}

class BooleanPropertyStream extends PropertyStream<bool> {
  BooleanPropertyStream({required super.future, required Stream<bool> stream})
    : _stream = stream;

  final Stream<bool> _stream;
  Stream<bool> get stream => _stream;
}

class ListPropertyStream extends PropertyStream<List<Object?>> {
  ListPropertyStream({required super.future});

  void onElement(void Function(int, Object?) handleElement) {
    throw UnimplementedError();
  }

  StringPropertyStream getStringProperty(String propertyPath) {
    throw UnimplementedError();
  }

  BooleanPropertyStream getBooleanProperty(String propertyPath) {
    throw UnimplementedError();
  }

  NumberPropertyStream getNumberProperty(String propertyPath) {
    throw UnimplementedError();
  }

  NullPropertyStream getNullProperty(String propertyPath) {
    throw UnimplementedError();
  }

  MapPropertyStream getMapProperty(String propertyPath) {
    throw UnimplementedError();
  }

  ListPropertyStream getListProperty(String propertyPath) {
    throw UnimplementedError();
  }
}

class MapPropertyStream extends PropertyStream<Map<String, Object?>> {
  MapPropertyStream({required super.future});

  StringPropertyStream getStringProperty(String propertyPath) {
    throw UnimplementedError();
  }

  BooleanPropertyStream getBooleanProperty(String propertyPath) {
    throw UnimplementedError();
  }

  NumberPropertyStream getNumberProperty(String propertyPath) {
    throw UnimplementedError();
  }

  NullPropertyStream getNullProperty(String propertyPath) {
    throw UnimplementedError();
  }

  MapPropertyStream getMapProperty(String propertyPath) {
    throw UnimplementedError();
  }

  ListPropertyStream getListProperty(String propertyPath) {
    throw UnimplementedError();
  }
}
