import 'dart:convert';

import 'package:llm_json_stream/llm_json_stream.dart';

void main() async {
  final json = jsonEncode({
    "title": "Top Programming Tips",
    "items": [
      {"name": "Dart Basics"},
      {"name": "Advanced Patterns"}
    ],
    "author": "Dev Expert",
    "version": 1.0
  });

  final Stream<String> stream = streamTextInChunks(
          text: json, chunkSize: 5, interval: Duration(milliseconds: 100))
      .asBroadcastStream();

  final parser = JsonStreamParser(stream);

  final titleStream = parser.getStringProperty('title');
  titleStream.stream.listen((chunk) {
    print("TITLE: |$chunk|");
  });

  final itemsList = parser.getListProperty('items');
  itemsList.onElement((element, index) {
    if (element is MapPropertyStream) {
      element.getStringProperty('name').stream.listen((chunk) {
        print('Item $index: |$chunk|');
      });
    }
  });

  final author = await parser.getStringProperty('author').future;
  final version = await parser.getNumberProperty('version').future;

  await itemsList.future;

  print('\nAuthor: $author | Version: $version');
  await parser.dispose();
}

/// Simulates a stream that yields chunks of text at specified intervals.
Stream<String> streamTextInChunks({
  required String text,
  required int chunkSize,
  required Duration interval,
}) async* {
  int totalLength = text.length;
  int numChunks = (totalLength / chunkSize).ceil();
  for (int i = 0; i < numChunks; i++) {
    int start = i * chunkSize;
    int end =
        (start + chunkSize < totalLength) ? start + chunkSize : totalLength;
    String chunk = text.substring(start, end);
    yield chunk;
    await Future.delayed(interval);
  }
}
