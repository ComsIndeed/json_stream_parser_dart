abstract class PropertyStream {
  Future<Object> get future;

  PropertyStream();
}

class MapPropertyStream implements PropertyStream {
  @override
  Future<Object> get future => throw UnimplementedError();

  MapPropertyStream();
}

class StringPropertyStream implements PropertyStream {
  @override
  Future<Object> get future => throw UnimplementedError();
  Stream<String> get stream => throw UnimplementedError();

  StringPropertyStream();
}


