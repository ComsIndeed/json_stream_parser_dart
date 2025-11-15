# Nested Callbacks and Disposal Support

**Date:** November 15, 2025

## Summary

Added two major features to the JSON Stream Parser:

1. **Nested List `onElement` Callbacks** - Ability to set `onElement` callbacks on nested lists obtained via `getListProperty()`
2. **Parser Disposal** - Proper cleanup mechanism to prevent memory leaks

## Changes Made

### 1. Enhanced `getListProperty()` Methods

**Modified Files:**
- `lib/classes/property_stream.dart`

**Changes:**
- Added optional `onElement` parameter to `ListPropertyStream.getListProperty()`
- Added optional `onElement` parameter to `MapPropertyStream.getListProperty()`
- When `onElement` is provided, it's automatically registered with the list stream

**Before:**
```dart
ListPropertyStream<E> getListProperty<E extends Object?>(String key) {
  // Could not set onElement callback at this level
}
```

**After:**
```dart
ListPropertyStream<E> getListProperty<E extends Object?>(
  String key, {
  void Function(PropertyStream propertyStream, int index)? onElement,
}) {
  final listStream = _parserController.getPropertyStream(fullPath, List)
      as ListPropertyStream<E>;
  
  if (onElement != null) {
    listStream.onElement(onElement);
  }
  
  return listStream;
}
```

**Usage:**
```dart
// Set callback when getting nested list from MapPropertyStream
final userMap = parser.getMapProperty('user');
final itemsList = userMap.getListProperty(
  'items',
  onElement: (element, index) {
    print('Item $index discovered');
  },
);

// Or on nested lists from ListPropertyStream
final matrix = parser.getListProperty('matrix');
final firstRow = matrix.getListProperty(
  '[0]',
  onElement: (element, index) {
    print('Element $index in first row');
  },
);
```

### 2. Parser Disposal Support

**Modified Files:**
- `lib/classes/json_stream_parser.dart`

**Changes:**
- Added `_streamSubscription` field to track the stream subscription
- Added `_isDisposed` flag to prevent multiple disposal attempts
- Added `dispose()` method that:
  - Cancels the stream subscription
  - Closes all stream controllers
  - Completes pending futures with errors (if not already completed)
  - Clears all internal state

**Implementation:**
```dart
Future<void> dispose() async {
  if (_isDisposed) return;
  
  _isDisposed = true;

  // Cancel the stream subscription
  await _streamSubscription.cancel();

  // Close all stream controllers and complete pending futures with errors
  for (final controller in _propertyControllers.values) {
    if (!controller.completer.isCompleted) {
      controller.completer.completeError(
        StateError('Parser was disposed before property completed'),
      );
    }
    // Close stream controllers if they have one
  }

  // Clear all state
  _propertyControllers.clear();
  _rootDelegate = null;
}
```

**Usage:**
```dart
final parser = JsonStreamParser(llmStream);

// Use the parser...
final titleStream = parser.getStringProperty("title");
await titleStream.future;

// Clean up when done
await parser.dispose();
```

## Testing

### New Tests
Created `test/disposal_test.dart` with 5 test cases:
- ✅ Parser disposal can be called multiple times safely
- ✅ Disposal cleans up resources properly
- ✅ Nested list `onElement` callbacks work on MapPropertyStream
- ✅ Nested list `onElement` callbacks work on ListPropertyStream
- ✅ `onElement` callbacks receive correct property stream types

### Test Results
- **Total Tests:** 88
- **Status:** All passing ✅

## Documentation

### Updated Files
1. **README.md** - Added documentation for:
   - Setting `onElement` callbacks on nested lists (two methods)
   - Parser disposal API and usage

2. **todo** - Marked completed:
   - ✅ Allow for disposing the stream
   - ✅ Allow for setting callbacks from property stream object itself

### New Example
Created `example/nested_callbacks_disposal_example.dart` demonstrating:
- Setting `onElement` callbacks on nested lists
- Proper parser disposal workflow
- Real-world usage patterns

## Benefits

### 1. Nested Callbacks Support
- **More Flexible:** Can set callbacks at any nesting level
- **Better UX:** Allows reactive UI updates for deeply nested data structures
- **Cleaner Code:** Both inline and post-creation callback setting

### 2. Disposal Support
- **Prevents Memory Leaks:** Properly closes stream controllers and subscriptions
- **Safe Cleanup:** Can be called multiple times without errors
- **Clear State:** Completes pending futures with errors, preventing hanging awaits

## Breaking Changes
None. All changes are backward compatible additions.

## Migration Guide
No migration needed. Existing code continues to work as before. New features are opt-in.

## Example Output
```
=== Nested List onElement Callback Example ===

📁 Department 0 discovered!
   👤 Employee 0 discovered in department 0
   👤 Employee 1 discovered in department 0
📁 Department 1 discovered!
   👤 Employee 0 discovered in department 1
   👤 Employee 1 discovered in department 1
   Department name: Engineering
      Employee name: Alice
      Employee name: Bob
   Department name: Marketing
      Employee name: Carol
      Employee name: David
✓ Parser disposed successfully
```
