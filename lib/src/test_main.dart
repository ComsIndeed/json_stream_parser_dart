import 'dart:convert';

import 'package:json_stream_parser/classes/json_stream_parser.dart';
import 'package:json_stream_parser/classes/property_stream.dart';
import 'package:json_stream_parser/utilities/stream_text_in_chunks.dart';

void main() async {
  final map = {
    "numberList": [1, 2, 3, 4, 5],
  };
  final json = jsonEncode(map);
  final stream = streamTextInChunks(
    text: json,
    chunkSize: 3,
    interval: Duration(milliseconds: 50),
  ).asBroadcastStream();
  final parser = JsonStreamParser(stream);
  final object = await parser
      .getListProperty<int>(
        'numberList',
        onElement: (propertyStream, index) {
          final numberProperty = propertyStream as NumberPropertyStream;
          numberProperty.stream.listen(
            (onValue) => print('Element $index: $onValue'),
          );
        },
      )
      .future;
  print('Parsed number list: $object');
}

// void main() async {
//   try {
//     final map = {
//       "someList": [
//         "The quick brown fox",
//         "jumps over the lazy dog",
//         "and runs away",
//       ],
//     };

//     final json = jsonEncode(map);

//     final stream = streamTextInChunks(
//       text: json,
//       chunkSize: 3,
//       interval: Duration(milliseconds: 50),
//     );

//     final parser = JsonStreamParser(stream);

//     parser.getListProperty<String>(
//       'someList',
//       onElement: (propertyStream, index) {
//         final stringProperty = propertyStream as StringPropertyStream;
//         stringProperty.stream.listen(
//           (onValue) => print('Element $index: |$onValue|'),
//         );
//       },
//     );

//     parser.getListProperty('someList').future.then((list) {
//       print('Parsed list: $list');
//     });

//     await Future.delayed(Duration(seconds: 1));
//   } catch (e) {
//     print('Error during parsing: $e');
//   }
// }
