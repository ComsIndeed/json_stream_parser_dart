import 'package:json_stream_parser/classes/property_delegates/property_delegate.dart';

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
    if (_buffer.isEmpty) return;
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
      _buffer += character;
      _isEscaping = false;
      return;
    }
    if (character == r'\') {
      _isEscaping = true;
      return;
    }
    if (character == '"') {
      isDone = true;
      if (_buffer.isNotEmpty) {
        addPropertyChunk(_buffer);
      }
      parserController.getPropertyStreamController(propertyPath).complete("");
      onComplete?.call();
      return;
    }
    _buffer += character;
  }
}
