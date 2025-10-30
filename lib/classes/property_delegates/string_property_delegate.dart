import 'package:json_stream_parser/classes/property_delegates/property_delegate.dart';

class StringPropertyDelegate extends PropertyDelegate {
  StringPropertyDelegate({
    required super.propertyPath,
    required super.parserController,
  });

  String _buffer = "";
  bool _isEscaping = false;

  @override
  void onChunkEnd() {
    addPropertyChunk(_buffer);
    _buffer = "";
  }

  @override
  void addCharacter(String character) {
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
      addPropertyChunk(_buffer);
      // TODO : call finish for string streams

      return;
    }
    _buffer += character;
  }
}
