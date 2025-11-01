import 'package:json_stream_parser/classes/json_stream_parser.dart';
import 'package:json_stream_parser/utilities/stream_text_in_chunks.dart';

void main() async {
  try {
    final json =
        '''{"parent": {"child": "Hello, World!"}, "number": 42, "newNested": {"deepChild": {"grandChild": "Hello, Grandchild!"}}, "nothing": null}''';

    final stream = streamTextInChunks(
      text: json,
      chunkSize: 10,
      interval: Duration(milliseconds: 50),
    );

    final parser = JsonStreamParser(stream);

    parser
        .getMapProperty("newNested.deepChild")
        .getStringProperty("grandChild")
        .stream
        .listen((value) {
          print('Grandchild Value Chunk: $value');
        });

    await Future.delayed(Duration(seconds: 1));
  } catch (e) {
    print('Error during parsing: $e');
  }
}
