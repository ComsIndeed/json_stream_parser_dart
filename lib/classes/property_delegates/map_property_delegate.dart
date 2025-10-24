import 'package:json_stream_parser/classes/property_delegates/property_delegate.dart';

class MapPropertyDelegate extends PropertyDelegate {
  MapPropertyDelegate({required super.propertyPath, required super.controller});

  @override
  void handleCharacter(String character) {
    switch (character) {
      case '{':
        // Handle nested map
        break;
      case '[':
        // Handle nested list
        break;
      case '}':
        // Handle end of map
        break;
      case ']':
        // Handle end of list
        break;
      case ',':
        // Handle separator
        break;
      case ':':
        // Handle key-value separator
        break;
      case '"':
        // Handle string value
        break;
      case '-':
      case '0':
      case '1':
      case '2':
      case '3':
      case '4':
      case '5':
      case '6':
      case '7':
      case '8':
      case '9':
        // Handle any valid number value
        break;
      case 't':
      case 'f':
        // Handle boolean value
        break;
      case 'n':
        // Handle null value
        break;
      default:
        break;
    }
  }
}
