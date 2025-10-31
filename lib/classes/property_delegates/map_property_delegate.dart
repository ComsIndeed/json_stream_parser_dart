// ignore_for_file: prefer_final_fields

import 'package:json_stream_parser/classes/property_delegates/property_delegate.dart';

class MapPropertyDelegate extends PropertyDelegate {
  // * String propertyPath

  // * JsonStreamParserController jsonStreamParserController

  MapPropertyDelegate({
    required super.propertyPath,
    required super.parserController,
    super.onComplete,
  });

  MapParseState _state = MapParseState.waitingForKey;

  bool _firstCharacter = true;
  String _keyBuffer = "";
  String _stringBuffer = "";
  PropertyDelegate? _activeChildDelegate;

  void onChildComplete() {
    _activeChildDelegate = null;
    _state = MapParseState.waitingForCommaOrEnd;
  }

  @override
  void onChunkEnd() {
    _activeChildDelegate?.onChunkEnd();
    addPropertyChunk<String>(_stringBuffer);
    _stringBuffer = "";
  }

  @override
  void addCharacter(String character) {
    _stringBuffer += character;

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
      _activeChildDelegate?.addCharacter(character);
      if (_activeChildDelegate?.isDone ?? false) {
        _state = MapParseState.waitingForCommaOrEnd;
        _activeChildDelegate = null;
      }
      return;
    }

    if (_state == MapParseState.waitingForValue) {
      if (character == " " || character == ":") return;
      _activeChildDelegate = createDelegate(
        character,
        propertyPath: propertyPath + _keyBuffer,
        jsonStreamParserController: parserController,
      );
      _activeChildDelegate!.addCharacter(character);
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
        isDone = true;
        onComplete?.call();
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
