import 'package:json_stream_parser/classes/property_delegates/property_delegate.dart';
import 'package:json_stream_parser/classes/property_stream.dart';

class ListPropertyDelegate extends PropertyDelegate {
  ListPropertyDelegate({
    required super.propertyPath,
    required super.parserController,
    super.onComplete,
    this.onElementCallbacks = const [],
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

  final List<void Function(PropertyStream)> onElementCallbacks;

  void onChildComplete() {
    _isReadingValue = false;
    _activeChildDelegate = null;
    _index += 1;
  }

  bool _isFirstCharacter = true;
  bool _isReadingValue = false;
  PropertyDelegate? _activeChildDelegate;

  int _index = 0;
  String get _currentElementPath => '$propertyPath[$_index]';

  @override
  void addCharacter(String character) {
    if (_isFirstCharacter && character == '[') {
      _isFirstCharacter = false;
      return;
    }

    if (!_isReadingValue && _valueFirstCharacters.contains(character)) {
      _isReadingValue = true;
      final delegate = createDelegate(
        character,
        propertyPath: _currentElementPath,
        jsonStreamParserController: parserController,
        onComplete: onChildComplete,
      );
      for (final callback in onElementCallbacks) {
        final controller = parserController.getPropertyStreamController(
          _currentElementPath,
        );
        callback(controller.propertyStream);
      }
      _activeChildDelegate = delegate;
    }

    if (_isReadingValue) {
      _activeChildDelegate?.addCharacter(character);
    }

    if (!_isReadingValue && [',', ' '].contains(character)) {
      // Just a separator, do nothing
      return;
    }

    if (character == ']') {
      isDone = true;
      onComplete?.call();
    }
  }
}
