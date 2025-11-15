import 'package:streaming_json_parser/classes/property_delegates/property_delegate.dart';

class StringPropertyDelegate extends PropertyDelegate {
  StringPropertyDelegate({
    required super.propertyPath,
    required super.parserController,
    super.onComplete,
  });

  String _buffer = "";
  bool _isEscaping = false;
  bool _firstCharacter = true;

  @override
  void onChunkEnd() {
    if (_buffer.isEmpty || isDone) return;
    addPropertyChunk(_buffer);
    _buffer = "";
  }

  @override
  void addCharacter(String character) {
    if (_firstCharacter && character == '"') {
      _firstCharacter = false;
      return;
    }
    if (_firstCharacter) {
      throw Exception(
        'StringPropertyDelegate expected starting quote but got: $character',
      );
    }
    if (_isEscaping) {
      // Handle escape sequences - convert them to actual characters
      switch (character) {
        case '"':
          _buffer += '"';
          break;
        case '\\':
          _buffer += '\\';
          break;
        case '/':
          _buffer += '/';
          break;
        case 'b':
          _buffer += '\b';
          break;
        case 'f':
          _buffer += '\f';
          break;
        case 'n':
          _buffer += '\n';
          break;
        case 'r':
          _buffer += '\r';
          break;
        case 't':
          _buffer += '\t';
          break;
        default:
          // For unknown escape sequences, include both backslash and character
          _buffer += '\\$character';
          break;
      }
      _isEscaping = false;
      return;
    }
    if (character == r'\') {
      _isEscaping = true;
      return;
    }
    if (character == '"') {
      isDone = true;
      // Emit final chunk if there's any remaining buffer
      if (_buffer.isNotEmpty) {
        addPropertyChunk(_buffer);
        _buffer = "";
      }
      // Complete the string controller - it will use its accumulated buffer
      final controller = parserController.getPropertyStreamController(
        propertyPath,
      );
      if (!controller.isClosed) {
        controller.complete(
          "",
        ); // The actual value comes from the controller's _buffer
      }
      onComplete?.call();
      return;
    }
    _buffer += character;
  }
}
