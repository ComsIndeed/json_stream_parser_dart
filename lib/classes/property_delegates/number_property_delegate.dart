import 'package:streaming_json_parser/classes/property_delegates/property_delegate.dart';

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
      if (_buffer.isNotEmpty && !isDone) {
        isDone = true; // Mark done BEFORE completing to prevent re-entry
        _completeNumber();
        onComplete?.call();
      }
      // Don't consume the character - let the parent handle delimiters
      // The parent will reprocess this character after seeing isDone=true
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
    if (_buffer.isEmpty) return; // Defensive check

    final numberString = _buffer.toString();
    final number = num.parse(numberString);

    parserController.addPropertyChunk<num>(
      propertyPath: propertyPath,
      chunk: number,
    );

    _buffer.clear(); // Clear buffer to prevent re-use
    // Note: addPropertyChunk already completes the controller, so we don't need to call complete again
  }
}
