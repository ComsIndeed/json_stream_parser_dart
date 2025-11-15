import 'dart:convert';

/// Debug script to see exact chunk boundaries
void main() {
  final json = jsonEncode({
    "name": "Sample Item",
    "description":
        "This is a very long description that could potentially span multiple lines and contain a lot of information about the item, including its features, benefits, and usage.",
    "tags": [
      "sample tag 1 with some extra info",
      "sample tag 2 with more details",
      "sample tag 3 that is a bit longer",
    ],
    "details": {
      "color": "red",
      "size": "large",
      "weight": "1.5kg",
      "material": "plastic",
    },
    "status": "active",
  });

  print('JSON length: ${json.length} chars');
  print('JSON: $json\n');

  // Test chunk size 25 (fails)
  print('=' * 80);
  print('CHUNK SIZE = 25 (FAILS)');
  print('=' * 80);
  showChunks(json, 25);

  print('\n${'=' * 80}');
  print('CHUNK SIZE = 50 (FAILS)');
  print('=' * 80);
  showChunks(json, 50);

  print('\n${'=' * 80}');
  print('CHUNK SIZE = 10 (WORKS)');
  print('=' * 80);
  showChunks(json, 10);

  print('\n${'=' * 80}');
  print('CHUNK SIZE = 100 (WORKS)');
  print('=' * 80);
  showChunks(json, 100);
}

void showChunks(String text, int chunkSize) {
  int numChunks = (text.length / chunkSize).ceil();

  for (int i = 0; i < numChunks; i++) {
    int start = i * chunkSize;
    int end =
        (start + chunkSize < text.length) ? start + chunkSize : text.length;
    String chunk = text.substring(start, end);

    print('Chunk ${i + 1} [$start-$end): "$chunk"');

    // Highlight special characters at boundaries
    if (chunk.isNotEmpty) {
      print('  First char: "${chunk[0]}" (code: ${chunk[0].codeUnitAt(0)})');
      print(
          '  Last char: "${chunk[chunk.length - 1]}" (code: ${chunk[chunk.length - 1].codeUnitAt(0)})');
    }
  }

  print('Total chunks: $numChunks');
}
