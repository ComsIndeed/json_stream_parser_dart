import 'package:llm_json_stream/classes/property_delegates/property_delegate.dart';

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
      // addPropertyChunk already completes the controller
    } else if (character == "," || character == "}" || character == "]") {
      isDone = true;
      onComplete?.call();
      return;
    }
  }
}
