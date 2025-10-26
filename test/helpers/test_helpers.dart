import 'dart:async';
import 'dart:convert';
import 'package:test/test.dart';

/// Helper class to accumulate stream values and validate them
class StreamAccumulator<T> {
  final List<T> values = [];
  final Completer<T> _completer = Completer<T>();

  Future<T> get future => _completer.future;

  void add(T value) {
    values.add(value);
    if (!_completer.isCompleted) {
      _completer.complete(value);
    }
  }

  void complete(T value) {
    if (!_completer.isCompleted) {
      _completer.complete(value);
    }
  }

  void completeError(Object error) {
    if (!_completer.isCompleted) {
      _completer.completeError(error);
    }
  }

  String getAccumulatedString() {
    return values.join('');
  }

  void clear() {
    values.clear();
  }
}

/// Test runner that simulates streaming JSON chunks
class JsonStreamTestRunner {
  final String jsonString;
  final int chunkSize;
  final Duration interval;
  final bool verbose;

  JsonStreamTestRunner({
    required this.jsonString,
    this.chunkSize = 4,
    this.interval = const Duration(microseconds: 1),
    this.verbose = false,
  });

  /// Create a stream of chunks from the JSON string
  Stream<String> createChunkStream() async* {
    if (verbose) {
      print('\n📦 Starting stream for: $jsonString');
      print('   Chunk size: $chunkSize, Total length: ${jsonString.length}');
    }

    int totalLength = jsonString.length;
    int numChunks = (totalLength / chunkSize).ceil();

    for (int i = 0; i < numChunks; i++) {
      int start = i * chunkSize;
      int end = (start + chunkSize < totalLength)
          ? start + chunkSize
          : totalLength;

      String chunk = jsonString.substring(start, end);

      if (verbose) {
        print('   📤 Chunk ${i + 1}/$numChunks: "$chunk"');
      }

      yield chunk;
      await Future.delayed(interval);
    }

    if (verbose) {
      print('   ✅ Stream completed\n');
    }
  }

  /// Run a test with the given stream processor
  Future<void> runTest<T>({
    required Future<T> Function(Stream<String>) processor,
    required T expectedValue,
    required String testDescription,
  }) async {
    if (verbose) {
      print('\n🧪 Running test: $testDescription');
    }

    final stream = createChunkStream();
    final result = await processor(stream);

    if (verbose) {
      print('   Expected: $expectedValue');
      print('   Got: $result');
    }

    expect(result, equals(expectedValue), reason: testDescription);

    if (verbose) {
      print('   ✅ Test passed!\n');
    }
  }
}

/// Pretty printer for test output
class TestPrinter {
  static void printTestGroup(String groupName) {
    print('\n${'=' * 60}');
    print('🔬 TEST GROUP: $groupName');
    print('=' * 60);
  }

  static void printTestCase(String testName) {
    print('\n  ▶️  $testName');
  }

  static void printChunk(String chunk, int index, int total) {
    print('     Chunk $index/$total: "$chunk"');
  }

  static void printAccumulated(String accumulated) {
    print('     Accumulated: "$accumulated"');
  }

  static void printResult(dynamic result) {
    print('     ✅ Result: $result');
  }

  static void printExpected(dynamic expected) {
    print('     📋 Expected: $expected');
  }

  static void printPassed() {
    print('     ✅ PASSED');
  }

  static void printFailed(String reason) {
    print('     ❌ FAILED: $reason');
  }
}

/// Helper to create various chunk sizes for testing
class ChunkSizeVariations {
  static List<int> get standard => [1, 2, 4, 8, 16];
  static List<int> get extreme => [1, 3, 7, 13, 100];
  static List<int> get minimal => [1];
  static List<int> get quick => [4, 16];
}

/// JSON test data generator
class JsonTestData {
  // Strings
  static String get simpleString => '"hello"';
  static String get stringWithSpaces => '"hello world"';
  static String get stringWithEscapes => r'"hello \"world\""';
  static String get stringWithNewline => r'"hello\nworld"';
  static String get stringWithTab => r'"hello\tworld"';
  static String get emptyString => '""';
  static String get longString => '"${"a" * 1000}"';
  static String get unicode => '"Hello 👋 World 🌍"';

  // Numbers
  static String get positiveInt => '42';
  static String get negativeInt => '-42';
  static String get zero => '0';
  static String get positiveFloat => '3.14';
  static String get negativeFloat => '-3.14';
  static String get largeNumber => '999999999';
  static String get smallDecimal => '0.0001';

  // Booleans
  static String get trueValue => 'true';
  static String get falseValue => 'false';

  // Null
  static String get nullValue => 'null';

  // Maps - Flat
  static String flatMapStringToString() =>
      jsonEncode({'name': 'John', 'city': 'New York', 'country': 'USA'});

  static String flatMapMixedValues() => jsonEncode({
    'name': 'John',
    'age': 30,
    'isActive': true,
    'score': 95.5,
    'nickname': null,
  });

  static String flatMapManyProperties() => jsonEncode({
    'prop1': 'value1',
    'prop2': 'value2',
    'prop3': 'value3',
    'prop4': 'value4',
    'prop5': 'value5',
    'prop6': 'value6',
    'prop7': 'value7',
    'prop8': 'value8',
    'prop9': 'value9',
    'prop10': 'value10',
  });

  // Maps - Nested
  static String nestedMaps() => jsonEncode({
    'user': {
      'name': 'John',
      'address': {'street': '123 Main St', 'city': 'New York'},
    },
  });

  static String mapWithLists() => jsonEncode({
    'name': 'John',
    'hobbies': ['reading', 'gaming', 'coding'],
    'scores': [10, 20, 30],
  });

  static String complexNestedMap() => jsonEncode({
    'users': [
      {
        'name': 'Alice',
        'tags': ['admin', 'user'],
        'metadata': {'created': '2024-01-01', 'active': true},
      },
      {
        'name': 'Bob',
        'tags': ['user'],
        'metadata': {'created': '2024-01-02', 'active': false},
      },
    ],
    'count': 2,
  });

  // Lists - Flat
  static String flatStringList() => jsonEncode(['apple', 'banana', 'cherry']);
  static String flatNumberList() => jsonEncode([1, 2, 3, 4, 5]);
  static String flatMixedList() => jsonEncode(['hello', 42, true, null, 3.14]);
  static String emptyList() => jsonEncode([]);

  // Lists - Nested
  static String listWithMaps() => jsonEncode([
    {'name': 'Alice', 'age': 30},
    {'name': 'Bob', 'age': 25},
  ]);

  static String nestedLists() => jsonEncode([
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 9],
  ]);

  static String complexNestedList() => jsonEncode([
    'string',
    123,
    [
      1,
      2,
      [3, 4],
    ],
    {
      'key': 'value',
      'nested': {'deep': true},
    },
    null,
  ]);
}

/// Validator for test assertions
class JsonStreamValidator {
  /// Validate that accumulated chunks match expected value
  static void validateAccumulatedString(
    List<String> chunks,
    String expected, {
    String? message,
  }) {
    final accumulated = chunks.join('');
    expect(
      accumulated,
      equals(expected),
      reason: message ?? 'Accumulated chunks should match expected value',
    );
  }

  /// Validate that parsed JSON matches expected value
  static void validateParsedJson(
    String jsonString,
    dynamic expected, {
    String? message,
  }) {
    final parsed = jsonDecode(jsonString);
    expect(
      parsed,
      equals(expected),
      reason: message ?? 'Parsed JSON should match expected value',
    );
  }

  /// Validate stream emissions
  static Future<void> validateStream<T>(
    Stream<T> stream,
    List<T> expectedValues, {
    String? message,
    bool verbose = false,
  }) async {
    final List<T> actual = [];

    await for (final value in stream) {
      actual.add(value);
      if (verbose) {
        print('     Emitted: $value');
      }
    }

    expect(
      actual,
      equals(expectedValues),
      reason: message ?? 'Stream values should match expected values',
    );
  }
}
