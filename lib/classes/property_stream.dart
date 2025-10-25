import 'dart:async';

import 'package:meta/meta.dart';

abstract class PropertyStream<T> {
  Future<Object> get future;
  Stream<Object> get stream;

  @internal
  final PropertyStreamController<T> controller = PropertyStreamController<T>();
}

class PropertyStreamController<T> {
  final _streamController = StreamController<T>.broadcast();

  void add(T value) {
    _streamController.add(value);
  }

  Stream<T> get stream => _streamController.stream;

  Future<T> get future => _streamController.stream.first;
}

class MapPropertyStream extends PropertyStream {
  @override
  Future<Object> get future {
    throw UnimplementedError();
  }

  @override
  Stream<Object> get stream {
    throw UnimplementedError("Use getPropertyStream<T> instead.");
  }

  Stream<T> getPropertyStream<T>(String propertyPath) {
    throw UnimplementedError();
  }
}

class ListPropertyStream extends PropertyStream {
  @override
  Future<Object> get future {
    throw UnimplementedError();
  }

  @override
  Stream<Object> get stream {
    throw UnimplementedError();
  }
}

class StringPropertyStream extends PropertyStream {
  @override
  Future<Object> get future {
    throw UnimplementedError();
  }

  @override
  Stream<Object> get stream {
    throw UnimplementedError();
  }
}

class NumberPropertyStream extends PropertyStream {
  @override
  Future<Object> get future {
    throw UnimplementedError();
  }

  @override
  Stream<Object> get stream {
    throw UnimplementedError();
  }
}

class BooleanPropertyStream extends PropertyStream {
  @override
  Future<Object> get future {
    throw UnimplementedError();
  }

  @override
  Stream<Object> get stream {
    throw UnimplementedError();
  }
}

class NullPropertyStream extends PropertyStream {
  @override
  Future<Object> get future {
    throw UnimplementedError();
  }

  @override
  Stream<Object> get stream {
    throw UnimplementedError();
  }
}
