// ignore_for_file: prefer_final_fields

import 'package:streaming_json_parser/classes/property_delegates/property_delegate.dart';

class MapPropertyDelegate extends PropertyDelegate {
  // * String propertyPath

  // * JsonStreamParserController jsonStreamParserController

  MapPropertyDelegate({
    required super.propertyPath,
    required super.parserController,
    super.onComplete,
  });

  MapParserState _state = MapParserState.waitingForKey;

  bool _firstCharacter = true;
  String _keyBuffer = "";
  PropertyDelegate? _activeChildDelegate;

  void onChildComplete() {
    _activeChildDelegate = null;
    // Transition state to allow parsing to continue
    if (_state == MapParserState.readingValue) {
      _state = MapParserState.waitingForCommaOrEnd;
    }
  }

  @override
  void onChunkEnd() {
    // Only call onChunkEnd on child if it's not done yet
    if (_activeChildDelegate != null && !_activeChildDelegate!.isDone) {
      _activeChildDelegate?.onChunkEnd();
    }
    // Maps don't emit chunks - they just complete with an empty map at the end
  }

  @override
  void addCharacter(String character) {
    // Debug logging disabled to reduce noise
    // print(
    //   'MAP[$propertyPath] State: $_state | Char: |$character| | KeyBuffer: |$_keyBuffer| | ChildDone: ${_activeChildDelegate?.isDone}',
    // );

    if (_state == MapParserState.readingKey) {
      if (character == '"') {
        _state = MapParserState.waitingForValue;
        return;
      } else {
        _keyBuffer += character;
        return;
      }
    }

    if (_state == MapParserState.readingValue) {
      // Store the delegate reference before calling addCharacter
      // because onComplete callback might clear it
      final childDelegate = _activeChildDelegate;
      childDelegate?.addCharacter(character);
      final childIsDone = childDelegate?.isDone ?? false;
      if (childIsDone) {
        _state = MapParserState.waitingForCommaOrEnd;
        _activeChildDelegate = null;
        // Only reprocess if the child is NOT a list or map
        // (lists and maps consume their own closing brackets)
        final childType = childDelegate.runtimeType.toString();
        if (childType == 'ListPropertyDelegate' ||
            childType == 'MapPropertyDelegate') {
          return; // Don't reprocess - child consumed the closing bracket
        }
        // For other types (numbers, strings, etc), reprocess the delimiter
      } else {
        return;
      }
    }

    if (_state == MapParserState.waitingForValue) {
      if (character == " " || character == ":") return;
      // Create child delegate with a closure that checks if it's still active
      PropertyDelegate? childDelegate;
      childDelegate = createDelegate(
        character,
        propertyPath: newPath(_keyBuffer),
        jsonStreamParserController: parserController,
        onComplete: () {
          // Only notify parent if this child is still the active one
          if (_activeChildDelegate == childDelegate) {
            onChildComplete();
          }
        },
      );
      _activeChildDelegate = childDelegate;
      _activeChildDelegate!.addCharacter(character);
      _state = MapParserState.readingValue;
      return;
    }

    if (_firstCharacter && character == '{') {
      _firstCharacter = false;
      return;
    }

    if (_state == MapParserState.waitingForCommaOrEnd) {
      // Skip whitespace
      if (character == ' ' ||
          character == '\t' ||
          character == '\n' ||
          character == '\r') {
        return;
      }
      if (character == ',') {
        _state = MapParserState.waitingForKey;
        _keyBuffer = "";
        return;
      } else if (character == '}') {
        _completeMap();
        return;
      }
    }

    if (_state == MapParserState.waitingForKey) {
      // Skip whitespace
      if (character == ' ' ||
          character == '\t' ||
          character == '\n' ||
          character == '\r') {
        return;
      }
      if (character == '"') {
        _state = MapParserState.readingKey;
        return;
      }
      if (character == "}") {
        _completeMap();
        return;
      }
    }

    return;
  }

  void _completeMap() {
    isDone = true;

    // Complete the map controller if it exists
    try {
      final mapController = parserController.getPropertyStreamController(
        propertyPath,
      );
      // Create an empty map - the actual values are accessed through child controllers
      mapController.complete(<String, Object?>{});
    } catch (e) {
      // If there's no map controller, it means no one subscribed to this map
      // This is fine - we just won't complete anything
    }

    onComplete?.call();
  }
}

enum MapParserState {
  waitingForKey,
  readingKey,
  waitingForValue,
  readingValue,
  waitingForCommaOrEnd,
}
