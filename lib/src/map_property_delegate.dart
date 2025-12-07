// ignore_for_file: prefer_final_fields

import 'dart:async';

import 'list_property_delegate.dart';
import 'parse_event.dart';
import 'property_delegate.dart';
import 'property_stream_controller.dart';
import 'property_stream.dart';

class MapPropertyDelegate extends PropertyDelegate {
  MapPropertyDelegate({
    required super.propertyPath,
    required super.parserController,
    super.onComplete,
  });

  MapParserState _state = MapParserState.waitingForKey;

  bool _firstCharacter = true;
  final StringBuffer _keyBuffer = StringBuffer();
  PropertyDelegate? _activeChildDelegate;

  // Track all keys that have been parsed
  List<String> _keys = [];

  // The current map being built
  Map<String, dynamic> _currentMap = {};
  StreamSubscription? _childSubscription;

  void _emitLog(ParseEvent event) {
    // Emit to the parser's global log
    parserController.emitLog(event);

    // Also emit to any property-specific log callbacks
    try {
      final controller =
          parserController.getPropertyStreamController(propertyPath);
      controller.emitLog(event);
    } catch (_) {
      // Controller doesn't exist yet
    }
  }

  void _emitUpdate() {
    try {
      final controller =
          parserController.getPropertyStreamController(propertyPath)
              as MapPropertyStreamController;
      controller.addNew(Map<String, dynamic>.from(_currentMap));
    } catch (_) {
      // Controller doesn't exist - no one is listening
    }
  }

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

    final controller =
        parserController.getPropertyStreamController(propertyPath)
            as MapPropertyStreamController;
    controller.addNew(Map<String, dynamic>.from(_currentMap));
  }

  @override
  void addCharacter(String character) {
    if (_state == MapParserState.readingKey) {
      if (character == '"') {
        _state = MapParserState.waitingForValue;
        return;
      } else {
        _keyBuffer.write(character);
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
        if (childDelegate is ListPropertyDelegate ||
            childDelegate is MapPropertyDelegate) {
          return; // Don't reprocess - child consumed the closing bracket
        }
        // For other types (numbers, strings, etc), reprocess the delimiter
      } else {
        return;
      }
    }

    if (_state == MapParserState.waitingForValue) {
      if (character == " " || character == ":") return;
      // Add this key to our list of keys
      final currentKeyString = _keyBuffer.toString();
      _keys.add(currentKeyString);

      // Emit mapKeyDiscovered event
      _emitLog(ParseEvent(
        type: ParseEventType.mapKeyDiscovered,
        propertyPath: propertyPath,
        message: 'Discovered key: $currentKeyString',
        data: currentKeyString,
      ));

      _childSubscription?.cancel();
      _childSubscription = null;

      // FIRST: Determine the type and create the PropertyStream
      // This ensures the controller exists before the delegate tries to use it
      final childPath = newPath(currentKeyString);
      final Type streamType;
      if (character == '"') {
        streamType = String;
      } else if (character == '{') {
        streamType = Map;
      } else if (character == '[') {
        streamType = List;
      } else if (character == 't' || character == 'f') {
        streamType = bool;
      } else if (character == 'n') {
        streamType = Null;
      } else {
        streamType = num;
      }

      // Emit propertyStart event for the child property
      _emitLog(ParseEvent(
        type: ParseEventType.propertyStart,
        propertyPath: childPath,
        message: 'Started parsing property: $childPath (type: $streamType)',
      ));

      final propertyStream =
          parserController.getPropertyStream(childPath, streamType);
      _currentMap[currentKeyString] = null;

      // Set up a subscription to update the map when the child emits values
      // Only subscribe to types that can emit multiple events (String, Map, List)
      if (propertyStream is MapPropertyStream) {
        _childSubscription = propertyStream.stream.listen((value) {
          _currentMap[currentKeyString] = value;
          _emitUpdate();
        });
      } else if (propertyStream is ListPropertyStream) {
        _childSubscription = propertyStream.stream.listen((value) {
          _currentMap[currentKeyString] = value;
          _emitUpdate();
        });
      } else if (propertyStream is StringPropertyStream) {
        _childSubscription = propertyStream.stream.listen((value) {
          if (_currentMap[currentKeyString] == null) {
            _currentMap[currentKeyString] = value;
          } else {
            _currentMap[currentKeyString] =
                _currentMap[currentKeyString] + value;
          }
          _emitUpdate();
        });
      }
      // Note: We don't subscribe to Number, Boolean, or Null streams
      // because they only emit once and we get their value from the completer

      // Invoke onProperty callbacks if anyone is listening (i.e., if the map controller exists)
      // Note: The map controller only exists if someone called getMapProperty() on this path
      try {
        final mapController =
            parserController.getPropertyStreamController(propertyPath)
                as MapPropertyStreamController;

        for (final callback in mapController.onPropertyCallbacks) {
          callback(propertyStream, currentKeyString);
        }
      } catch (_) {
        // Map controller doesn't exist - no one is listening to onProperty, so skip
      }

      // THEN: Create child delegate with a closure that checks if it's still active
      PropertyDelegate? childDelegate;
      childDelegate = createDelegate(
        character,
        propertyPath: childPath,
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
        _keyBuffer.clear();
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

  void _completeMap() async {
    isDone = true;

    // Build the map by collecting values from child controllers
    final Map<String, Object?> map = {};
    for (final key in _keys) {
      final childPath = newPath(key);
      try {
        final controller = parserController.getPropertyStreamController(
          childPath,
        );
        final value = await controller.completer.future;
        map[key] = value;

        // Emit propertyComplete for each child
        _emitLog(ParseEvent(
          type: ParseEventType.propertyComplete,
          propertyPath: childPath,
          message: 'Property completed: $childPath',
          data: value,
        ));
      } catch (e) {
        // Controller doesn't exist - this shouldn't happen in normal operation
        // but we'll handle it gracefully
        map[key] = null;
      }
    }

    // Complete the map controller if it exists
    try {
      final mapController = parserController.getPropertyStreamController(
        propertyPath,
      );
      mapController.complete(map);

      // Emit propertyComplete for the map itself
      _emitLog(ParseEvent(
        type: ParseEventType.propertyComplete,
        propertyPath: propertyPath,
        message: 'Map completed: $propertyPath',
        data: map,
      ));
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
