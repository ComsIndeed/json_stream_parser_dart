import 'package:json_stream_parser/classes/property_delegates/property_delegate.dart';

class NullPropertyDelegate extends PropertyDelegate {
  NullPropertyDelegate({
    required super.propertyPath,
    required super.parserController,
    super.onComplete,
  });

  @override
  void addCharacter(String character) {
    if (character == "n") {
      parserController.addPropertyChunk<Null>(
        propertyPath: propertyPath,
        chunk: null,
      );
      parserController.getPropertyStreamController(propertyPath).complete(null);
    } else if (character == "," || character == "}" || character == "]") {
      isDone = true;
      onComplete?.call();
      return;
    }
  }
}
