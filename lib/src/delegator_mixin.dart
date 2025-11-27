import 'json_stream_parser.dart';
import 'property_delegate.dart';
import 'boolean_property_delegate.dart';
import 'list_property_delegate.dart';
import 'map_property_delegate.dart';
import 'null_property_delegate.dart';
import 'number_property_delegate.dart';
import 'string_property_delegate.dart';

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
