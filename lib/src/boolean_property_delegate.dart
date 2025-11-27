import 'property_delegate.dart';

class BooleanPropertyDelegate extends PropertyDelegate {
  BooleanPropertyDelegate({
    required super.propertyPath,
    required super.parserController,
    super.onComplete,
  });

  @override
  void addCharacter(String character) {
    if (character == "t") {
      parserController.addPropertyChunk<bool>(
        propertyPath: propertyPath,
        chunk: true,
      );
      // addPropertyChunk already completes the controller
    } else if (character == "f") {
      parserController.addPropertyChunk<bool>(
        propertyPath: propertyPath,
        chunk: false,
      );
      // addPropertyChunk already completes the controller
    } else if (character == "," || character == "}" || character == "]") {
      isDone = true;
      onComplete?.call();
      return;
    }
  }
}
