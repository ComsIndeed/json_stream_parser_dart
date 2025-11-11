import 'package:json_stream_parser/classes/json_stream_parser.dart';
import 'package:json_stream_parser/classes/property_delegates/boolean_property_delegate.dart';
import 'package:json_stream_parser/classes/property_delegates/list_property_delegate.dart';
import 'package:json_stream_parser/classes/property_delegates/map_property_delegate.dart';
import 'package:json_stream_parser/classes/property_delegates/null_property_delegate.dart';
import 'package:json_stream_parser/classes/property_delegates/number_property_delegate.dart';
import 'package:json_stream_parser/classes/property_delegates/property_delegate.dart';
import 'package:json_stream_parser/classes/property_delegates/string_property_delegate.dart';

mixin Delegator {
  PropertyDelegate createDelegate(
    String character, {
    required String propertyPath,
    required JsonStreamParserController jsonStreamParserController,
    void Function()? onComplete,
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
          parserController: jsonStreamParserController,
          onComplete: onComplete,
        );
      case '[':
        return ListPropertyDelegate(
          propertyPath: propertyPath,
          parserController: jsonStreamParserController,
          onComplete: onComplete,
        );
      case '"':
        return StringPropertyDelegate(
          propertyPath: propertyPath,
          parserController: jsonStreamParserController,
          onComplete: onComplete,
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
          parserController: jsonStreamParserController,
          onComplete: onComplete,
        );
      case 't':
      case 'f':
        return BooleanPropertyDelegate(
          propertyPath: propertyPath,
          parserController: jsonStreamParserController,
          onComplete: onComplete,
        );
      case 'n':
        return NullPropertyDelegate(
          propertyPath: propertyPath,
          parserController: jsonStreamParserController,
          onComplete: onComplete,
        );
      default:
        throw UnimplementedError(
          'No delegate available for character: \n|$character|',
        );
    }
  }
}

/// ! You left off trying to determine what would be the interface for the map stream properties and such, so that you could emit values from the delegates
///
/// You did really well again, goodjob!
