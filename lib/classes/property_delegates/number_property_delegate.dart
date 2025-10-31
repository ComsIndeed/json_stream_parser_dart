import 'package:json_stream_parser/classes/property_delegates/property_delegate.dart';

class NumberPropertyDelegate extends PropertyDelegate {
  final StringBuffer _buffer = StringBuffer();

  NumberPropertyDelegate({
    required super.propertyPath,
    required super.parserController,
    super.onComplete,
  });

  @override
  void addCharacter(String character) {
    // Check if this is a delimiter that ends the number
    if (character == "," ||
        character == "}" ||
        character == "]" ||
        character == " " ||
        character == "\n" ||
        character == "\r" ||
        character == "\t") {
      if (_buffer.isNotEmpty) {
        _completeNumber();
      }
      isDone = true;
      onComplete?.call();
      return;
    }

    // Valid number characters: digits, minus sign, decimal point, exponent
    if (_isValidNumberCharacter(character)) {
      _buffer.write(character);
    }
  }

  bool _isValidNumberCharacter(String character) {
    return character == '-' ||
        character == '+' ||
        character == '.' ||
        character == 'e' ||
        character == 'E' ||
        (character.codeUnitAt(0) >= 48 && character.codeUnitAt(0) <= 57); // 0-9
  }

  void _completeNumber() {
    final numberString = _buffer.toString();
    final number = num.parse(numberString);

    parserController.addPropertyChunk<num>(
      propertyPath: propertyPath,
      chunk: number,
    );
    parserController.getPropertyStreamController(propertyPath).complete(number);
  }
}
