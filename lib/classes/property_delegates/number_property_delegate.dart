import 'package:json_stream_parser/classes/property_delegates/property_delegate.dart';

class NumberPropertyDelegate extends PropertyDelegate {
  NumberPropertyDelegate({
    required super.propertyPath,
    required super.parserController,
  });

  @override
  void addCharacter(String character) {
    // TODO: implement addCharacter
    throw UnimplementedError();
  }
}
