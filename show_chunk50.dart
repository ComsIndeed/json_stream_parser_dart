void main() {
  const json =
      '{"name":"Sample Item","description":"This is a very long description that could potentially span multiple lines and contain a lot of information about the item, including its features, benefits, and usage.","tags":["sample tag 1 with some extra info","sample tag 2 with more details","sample tag 3 that is a bit longer"],"details":{"color":"red","size":"large","weight":"1.5kg","material":"plastic"},"status":"active"}';

  print('JSON length: ${json.length}');
  print('');

  print('Chunk size = 50:');
  for (int i = 0; i < json.length; i += 50) {
    final end = (i + 50 > json.length) ? json.length : i + 50;
    final chunk = json.substring(i, end);
    print('  Chunk ${(i / 50).floor()} [$i-$end): "$chunk"');
  }
}
