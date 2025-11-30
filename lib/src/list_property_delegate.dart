import 'dart:async';

import 'parse_event.dart';
import 'property_delegate.dart';
import 'property_stream.dart';
import 'property_stream_controller.dart';

class ListPropertyDelegate extends PropertyDelegate {
  ListPropertyDelegate({
    required super.propertyPath,
    required super.parserController,
    super.onComplete,
  });

  static const _valueFirstCharacters = [
    '"',
    '{',
    '[',
    't',
    'f',
    'n',
    '-',
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
  ];

  // State machine
  ListParserState _state = ListParserState.waitingForValue;

  // Element tracking
  int _index = 0;

  // Delegate management
  bool _isFirstCharacter = true;
  PropertyDelegate? _activeChildDelegate;

  // The current list being built
  List<dynamic> _currentList = [];
  StreamSubscription? _childSubscription;

  String get _currentElementPath => '$propertyPath[$_index]';

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
              as ListPropertyStreamController;
      controller.addNew(List<dynamic>.from(_currentList));
    } catch (_) {
      // List controller doesn't exist - no one is listening
    }
  }

  void onChildComplete() {
    // State management now happens inline in addCharacter
    // This callback is just for notification purposes
  }

  @override
  void onChunkEnd() {
    // Only call onChunkEnd on child if it's not done yet
    if (_activeChildDelegate != null && !_activeChildDelegate!.isDone) {
      _activeChildDelegate?.onChunkEnd();
    }

    // Only emit updates if someone is listening (i.e., if the list controller exists)
    try {
      final controller =
          parserController.getPropertyStreamController(propertyPath)
              as ListPropertyStreamController;
      controller.addNew(List<dynamic>.from(_currentList));
    } catch (_) {
      // List controller doesn't exist - no one is listening, so skip emission
    }
  }

  @override
  void addCharacter(String character) {
    // Handle opening bracket
    if (_isFirstCharacter && character == '[') {
      _isFirstCharacter = false;
      _state = ListParserState.waitingForValue;
      return;
    }

    // Skip whitespace when not reading a value
    if (_state != ListParserState.readingValue &&
        (character == ' ' ||
            character == '\t' ||
            character == '\n' ||
            character == '\r')) {
      return;
    }

    if (_state == ListParserState.readingValue) {
      // Store the delegate reference before calling addCharacter
      // because onComplete callback might clear it
      final childDelegate = _activeChildDelegate;
      childDelegate?.addCharacter(character);

      // If child completed, we need to reprocess this character
      // in case it's a delimiter (like comma for numbers)
      if (childDelegate?.isDone == true) {
        _activeChildDelegate = null;
        _index++;
        _state = ListParserState.waitingForCommaOrEnd;
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

    // Handle waiting for value state
    if (_state == ListParserState.waitingForValue) {
      if (_valueFirstCharacters.contains(character)) {
        // FIRST: Get the PropertyStream for this element (creates controller if needed)
        // This must happen BEFORE creating the delegate so callbacks can subscribe
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

        // Emit listElementStart event
        _emitLog(ParseEvent(
          type: ParseEventType.listElementStart,
          propertyPath: propertyPath,
          message: 'List element started at index $_index',
          data: _index,
        ));

        // Emit propertyStart for the element
        _emitLog(ParseEvent(
          type: ParseEventType.propertyStart,
          propertyPath: _currentElementPath,
          message:
              'Started parsing list element: $_currentElementPath (type: $streamType)',
        ));

        final elementStream = parserController.getPropertyStream(
          _currentElementPath,
          streamType,
        );

        // Add placeholder to current list at this index
        _currentList.add(null);
        final currentIndex = _index;

        // Cancel any previous subscription
        _childSubscription?.cancel();
        _childSubscription = null;

        // Set up a subscription to update the list when the child emits values
        // Only subscribe to types that can emit multiple events (String, Map, List)
        if (elementStream is MapPropertyStream) {
          _childSubscription = elementStream.stream.listen((value) {
            _currentList[currentIndex] = value;
            _emitUpdate();
          });
        } else if (elementStream is ListPropertyStream) {
          _childSubscription = elementStream.stream.listen((value) {
            _currentList[currentIndex] = value;
            _emitUpdate();
          });
        } else if (elementStream is StringPropertyStream) {
          _childSubscription = elementStream.stream.listen((value) {
            if (_currentList[currentIndex] == null) {
              _currentList[currentIndex] = value;
            } else {
              _currentList[currentIndex] = _currentList[currentIndex] + value;
            }
            _emitUpdate();
          });
        }
        // Note: We don't subscribe to Number, Boolean, or Null streams
        // because they only emit once and we get their value from the completer

        // Invoke onElement callbacks if anyone is listening (i.e., if the list controller exists)
        // Note: The list controller only exists if someone called getListProperty() on this path
        try {
          final listController =
              parserController.getPropertyStreamController(propertyPath)
                  as ListPropertyStreamController<Object?>;

          for (final callback in listController.onElementCallbacks) {
            callback(elementStream, _index);
          }
        } catch (_) {
          // List controller doesn't exist - no one is listening to onElement, so skip
        }

        // THEN create delegate - it will use the existing controller via putIfAbsent
        final delegate = createDelegate(
          character,
          propertyPath: _currentElementPath,
          jsonStreamParserController: parserController,
          onComplete: onChildComplete,
        );

        _activeChildDelegate = delegate;
        _activeChildDelegate!.addCharacter(character);

        _state = ListParserState.readingValue;
        return;
      }

      if (character == ']') {
        _completeList();
        return;
      }
    }

    if (_state == ListParserState.waitingForCommaOrEnd) {
      if (character == ',') {
        _state = ListParserState.waitingForValue;
        return;
      } else if (character == ']') {
        _completeList();
        return;
      }
    }
  }

  void _completeList() async {
    isDone = true;

    final List<Object?> elements = [];
    for (int i = 0; i < _index; i++) {
      final elementPath = '$propertyPath[$i]';
      try {
        final controller = parserController.getPropertyStreamController(
          elementPath,
        );
        final value = await controller.completer.future;
        elements.add(value);

        // Emit propertyComplete for each element
        _emitLog(ParseEvent(
          type: ParseEventType.propertyComplete,
          propertyPath: elementPath,
          message: 'List element completed: $elementPath',
          data: value,
        ));
      } catch (e) {
        // Controller doesn't exist - this shouldn't happen in normal operation
        // but we'll handle it gracefully
        elements.add(null);
      }
    }

    // Complete the list controller with the accumulated elements
    try {
      final listController = parserController.getPropertyStreamController(
        propertyPath,
      );
      listController.complete(elements);

      // Emit propertyComplete for the list itself
      _emitLog(ParseEvent(
        type: ParseEventType.propertyComplete,
        propertyPath: propertyPath,
        message: 'List completed: $propertyPath',
        data: elements,
      ));
    } catch (e) {
      // If there's no list controller, it means no one subscribed to this list
      // This is fine - we just won't complete anything
    }

    onComplete?.call();
  }
}

enum ListParserState { waitingForValue, readingValue, waitingForCommaOrEnd }
