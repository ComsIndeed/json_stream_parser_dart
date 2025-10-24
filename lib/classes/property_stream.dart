import 'package:json_stream_parser/classes/property_delegates/property_delegate.dart';

abstract class PropertyStream {
  final PropertyDelegate _delegate;

  Future<Object> get future;
  Stream<Object> get stream;

  PropertyStream(PropertyDelegate delegate) : _delegate = delegate;
}

class MapPropertyStream extends PropertyStream {
  MapPropertyStream(super.delegate);

  @override
  Future<Object> get future {
    throw UnimplementedError();
  }

  @override
  Stream<Object> get stream {
    throw UnimplementedError();
  }
}

class ListPropertyStream extends PropertyStream {
  ListPropertyStream(super.delegate);

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
  StringPropertyStream(super.delegate);

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
  NumberPropertyStream(super.delegate);

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
  BooleanPropertyStream(super.delegate);

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
  NullPropertyStream(super.delegate);

  @override
  Future<Object> get future {
    throw UnimplementedError();
  }

  @override
  Stream<Object> get stream {
    throw UnimplementedError();
  }
}
