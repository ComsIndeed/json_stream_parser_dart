import 'package:json_stream_parser/classes/json_stream_parser.dart';
import 'package:json_stream_parser/utilities/stream_text_in_chunks.dart';

void main() async {
  try {
    final json = '''
  {
    "name": "ABCDEFG",
    "bio": "1234567890",
  }
  ''';

    final stream = streamTextInChunks(
      text: json,
      chunkSize: 10,
      interval: Duration(milliseconds: 50),
    );

    final parser = JsonStreamParser(stream);
    final nameStream = parser.getStringProperty("name");
    final bioStream = parser.getStringProperty("bio");

    nameStream.stream.listen((chunk) {
      print('Name chunk: "$chunk"');
    });

    bioStream.future.then((finalBio) {
      print('Final bio: "$finalBio"');
    });

    await bioStream.future;
  } catch (e) {
    print('Error during parsing: $e');
  }
}
