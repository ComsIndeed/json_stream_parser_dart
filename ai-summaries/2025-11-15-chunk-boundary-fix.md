# Chunk Boundary Bug Fix - 2025-11-15

## Problem
Parser failed when chunk size was larger than some values, specifically with chunk=50 on the API demo JSON. The parser would timeout after 30 seconds.

## Root Cause
When a parent map delegate created child delegates (for values), it passed `onComplete: onChildComplete` as the callback. However, ALL children shared the SAME `onChildComplete` method reference.

When a PREVIOUS child completed asynchronously (e.g., a list completing after the parent had moved on to process a nested map), it would call the parent's `onChildComplete()` method. This would:
1. Clear `_activeChildDelegate` even though the currently active child was a DIFFERENT delegate
2. Transition the parent's state to `waitingForCommaOrEnd`
3. Cause the parent to steal characters meant for the currently active child

### Specific Example
With the API demo JSON and chunk=50:
1. Root map creates list delegate for "tags" array
2. Tags list starts processing, root's `_activeChildDelegate` points to tags list
3. Root moves on and creates map delegate for "details" nested object
4. Root's `_activeChildDelegate` now points to details map
5. Tags list completes asynchronously and calls root's `onChildComplete()`
6. Root's `onChildComplete()` clears `_activeChildDelegate` (which was pointing to details!)
7. Root transitions to `waitingForCommaOrEnd`
8. Subsequent characters meant for details map are processed by root instead
9. Root creates properties "weight" and "material" as root-level properties (should be in details)
10. Parser gets into corrupted state and times out

## Solution
Modified the `waitingForValue` state handler in `MapPropertyDelegate.addCharacter()` to create a closure that captures the child delegate instance and checks if it's still the active child before calling `onChildComplete()`:

```dart
// Old code (problematic):
_activeChildDelegate = createDelegate(
  character,
  propertyPath: newPath(_keyBuffer),
  jsonStreamParserController: parserController,
  onComplete: onChildComplete,  // All children share same callback!
);

// New code (fixed):
PropertyDelegate? childDelegate;
childDelegate = createDelegate(
  character,
  propertyPath: newPath(_keyBuffer),
  jsonStreamParserController: parserController,
  onComplete: () {
    // Only notify parent if this child is still the active one
    if (_activeChildDelegate == childDelegate) {
      onChildComplete();
    }
  },
);
_activeChildDelegate = childDelegate;
```

The closure captures the specific child delegate instance and compares it with `_activeChildDelegate` before calling `onChildComplete()`. This ensures that late-completing children don't interfere with newer children.

## Testing
All 159 tests pass, including:
- ✅ All chunk sizes (1, 5, 10, 25, **50**, 100, 500, 1000) with the API demo JSON
- ✅ All speed variations (0ms, 5ms, 50ms, 100ms intervals)
- ✅ Both futures AND accumulated stream chunks match expected values
- ✅ Nested structures with multiple levels of maps and arrays
- ✅ Edge cases with chunk boundaries splitting keys, values, and delimiters

The previously failing `chunk=50, interval=10ms` test now passes consistently.

## Files Modified
- `lib/classes/property_delegates/map_property_delegate.dart` - Lines 86-99 (waitingForValue handler)

## Impact
This fix ensures the parser correctly handles:
1. Chunk boundaries at any position in the JSON
2. Asynchronous completion of child delegates (lists, nested maps)
3. Multiple levels of nesting with various chunk sizes
4. Values of any size relative to chunk size
