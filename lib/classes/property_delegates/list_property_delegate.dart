import 'package:json_stream_parser/classes/property_delegates/property_delegate.dart';
import 'package:json_stream_parser/classes/property_stream_controller.dart';

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
    // Child has completed - this is just a signal
    // Don't change state or index here - wait for comma or bracket
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

    // Handle reading value state
    if (_state == ListParserState.readingValue) {
      // Check if child is done BEFORE feeding more characters
      if (_activeChildDelegate?.isDone ?? false) {
        _state = ListParserState.waitingForCommaOrEnd;
        // Don't return - fall through to process the character in the new state
      } else {
        _activeChildDelegate?.addCharacter(character);
        // Check again AFTER feeding - child might complete on this character
        if (_activeChildDelegate?.isDone ?? false) {
          _state = ListParserState.waitingForCommaOrEnd;
          // Don't return - check for comma/bracket in same iteration
        } else {
          return;
        }
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
                  as ListPropertyStreamController;

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

      // Handle closing bracket for empty array
      if (character == ']') {
        _completeList();
        return;
      }
    }

    // Handle waiting for comma or end state
    if (_state == ListParserState.waitingForCommaOrEnd) {
      if (character == ',') {
        // Finalize the completed child
        _activeChildDelegate = null;
        _index += 1;
        _state = ListParserState.waitingForValue;
        return;
      } else if (character == ']') {
        // Finalize the last child before completing
        _activeChildDelegate = null;
        _index += 1;
        _completeList();
        return;
      }
    }
  }

  void _completeList() async {
    isDone = true;

    // Collect all element values
    final List<dynamic> elements = [];
    for (int i = 0; i < _index; i++) {
      final elementPath = '$propertyPath[$i]';
      try {
        final controller = parserController.getPropertyStreamController(
          elementPath,
        );
        final value = await controller.completer.future;
        elements.add(value);
      } catch (e) {
        elements.add(null);
      }
    }

    parserController.addPropertyChunk<List<Object?>>(
      propertyPath: propertyPath,
      chunk: elements,
    );

    onComplete?.call();
  }
}

enum ListParserState { waitingForValue, readingValue, waitingForCommaOrEnd }
