import 'dart:async';
import 'dart:ffi';

/// JUST FEED THE [_objectStream] AND [_objectCompleter] OBJECTS AND HANDLE THE DISPOSING
abstract class PropertyStream<T> {
  // internal sources
  final Stream<String> _sourceStream;

  // states and objects
  final StreamController<T> _objectStream = StreamController<T>.broadcast();
  final Completer<T> _objectCompleter = Completer<T>();

  PropertyStream(Stream<String> stream) : _sourceStream = stream;

  // publics
  Future<T> get future => _objectCompleter.future;
  Stream<T> get stream => _objectStream.stream;
}

/// Start feeding characters to this ON (AND INCLUDING) the first quote
class StringPropertyStream extends PropertyStream<String> {
  StringPropertyStream(super.stream) {
    _sourceStream.listen(_parse);
  }

  bool _isEscaped = false;
  int _quoteCount = 0;
  String _completerBuffer = "";

  void _add(String chunk) {
    if (chunk.isEmpty) return;
    _completerBuffer += chunk;
    _objectStream.add(chunk);
  }

  void _complete() {
    _objectCompleter.complete(_completerBuffer);
    _objectStream.close();
    print("CLSOED");
  }

  void _parse(String chunk) {
    String chunkBuffer = "";
    for (final character in chunk.split("")) {
      if (_isEscaped) {
        chunkBuffer += character;
        _isEscaped = false;
        continue;
      }
      if (character == r"\") {
        _isEscaped = true;
        chunkBuffer += character; // TODO: Should we keep the backslash?
        continue;
      }
      if (character == '"') {
        _quoteCount++;
        if (_quoteCount == 2) {
          _add(chunkBuffer);
          _complete();
          return;
        }
        continue;
      }
      chunkBuffer += character;
    }
    _add(chunkBuffer);
  }
}

class BooleanPropertyStream extends PropertyStream<bool> {
  BooleanPropertyStream(bool value) : super(Stream.empty()) {
    _objectStream.add(value);
    _objectCompleter.complete(value);
    _objectStream.close();
  }
}

class NumberPropertyStream extends PropertyStream<num> {
  bool isNumericToken(String char) {
    // Dart doesn't have a 'char' type, so we use String,
    // but we enforce it's only a single character.
    if (char.length != 1) {
      return false; // Not a single token
    }

    final token = char[0]; // Get the actual character

    // Check if it's a digit (0-9)
    if (token.codeUnitAt(0) >= '0'.codeUnitAt(0) &&
        token.codeUnitAt(0) <= '9'.codeUnitAt(0)) {
      return true;
    }

    // Check for the special characters allowed in a number
    switch (token) {
      case '-': // Minus sign for negative numbers
      case '.': // Decimal point for floats
      case 'e': // Exponent sign
      case 'E': // Uppercase exponent sign
        return true;
      default:
        return false; // Anything else is invalid for a number token
    }
  }

  NumberPropertyStream(super.stream) {
    _sourceStream.listen(_parse);
  }

  void _close() {
    final number = num.parse(numberBuffer);
    _objectStream.add(number);
    _objectStream.close();
    _objectCompleter.complete(number);
  }

  String numberBuffer = "";
  void _parse(String chunk) {
    for (final character in chunk.split("")) {
      final isNumeric = isNumericToken(character);
      if (isNumeric) {
        numberBuffer += character;
        continue;
      } else {
        _close();
        return;
      }
    }
  }
}

class NullPropertyStream extends PropertyStream<Null> {
  NullPropertyStream() : super(Stream.empty()) {
    _objectStream.add(null);
    _objectCompleter.complete(null);
    _objectStream.close();
  }
}

class MapPropertyStream extends PropertyStream<Map<String, dynamic>> {
  MapPropertyStream(super.stream) {
    _sourceStream.listen(_parse);
  }

  void _parse(String chunk) {}
}

class ListPropertyStream extends PropertyStream<List<dynamic>> {
  ListPropertyStream(super.stream);
}
