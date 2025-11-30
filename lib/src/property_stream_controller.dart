import 'dart:async';

import 'json_stream_parser.dart';
import 'property_stream.dart';

abstract class PropertyStreamController<T> {
  abstract final PropertyStream propertyStream;
  bool _isClosed = false;
  bool get isClosed => _isClosed;

  Completer<T> completer = Completer<T>();

  PropertyStreamController({
    required this.parserController,
    required this.propertyPath,
  });
  final JsonStreamParserController parserController;
  final String propertyPath;

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

class StringPropertyStreamController extends PropertyStreamController<String> {
  @override
  late final StringPropertyStream propertyStream;

  String _buffer = "";
  void addChunk(String chunk) {
    if (!_isClosed) {
      _buffer += chunk;
      streamController.add(chunk);
    }
  }

  Stream<String> get liveStream => streamController.stream;

  Stream<String> createReplayableStream() async* {
    if (_buffer.isNotEmpty) {
      yield _buffer;
    }
    if (!_isClosed) {
      yield* streamController.stream;
    }
  }

  final streamController = StreamController<String>.broadcast();

  @override

  /// [value] will be ignored. The stream will emit the accumulated chunks instead.
  void complete(String value) {
    if (!_isClosed) {
      completer.complete(_buffer);
      streamController.close();
      onClose();
    }
  }

  StringPropertyStreamController({
    required super.parserController,
    required super.propertyPath,
  }) {
    propertyStream = StringPropertyStream(
      liveStream: liveStream,
      replayableStreamFactory: createReplayableStream,
      future: completer.future,
      parserController: parserController,
    );
  }
}

class MapPropertyStreamController
    extends PropertyStreamController<Map<String, Object?>> {
  @override
  late final MapPropertyStream propertyStream;

  final streamController = StreamController<Map<String, dynamic>>.broadcast();

  List<Map<String, dynamic>> _buffer = [];

  void addNew(Map<String, dynamic> map) {
    if (!_isClosed) {
      _buffer.add(map);
      streamController.add(map);
    }
  }

  Stream<Map<String, dynamic>> get liveStream => streamController.stream;

  Stream<Map<String, dynamic>> createReplayableStream() async* {
    // Take a snapshot of the buffer at subscription time
    final bufferSnapshot = List<Map<String, dynamic>>.from(_buffer);
    for (final item in bufferSnapshot) {
      yield item;
    }
    if (!_isClosed) {
      yield* streamController.stream;
    }
  }

  @override
  void complete(Map<String, Object?> value) {
    streamController.close();
    super.complete(value);
  }

  MapPropertyStreamController({
    required super.parserController,
    required super.propertyPath,
  }) {
    propertyStream = MapPropertyStream(
      future: completer.future,
      parserController: parserController,
      propertyPath: propertyPath,
      liveStream: liveStream,
      replayableStreamFactory: createReplayableStream,
    );
  }
}

class ListPropertyStreamController<T extends Object?>
    extends PropertyStreamController<List<T>> {
  @override
  late final ListPropertyStream<T> propertyStream;
  List<void Function(PropertyStream, int)> onElementCallbacks = [];

  final streamController = StreamController<List<T>>.broadcast();

  List<List<T>> _buffer = [];

  void addNew(List<T> list) {
    if (!_isClosed) {
      _buffer.add(list);
      streamController.add(list);
    }
  }

  Stream<List<T>> get liveStream => streamController.stream;

  Stream<List<T>> createReplayableStream() async* {
    // Take a snapshot of the buffer at subscription time
    final bufferSnapshot = List<List<T>>.from(_buffer);
    for (final item in bufferSnapshot) {
      yield item;
    }
    if (!_isClosed) {
      yield* streamController.stream;
    }
  }

  void addOnElementCallback(
    void Function(PropertyStream propertyStream, int index) callback,
  ) {
    onElementCallbacks.add(callback);
  }

  ListPropertyStreamController({
    required super.parserController,
    required super.propertyPath,
  }) {
    propertyStream = ListPropertyStream<T>(
      future: completer.future,
      parserController: parserController,
      propertyPath: propertyPath,
      liveStream: liveStream,
      replayableStreamFactory: createReplayableStream,
    );
  }

  @override
  void complete(covariant List<Object?> value) {
    addNew(List<T>.from(value));
    streamController.close();
    if (!_isClosed) {
      // Cast the list to List<T>
      // This handles the case where we receive a List<Object?> that needs to be List<T>
      final typedList = List<T>.from(value);
      completer.complete(typedList);
      onClose();
    }
  }
}

class NumberPropertyStreamController extends PropertyStreamController<num> {
  @override
  late final NumberPropertyStream propertyStream;

  final streamController = StreamController<num>();

  NumberPropertyStreamController({
    required super.parserController,
    required super.propertyPath,
  }) {
    propertyStream = NumberPropertyStream(
      parserController: parserController,
      future: completer.future,
      stream: streamController.stream,
    );
  }

  @override

  /// [value] will be ignored. The stream will emit the accumulated chunks instead.
  void complete(num value) {
    if (!_isClosed) {
      completer.complete(value);
      streamController.close();
      onClose();
    }
  }
}

class BooleanPropertyStreamController extends PropertyStreamController<bool> {
  @override
  late final BooleanPropertyStream propertyStream;

  final streamController = StreamController<bool>();
  BooleanPropertyStreamController({
    required super.parserController,
    required super.propertyPath,
  }) {
    propertyStream = BooleanPropertyStream(
      parserController: parserController,
      future: completer.future,
      stream: streamController.stream,
    );
  }

  @override

  /// [value] will be ignored. The stream will emit the accumulated chunks instead.
  void complete(bool value) {
    if (!_isClosed) {
      streamController.close();
      completer.complete(value);
      onClose();
    }
  }
}

class NullPropertyStreamController extends PropertyStreamController<Null> {
  @override
  late final NullPropertyStream propertyStream;

  final streamController = StreamController<Null>();

  NullPropertyStreamController({
    required super.parserController,
    required super.propertyPath,
  }) {
    propertyStream = NullPropertyStream(
      parserController: parserController,
      future: completer.future,
      stream: streamController.stream,
    );
  }

  @override

  /// [value] will be ignored. The stream will emit the accumulated chunks instead.
  void complete(Null value) {
    if (!_isClosed) {
      completer.complete(value);
      streamController.close();
      onClose();
    }
  }
}
