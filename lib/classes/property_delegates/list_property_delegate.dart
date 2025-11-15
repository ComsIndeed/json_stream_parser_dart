import 'package:llm_json_stream/classes/property_delegates/property_delegate.dart';
import 'package:llm_json_stream/classes/property_stream_controller.dart';

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

  String get _currentElementPath => '$propertyPath[$_index]';

  void onChildComplete() {
    // State management now happens inline in addCharacter
    // This callback is just for notification purposes
  }

  @override
  void onChunkEnd() {
    if (_activeChildDelegate != null && !_activeChildDelegate!.isDone) {
      _activeChildDelegate?.onChunkEnd();
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
        final elementStream = parserController.getPropertyStream(
          _currentElementPath,
          streamType,
        );

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
    } catch (e) {
      // If there's no list controller, it means no one subscribed to this list
      // This is fine - we just won't complete anything
    }

    onComplete?.call();
  }
}

enum ListParserState { waitingForValue, readingValue, waitingForCommaOrEnd }
