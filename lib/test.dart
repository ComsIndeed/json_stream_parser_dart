import 'package:json_stream_parser/utilities/stream_text_in_chunks.dart';






// void main() async {
//   final String string =
//       r'{"name": "John", "age": 30, "isStudent": false, "scores": [85, 90, 78], "address": {"street": "123 Main St", "city": "Anytown"}}';
//   final stream = streamTextInChunks(
//     text: string,
//     chunkSize: 10,
//     interval: Duration(milliseconds: 50),
//   ).asBroadcastStream();
// }

// /// ! WORks too
// void main() async {
//   final string = r'-23582454378,';
//   final stream = streamTextInChunks(
//     text: string,
//     chunkSize: 100,
//     interval: Duration(milliseconds: 50),
//   ).asBroadcastStream();
//   stream.listen((chunk) => print("|$chunk|"));

//   final textStream = NumberPropertyStream(stream);

//   textStream.stream.listen((chunk) => print("CHUNK:\t|$chunk|"));
//   final finalValue = await textStream.future;
//   print(finalValue);
// }




/// ! STRING STREAM PROPERTY WORKS NOW
// void main() async {
//   final string = r'"The quick brown fox \"jumps\" over the lazy dog."';
//   final stream = streamTextInChunks(
//     text: string,
//     chunkSize: 100,
//     interval: Duration(microseconds: 1),
//   );
//   final textStream = StringPropertyStream(stream);

//   textStream.stream.listen((chunk) => print("CHUNK:\t|$chunk|"));
//   final finalValue = await textStream.future;
//   print(finalValue);
// }

///
///
///
///
///
///
///
///
///







///
///
///
///
///
///




///
///
///










































// import 'dart:convert';

// import '../_trash/json_stream.dart';
// import 'package:json_stream_parser/utilities/stream_text_in_chunks.dart';

// void main() {
//   // CLASS TEST

//   final map = {
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

//   final json = jsonEncode(map);
//   final stream = streamTextInChunks(
//     text: json,
//     chunkSize: 8,
//     interval: Duration(milliseconds: 1),
//   );

//   final jsonStream = JsonStream(stream: stream);
//   jsonStream
//       .getPropertyStream('title')
//       .listen((chunk) => print("\tTITLE:\n|$chunk|"));
//   jsonStream
//       .getPropertyStream('description')
//       .listen((chunk) => print("\tDESC:\n|$chunk|"));
// }

// // void main() {
// //   // KEY DEF TEST
// //   final keyList = KeyList();
// //   keyList.addKey("root");
// //   keyList.addKey("grandparent");
// //   keyList.addKey("parent");
// //   keyList.addKey("child1");
// //   keyList.removeLastKey();
// //   keyList.addKey("child1");
// //   keyList.removeLastKey();
// //   keyList.addKey("child2");
// //   keyList.removeLastKey();
// //   keyList.addKey("child3");
// //   keyList.removeLastKey();
// //   keyList.addKey("child4");
// //   keyList.removeLastKey();
// //   keyList.removeLastKey();
// //   keyList.removeLastKey();
// //   keyList.removeLastKey();
// //   keyList.removeLastKey();
// //   keyList.removeLastKey();
// //   keyList.removeLastKey();
// //   keyList.removeLastKey();
// // }

// // class KeyList {
// //   KeyList();
// //   int operationCount = 1;
// //   final keyList = <String>{};

// //   void printList() {
// //     final text =
// //         "[$operationCount]\n${keyList.map((key) => "- $key").join("\n")}";
// //     print(text);
// //   }

// //   void addKey(String key) {
// //     final prefixKey = keyList.isNotEmpty ? "${keyList.last}." : "";
// //     final newKey = "$prefixKey$key";
// //     keyList.add(newKey);
// //     printList();
// //     operationCount++;
// //   }

// //   void removeLastKey() {
// //     if (keyList.isEmpty) return;
// //     keyList.remove(keyList.last);
// //     printList();
// //     operationCount++;
// //   }
// // }
