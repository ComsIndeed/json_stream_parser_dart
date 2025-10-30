import 'package:json_stream_parser/classes/property_delegates/property_delegate.dart';

class BooleanPropertyDelegate extends PropertyDelegate {
  BooleanPropertyDelegate({
    required super.propertyPath,
    required super.parserController,
  });

  @override
  void addCharacter(String character) {
    print('BooleanPropertyDelegate received character: $character');
    if (character == "t") {
      parserController.addPropertyChunk<bool>(
        propertyPath: propertyPath,
        chunk: true,
      );
      parserController.getPropertyStreamController(propertyPath).complete(true);
    } else if (character == "f") {
      parserController.addPropertyChunk<bool>(
        propertyPath: propertyPath,
        chunk: false,
      );
      parserController
          .getPropertyStreamController(propertyPath)
          .complete(false);
    } else if (character == "," || character == "}" || character == "]") {
      isDone = true;
      return;
    }
  }
}
