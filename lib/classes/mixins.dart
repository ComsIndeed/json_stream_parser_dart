import 'package:json_stream_parser/classes/json_stream_parser.dart';
import 'package:json_stream_parser/classes/property_delegates/boolean_property_delegate.dart';
import 'package:json_stream_parser/classes/property_delegates/list_property_delegate.dart';
import 'package:json_stream_parser/classes/property_delegates/map_property_delegate.dart';
import 'package:json_stream_parser/classes/property_delegates/number_property_delegate.dart';
import 'package:json_stream_parser/classes/property_delegates/property_delegate.dart';
import 'package:json_stream_parser/classes/property_delegates/string_property_delegate.dart';
import 'package:json_stream_parser/classes/property_stream.dart';

mixin Delegator {
  PropertyDelegate getDelegateFromCharacter(
    String character, {
    required String propertyPath,
    required JsonStreamParserController jsonStreamParserController,
  }) {
    switch (character) {
      case ' ':
      case '\n':
      case '\r':
      case '\t':
        throw UnimplementedError('Handle whitespace characters in your code.');
      case '{':
        return MapPropertyDelegate(
          propertyPath: propertyPath,
          jsonStreamParserController: jsonStreamParserController,
        );
      case '[':
        return ListPropertyDelegate(
          propertyPath: propertyPath,
          jsonStreamParserController: jsonStreamParserController,
        );
      case '"':
        return StringPropertyDelegate(
          propertyPath: propertyPath,
          jsonStreamParserController: jsonStreamParserController,
        );
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
        return NumberPropertyDelegate(
          propertyPath: propertyPath,
          jsonStreamParserController: jsonStreamParserController,
        );
      case 't':
      case 'f':
        return BooleanPropertyDelegate(
          propertyPath: propertyPath,
          jsonStreamParserController: jsonStreamParserController,
        );
      case 'n':
        return NumberPropertyDelegate(
          propertyPath: propertyPath,
          jsonStreamParserController: jsonStreamParserController,
        );
      default:
        throw UnimplementedError(
          'No delegate available for character: $character',
        );
    }
  }
}

/// ! You left off trying to determine what would be the interface for the map stream properties and such, so that you could emit values from the delegates
///
/// You did really well again, goodjob!

mixin PropertyStreamorator {
  PropertyStream getPropertyStream<T>() {
    if (T is String) {
      return StringPropertyStream();
    } else if (T is Map) {
      return MapPropertyStream();
    } else {
      throw UnimplementedError('No PropertyStream available for type: $T');
    }
  }
}
