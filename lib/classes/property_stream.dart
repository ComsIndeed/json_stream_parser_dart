abstract class PropertyStream<T> {
  Future<T> get future;
  Stream<T> get stream;
}
