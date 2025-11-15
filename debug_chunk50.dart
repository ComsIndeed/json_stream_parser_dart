import 'dart:async';
import 'lib/json_stream_parser.dart';
import 'lib/utilities/stream_text_in_chunks.dart';

void main() async {
  const json = '{"tags":["sample details"],"key":"val"}';

  print('JSON: $json');
  print('Length: ${json.length}');
  print('');

  // Test with chunk=10 (fails with |})
  print('======== TESTING CHUNK=10 ========');
  await testChunkSize(json, 10);

  print('');

  // Test with chunk=50
  print('======== TESTING CHUNK=50 ========');
  const apiJson =
      '{"name":"Sample Item","description":"This is a very long description that could potentially span multiple lines and contain a lot of information about the item, including its features, benefits, and usage.","tags":["sample tag 1 with some extra info","sample tag 2 with more details","sample tag 3 that is a bit longer"],"details":{"color":"red","size":"large","weight":"1.5kg","material":"plastic"},"status":"active"}';
  await testChunkSize(apiJson, 50);
}

Future<void> testChunkSize(String json, int chunkSize) async {
  print('Chunks:');
  for (int i = 0; i < json.length; i += chunkSize) {
    final end = (i + chunkSize > json.length) ? json.length : i + chunkSize;
    final chunk = json.substring(i, end);
    print('  [$i-$end): "$chunk"');
  }
  print('');

  final stream = streamTextInChunks(
      text: json, chunkSize: chunkSize, interval: Duration.zero);
  final parser = JsonStreamParser(stream);

  print('Parsing...');
  try {
    final keyProp = parser.getStringProperty('key');
    final result = await keyProp.future.timeout(Duration(seconds: 5));
    print('✅ SUCCESS: $result');
  } catch (e, stack) {
    print('❌ ERROR: $e');
    final lines = stack.toString().split('\n');
    for (final line in lines.take(10)) {
      print('  $line');
    }
  }
}
