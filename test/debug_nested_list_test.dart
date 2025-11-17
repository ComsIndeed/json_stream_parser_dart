import 'dart:async';

import 'package:llm_json_stream/classes/json_stream_parser.dart';
import 'package:test/test.dart';

void main() {
  test('debug: map with nested list', () async {
    final json = '{"tags":["a","b"]}';

    final controller = StreamController<String>();
    final parser = JsonStreamParser(controller.stream);

    final mapStream = parser.getMapProperty("");

    // Add the JSON
    controller.add(json);
    await controller.close();

    // Wait for map to complete
    final map = await mapStream.future;

    print('Map result: $map');
    print('Tags value: ${map['tags']}');
    print('Tags type: ${map['tags'].runtimeType}');

    expect(map['tags'], equals(['a', 'b']));
  });

  test('debug: map with nested list - getting list separately', () async {
    final json = '{"tags":["a","b"]}';

    final controller = StreamController<String>();
    final parser = JsonStreamParser(controller.stream);

    final mapStream = parser.getMapProperty("");
    final tagsStream = parser.getListProperty("tags");

    // Add the JSON
    controller.add(json);
    await controller.close();

    // Wait for both to complete
    final map = await mapStream.future;
    final tags = await tagsStream.future;

    print('Map result: $map');
    print('Tags from map: ${map['tags']}');
    print('Tags from stream: $tags');

    expect(tags, equals(['a', 'b']));
    expect(map['tags'], equals(['a', 'b']));
  });
}
