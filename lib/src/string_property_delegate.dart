import 'parse_event.dart';
import 'property_delegate.dart';
import 'property_stream_controller.dart';

class StringPropertyDelegate extends PropertyDelegate {
  StringPropertyDelegate({
    required super.propertyPath,
    required super.parserController,
    super.onComplete,
  });

  String _buffer = "";
  bool _isEscaping = false;
  bool _firstCharacter = true;

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

  @override
  void onChunkEnd() {
    if (_buffer.isEmpty || isDone) return;

    // Emit stringChunk event
    _emitLog(ParseEvent(
      type: ParseEventType.stringChunk,
      propertyPath: propertyPath,
      message: 'String chunk: ${_buffer.length} chars',
      data: _buffer,
    ));

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
        // Emit stringChunk event for the final chunk
        _emitLog(ParseEvent(
          type: ParseEventType.stringChunk,
          propertyPath: propertyPath,
          message: 'String chunk: ${_buffer.length} chars',
          data: _buffer,
        ));

        addPropertyChunk(_buffer);
        _buffer = "";
      }
      // Complete the string controller - it will use its accumulated buffer
      final controller = parserController.getPropertyStreamController(
        propertyPath,
      ) as StringPropertyStreamController;
      if (!controller.isClosed) {
        // Emit propertyComplete event
        _emitLog(ParseEvent(
          type: ParseEventType.propertyComplete,
          propertyPath: propertyPath,
          message: 'String property completed: $propertyPath',
        ));

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
