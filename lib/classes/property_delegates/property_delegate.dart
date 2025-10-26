// ignore_for_file: prefer_final_fields

import 'package:json_stream_parser/classes/json_stream_parser.dart';
import 'package:json_stream_parser/classes/mixins.dart';

///
/// WORKERS THAT NAVIGATE DIFFERENT TOKENS
/// [ ] RESPONSIBLE FOR ACCUMULATING CHARACTERS
/// [ ] RESPONSIBLE FOR EMITTING TO THE PROPERTY STREAMS
/// [ ] RESPONSIBLE FOR HANDLING CHUNK ENDS
/// [ ] RESPONSIBLE FOR SIGNALLING COMPLETION OF THEIR TASK
/// [ ] RESPONSIBLE FOR CREATING CHILD DELEGATES AS NEEDED
/// [ ] RESPONSIBLE FOR UPDATING THE MASTER PARSER'S STATE VIA THE CONTROLLER
///

/// Delegates are not supposed to just hold states and data, but rather, mutate the master parser's state machine as characters are fed to them.
abstract class PropertyDelegate with Delegator {
  final String propertyPath;
  final JsonStreamParserController parserController;
  bool isDone = false;

  PropertyDelegate({
    required this.propertyPath,
    required this.parserController,
  });

  String newPath(String path) =>
      propertyPath.isEmpty ? path : '$propertyPath.$path';

  void emitToStream<T>(T value, {String? innerPath}) {
    throw UnimplementedError();

    ///
    /// ! THIS IS WHERE YOU LEFT OFF
    ///
    /// YOU HAVE TO FIX THIS METHOD SO THAT STREAMING WORKS
    ///
    /// YOU NEED TO FIGURE OUT HOW TO "ADD" OR "EMIT" VALUES TO [PROPERTYSTREAMS]
    /// DO REMEMBER THERE ARE DIFFERENT TYPES WITH DIFFERENT EMISSION REQUIREMENTS AND DIFFERENT PUBLIC APIS
    ///
    parserController.addPropertyChunk(
      propertyPath: propertyPath + (innerPath != null ? '.$innerPath' : ''),
      chunk: "",
    );
  }

  void addCharacter(String character) {
    throw UnimplementedError();
  }

  void onChunkEnd() {}
}
