import 'dart:async';

import 'package:json_stream_parser/classes/json_stream_parser.dart';
import 'package:json_stream_parser/classes/mixins.dart';

/// Delegates are not supposed to just hold states and data, but rather, mutate the master parser's state machine as characters are fed to them.
abstract class PropertyDelegate with Delegator {
  final String propertyPath;
  final JsonStreamParserController jsonStreamParserController;

  PropertyDelegate({
    required this.propertyPath,
    required this.jsonStreamParserController,
  });

  String newPath(String path) =>
      propertyPath.isEmpty ? path : '$propertyPath.$path';

  void emitToStream<T>(T value, {String? innerPath}) {
    jsonStreamParserController.addToPropertyStream<T>(
      propertyPath: propertyPath + (innerPath != null ? '.$innerPath' : ''),
      value: value,
    );
  }

  void addCharacter(String character) {
    throw UnimplementedError();
  }

  final Completer<void> _doneCompleter = Completer<void>();
  Future<void> get done => _doneCompleter.future;
  void close() {
    _doneCompleter.complete();
  }
}
