import 'package:json_stream_parser/classes/property_delegates/property_delegate.dart';

class ListPropertyDelegate extends PropertyDelegate {
  ListPropertyDelegate({
    required super.propertyPath,
    required super.parserController,
    super.onComplete,
  });

  @override
  void addCharacter(String character) {
    // TODO: implement addCharacter
    throw UnimplementedError();
  }
}
