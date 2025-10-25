// ignore_for_file: prefer_final_fields

import 'package:json_stream_parser/classes/property_delegates/property_delegate.dart';

/// ! YOU LEFT OFF AT BUILDING THE MAP PROPERTY DELEGATE !
///
/// - JUST FINISHED THE FLAT FLOW OF MAP STREAM PARSING
/// - MIGHT HAVE TO HANDLE LISTS NOW, OR TEST THE PARSER FIRST
/// - REMEMBER TO UPDATE THE PROPERTY STREAM TO HANDLE GENERIC TYPES (this was autocompleted, do check though)
/// - You're doing well, goodjob!

class MapPropertyDelegate extends PropertyDelegate {
  // * String propertyPath

  // * JsonStreamParserController jsonStreamParserController

  MapPropertyDelegate({
    required super.propertyPath,
    required super.jsonStreamParserController,
  });

  MapParseState _state = MapParseState.waitingForKey;

  bool _firstCharacter = true;
  String _keyBuffer = "";
  PropertyDelegate? _currentValueDelegate;

  @override
  void addCharacter(String character) {
    emitToStream(character);

    if (_state == MapParseState.readingKey) {
      if (character == '"') {
        _state = MapParseState.waitingForValue;
        return;
      } else {
        _keyBuffer += character;
        return;
      }
    }

    if (_state == MapParseState.readingValue) {
      _currentValueDelegate?.addCharacter(character);
      return;
    }

    if (_state == MapParseState.waitingForValue) {
      if (character == " ") return;
      _currentValueDelegate = getDelegateFromCharacter(
        character,
        propertyPath: propertyPath + _keyBuffer,
        jsonStreamParserController: jsonStreamParserController,
      );
      _state = MapParseState.readingValue;
      return;
    }

    if (_firstCharacter && character == '{') {
      _firstCharacter = false;
      return;
    }

    if (character == '"' && _state == MapParseState.waitingForKey) {
      _state = MapParseState.readingKey;
      return;
    }

    if (_state == MapParseState.waitingForCommaOrEnd) {
      if (character == ',') {
        _state = MapParseState.waitingForKey;
        _keyBuffer = "";
        return;
      } else if (character == '}') {
        close();
        return;
      }
    }

    return;
  }
}

enum MapParseState {
  waitingForKey,
  readingKey,
  waitingForValue,
  readingValue,
  waitingForCommaOrEnd,
}
