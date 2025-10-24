// import 'dart:convert';

// import 'package:json_stream_parser/classes/property_stream.dart';
// import 'package:json_stream_parser/utilities/stream_text_in_chunks.dart';
// import 'package:test/test.dart';

// void main() {
//   final testMap = {
//     // 1️⃣ simple string pairs first
//     "title": "A Journey into the Depths of Parsing",
//     "author": "Vince, the guy who decided pain was a hobby",
//     "description":
//         "This JSON exists to make sure your parser either evolves or combusts. It starts simple, then quickly spirals into madness.",

//     // 2️⃣ now we go nested — still strings at first
//     "chapter1": {
//       "intro": "Once upon a stream, data flowed endlessly...",
//       "theme": "Complexity disguised as simplicity",

//       // then different value types
//       "pageCount": 42,
//       "isPublished": true,
//       "ratings": 4.9,
//       "tags": ["flutter", "json", "insanity"],

//       // one more deeper nest
//       "meta": {"editor": "AI Assistant", "approved": false, "revision": 3},
//     },

//     // 3️⃣ denest — new property: a list
//     "contributors": [
//       "Vince", // string
//       "GPT-5", // string
//       9000, // int
//       true, // bool
//       {
//         // nested object inside list
//         "name": "Unknown Dev",
//         "skills": ["Dart", "Suffering", "Problem Solving"],
//         "yearsOfExperience": 2,
//       },
//     ],

//     // 4️⃣ denest again — back to simple strings
//     "endingNote":
//         "And thus, the parser stood victorious — or broken. Either way, a story was told.",
//     "version": "1.0.0",
//   };

//   final Map<String, dynamic> testFlatMap = {
//     // Pattern 1
//     'shortText': 'hey',
//     'longText': 'this is a long sample string just for demo purposes',
//     'count': 42,
//     'age': 19,
//     'height': 5.9,
//     'note': 'first cycle done',

//     // Pattern 2
//     'shortMsg': 'yo',
//     'longMsg': 'flutter makes cross-platform apps actually feel native',
//     'views': 1200,
//     'score': 87,
//     'rating': 4.7,
//     'remark': 'second cycle complete',
//   };

//   final testString =
//       '"Aliquip duis do occaecat anim non quis excepteur nostrud adipisicing excepteur."';

//   final testJsonMap = jsonEncode(testMap);
//   final testFlatJsonMap = jsonEncode(testFlatMap);

//   group('PropertyStream tests', () {
//     test('StringPropertyStream', () {
//       final stream = streamTextInChunks(
//         text: testString,
//         chunkSize: 4,
//         interval: Duration(microseconds: 1),
//       );
//       final parser = StringPropertyStream(stream);

//       // parser.

//       expect("", "");
//     });
//   });
// }
