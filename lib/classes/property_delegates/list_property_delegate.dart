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
    // State management now happens inline in addCharacter
    // This callback is just for notification purposes
  }

  @override
  void onChunkEnd() {
    _activeChildDelegate?.onChunkEnd();
  }

  @override
  void addCharacter(String character) {
    print("\nSTATE: ${_state.name}\nCHARACTER: |$character|\n");
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
      _activeChildDelegate?.addCharacter(character);

      // If child completed, we need to reprocess this character
      // in case it's a delimiter (like comma for numbers)
      if (_activeChildDelegate?.isDone == true) {
        _activeChildDelegate = null;
        _index++;
        _state = ListParserState.waitingForCommaOrEnd;
        // Don't return - reprocess the character in the new state
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

        print('GOT: $streamType for $character');

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
        print('GOT COMMA');
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
