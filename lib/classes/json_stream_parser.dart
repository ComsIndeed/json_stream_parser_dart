import 'dart:async';

import 'package:json_stream_parser/classes/property_delegates/list_property_delegate.dart';
import 'package:json_stream_parser/classes/property_delegates/map_property_delegate.dart';
import 'package:json_stream_parser/classes/property_delegates/property_delegate.dart';
import 'package:json_stream_parser/classes/property_stream.dart';
import 'package:json_stream_parser/classes/property_stream_controller.dart';

///
/// BASE PARSER HANDLING THE DELEGATES AND PROPERTY STREAMS
/// [ ] RESPONSIBLE FOR CREATING THE ROOT DELEGATE AND PROVIDING METHODS TO DESCENDANT DELEGATES
/// [ ] RESPONSIBLE FOR EXPOSING METHODS TO GET PROPERTY STREAMS
/// [ ] RESPONSIBLE FOR FEEDING CHUNKS TO THE ROOT DELEGATE
/// [ ] RESPONSIBLE FOR SIGNALLING THE END OF A CHUNK TO THE ROOT DELEGATE
///

class JsonStreamParser {
  JsonStreamParser(Stream<String> stream) : _stream = stream {
    _stream.listen(_parseChunk);
    _controller = JsonStreamParserController(
      addPropertyChunk: _addPropertyChunk,
      getPropertyStreamController: _getControllerForPath,
      getPropertyStream: _getPropertyStream,
    );
  }

  // * Exposeds
  StringPropertyStream getStringProperty(String propertyPath) {
    if (_propertyControllers[propertyPath] != null &&
        _propertyControllers[propertyPath] is! StringPropertyStreamController) {
      throw Exception(
        'Property at path $propertyPath is not a StringPropertyStream',
      );
    }
    final controller =
        _propertyControllers.putIfAbsent(
              propertyPath,
              () => StringPropertyStreamController(
                parserController: _controller,
                propertyPath: propertyPath,
              ),
            )
            as StringPropertyStreamController;
    return controller.propertyStream;
  }

  NumberPropertyStream getNumberProperty(String propertyPath) {
    if (_propertyControllers[propertyPath] != null &&
        _propertyControllers[propertyPath] is! NumberPropertyStreamController) {
      throw Exception(
        'Property at path $propertyPath is not a NumberPropertyStream',
      );
    }
    final controller =
        _propertyControllers.putIfAbsent(
              propertyPath,
              () => NumberPropertyStreamController(
                parserController: _controller,
                propertyPath: propertyPath,
              ),
            )
            as NumberPropertyStreamController;
    return controller.propertyStream;
  }

  BooleanPropertyStream getBooleanProperty(String propertyPath) {
    if (_propertyControllers[propertyPath] != null &&
        _propertyControllers[propertyPath]
            is! BooleanPropertyStreamController) {
      throw Exception(
        'Property at path $propertyPath is not a BooleanPropertyStream',
      );
    }
    final controller =
        _propertyControllers.putIfAbsent(
              propertyPath,
              () => BooleanPropertyStreamController(
                parserController: _controller,
                propertyPath: propertyPath,
              ),
            )
            as BooleanPropertyStreamController;
    return controller.propertyStream;
  }

  NullPropertyStream getNullProperty(String propertyPath) {
    if (_propertyControllers[propertyPath] != null &&
        _propertyControllers[propertyPath] is! NullPropertyStreamController) {
      throw Exception(
        'Property at path $propertyPath is not a NullPropertyStream',
      );
    }
    final controller =
        _propertyControllers.putIfAbsent(
              propertyPath,
              () => NullPropertyStreamController(
                parserController: _controller,
                propertyPath: propertyPath,
              ),
            )
            as NullPropertyStreamController;
    return controller.propertyStream;
  }

  MapPropertyStream getMapProperty(String propertyPath) {
    if (_propertyControllers[propertyPath] != null &&
        _propertyControllers[propertyPath] is! MapPropertyStreamController) {
      throw Exception(
        'Property at path $propertyPath is not a MapPropertyStream',
      );
    }
    final controller =
        _propertyControllers.putIfAbsent(
              propertyPath,
              () => MapPropertyStreamController(
                parserController: _controller,
                propertyPath: propertyPath,
              ),
            )
            as MapPropertyStreamController;
    return controller.propertyStream;
  }

  ListPropertyStream getListProperty(
    String propertyPath, {
    void Function(PropertyStream, int)? onElement,
  }) {
    if (_propertyControllers[propertyPath] != null &&
        _propertyControllers[propertyPath] is! ListPropertyStreamController) {
      throw Exception(
        'Property at path $propertyPath is not a ListPropertyStream',
      );
    }
    final controller =
        _propertyControllers.putIfAbsent(
              propertyPath,
              () => ListPropertyStreamController(
                parserController: _controller,
                propertyPath: propertyPath,
              ),
            )
            as ListPropertyStreamController;
    if (onElement != null) {
      controller.addOnElementCallback(onElement);
    }
    return controller.propertyStream;
  }

  // * Controller methods
  void _addPropertyChunk<T>({required String propertyPath, required T chunk}) {
    final controller =
        _propertyControllers.putIfAbsent(propertyPath, () {
              if (T == String) {
                return StringPropertyStreamController(
                  parserController: _controller,
                  propertyPath: propertyPath,
                );
              } else if (T == num) {
                return NumberPropertyStreamController(
                  parserController: _controller,
                  propertyPath: propertyPath,
                );
              } else if (T == bool) {
                return BooleanPropertyStreamController(
                  parserController: _controller,
                  propertyPath: propertyPath,
                );
              } else if (T == Null) {
                return NullPropertyStreamController(
                  parserController: _controller,
                  propertyPath: propertyPath,
                );
              } else if (T == Map<String, Object?>) {
                return MapPropertyStreamController(
                  parserController: _controller,
                  propertyPath: propertyPath,
                );
              } else if (T == List<Object?>) {
                return ListPropertyStreamController(
                  parserController: _controller,
                  propertyPath: propertyPath,
                );
              } else {
                throw UnimplementedError(
                  'No PropertyStreamController for type $T',
                );
              }
            })
            as PropertyStreamController<
              T
            >; // TODO: Fix casting. Maybe remove generics?

    // everything but list and map controllers will emit chunks in its stream
    if (controller is MapPropertyStreamController ||
        controller is ListPropertyStreamController) {
      controller.complete(chunk);
      return;
    } else {
      if (controller is StringPropertyStreamController) {
        final stringController = controller as StringPropertyStreamController;
        stringController.addChunk(chunk as String);
      } else if (controller is NumberPropertyStreamController) {
        final numberController = controller as NumberPropertyStreamController;
        numberController.streamController.add(chunk as num);
        numberController.complete(chunk as num);
      } else if (controller is BooleanPropertyStreamController) {
        final booleanController = controller as BooleanPropertyStreamController;
        booleanController.streamController.add(chunk as bool);
        booleanController.complete(chunk as bool);
      } else if (controller is NullPropertyStreamController) {
        final nullController = controller as NullPropertyStreamController;
        nullController.streamController.add(chunk as Null);
        nullController.complete(chunk as Null);
      }
    }
  }

  // * Fields
  final Stream<String> _stream;
  late final JsonStreamParserController _controller;

  // * Memories
  final Map<String, PropertyStreamController> _propertyControllers = {};

  // * States
  PropertyDelegate? _rootDelegate;

  // * Helpers
  PropertyStreamController _getControllerForPath(String propertyPath) {
    return _propertyControllers[propertyPath]!;
  }

  PropertyStream _getPropertyStream(String propertyPath, Type streamType) {
    // If controller already exists (e.g., user called getXxxProperty before parsing),
    // just return its property stream instead of trying to create a new one
    final existingController = _propertyControllers[propertyPath];
    if (existingController != null) {
      return existingController.propertyStream;
    }

    // Otherwise create the appropriate controller based on type
    if (streamType == String) {
      return getStringProperty(propertyPath);
    } else if (streamType == num) {
      return getNumberProperty(propertyPath);
    } else if (streamType == bool) {
      return getBooleanProperty(propertyPath);
    } else if (streamType == Null) {
      return getNullProperty(propertyPath);
    } else if (streamType == Map) {
      return getMapProperty(propertyPath);
    } else if (streamType == List) {
      return getListProperty(propertyPath);
    } else {
      throw Exception('Unknown stream type: $streamType');
    }
  }

  void _parseChunk(String chunk) {
    for (final character in chunk.split('')) {
      if (_rootDelegate != null) {
        _rootDelegate!.addCharacter(character);
        continue;
      }

      if (character == '{') {
        _rootDelegate = MapPropertyDelegate(
          propertyPath: '',
          parserController: _controller,
        );
        _rootDelegate!.addCharacter(character);
      }

      if (character == "[") {
        _rootDelegate = ListPropertyDelegate(
          propertyPath: '',
          parserController: _controller,
        );
        _rootDelegate!.addCharacter(character);
      }

      continue;
    }

    _rootDelegate?.onChunkEnd();
  }
}

class JsonStreamParserController {
  JsonStreamParserController({
    required this.addPropertyChunk,
    required this.getPropertyStreamController,
    required this.getPropertyStream,
  });

  final void Function<T>({required String propertyPath, required T chunk})
  addPropertyChunk;

  PropertyStreamController Function(String propertyPath)
  getPropertyStreamController;

  /// Gets a PropertyStream for the given path, creating the controller if needed.
  /// The type parameter indicates what kind of stream to create.
  final PropertyStream Function(String propertyPath, Type streamType)
  getPropertyStream;
}
