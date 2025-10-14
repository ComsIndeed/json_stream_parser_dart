Stream<String> streamTextInChunks({
  required String text,
  required int chunkSize,
  required Duration interval,
}) async* {
  // Calculate the number of chunks we'll need.
  int totalLength = text.length;
  int numChunks = (totalLength / chunkSize).ceil();

  // Loop through each chunk index.
  for (int i = 0; i < numChunks; i++) {
    // Determine the start and end indices for the current chunk.
    int start = i * chunkSize;
    // The end is either the next chunk's start or the total length,
    // whichever comes first (to handle the final, possibly smaller chunk).
    int end = (start + chunkSize < totalLength)
        ? start + chunkSize
        : totalLength;

    // Get the substring for the current chunk.
    String chunk = text.substring(start, end);

    // 'yield' is the magic word for async* functions. It adds the value
    // to the stream and pauses until the next iteration.
    yield chunk;

    // Wait for the specified interval before yielding the next chunk.
    // This is what makes it "stream" over time.
    await Future.delayed(interval);
  }
}
