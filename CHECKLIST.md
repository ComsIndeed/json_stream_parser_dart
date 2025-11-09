# JSON Stream Parser - Implementation Checklist

## 🔴 Critical Issues (Blocking Core Functionality)

### 1. ListPropertyDelegate Missing Core Implementation
**Status:** 🔴 CRITICAL - Blocks list functionality completely

**Problems:**
- [ ] Missing state machine for list parsing (similar to MapPropertyDelegate) (Please expand on this)
- [x] Does not handle closing bracket `]` to complete the list
- [x] Does not handle commas `,` between elements
- [x? (I already make it handle closing brackets, shouldnt this fix the issue?)] Does not handle empty arrays `[]`
- [x] Does not skip whitespace between elements
- [ ] Does not complete the list future when done
- [ ] Does not build and emit the final list value

**Current State:**
- Only creates child delegates when it sees value-starting characters
- Never marks itself as `isDone`
- Never calls `onComplete()`
- Never completes the ListPropertyStreamController

**What's Needed:**
```dart
// Add state machine enum
enum ListParserState {
  waitingForValue,
  readingValue,
  waitingForCommaOrEnd,
}

// Add state tracking
ListParserState _state = ListParserState.waitingForValue;
List<dynamic> _elements = []; // Store parsed elements

// Handle closing bracket and completion
if (character == ']') {
  isDone = true;
  parserController.addPropertyChunk<List<Object?>>(
    propertyPath: propertyPath,
    chunk: _elements,
  );
  onComplete?.call();
}

// Handle commas
if (_state == ListParserState.waitingForCommaOrEnd && character == ',') {
  _state = ListParserState.waitingForValue;
}
```

**Reference:** Look at `MapPropertyDelegate` lines 95-106 for completion logic

---

### 2. ListPropertyDelegate Missing onElement Callback Invocation
**Status:** 🔴 CRITICAL - "Arm the trap" mechanism doesn't work

**Problems:**
- [ ] Currently gets callbacks from constructor but doesn't actually use controller's callbacks
- [ ] Should retrieve callbacks from `ListPropertyStreamController` dynamically
- [ ] Callbacks are never invoked when elements are discovered

**Current Issue:**
```dart
// In ListPropertyDelegate constructor - callbacks come from constructor param
this.onElementCallbacks = const [],

// Should instead get them from the controller:
final controller = parserController.getPropertyStreamController(
  propertyPath,
) as ListPropertyStreamController;
for (final callback in controller.onElementCallbacks) {
  callback(delegate.propertyStream);
}
```

**Test That's Failing:**
- `test/properties/list_property_test.dart` line 275: `colorsStream.onElement((index, element) {...})`

---

### 3. ListPropertyStream Missing onElement() Method
**Status:** 🔴 CRITICAL - Public API incomplete

**Problem:**
- [ ] `ListPropertyStream` class doesn't have an `onElement()` method
- [ ] Test code calls this method but it doesn't exist
- [ ] README documents this API but it's not implemented

**What's Needed:**
```dart
class ListPropertyStream extends PropertyStream<List<Object?>> {
  // Add this method:
  void onElement(void Function(int index, PropertyStream element) callback) {
    final controller = _parserController.getPropertyStreamController(
      /* need to track propertyPath */
    ) as ListPropertyStreamController;
    controller.addOnElementCallback(callback);
  }
}
```

**Issue:** `ListPropertyStream` doesn't store its `propertyPath`, so it can't look up its controller!

---

### 4. PropertyStream Classes Missing propertyPath Field
**Status:** 🔴 CRITICAL - Prevents chaining from working properly

**Problem:**
- [ ] `MapPropertyStream` and `ListPropertyStream` need to prepend their path to child paths
- [ ] Currently they pass the path as-is to the parser controller
- [ ] This breaks nested path resolution

**Example Bug:**
```dart
final userMap = parser.getMapProperty("user");
final name = userMap.getStringProperty("name");
// This looks up "name" but should look up "user.name"!
```

**What's Needed:**
```dart
class MapPropertyStream extends PropertyStream<Map<String, Object?>> {
  final String _propertyPath;
  
  MapPropertyStream({
    required super.future,
    required super.parserController,
    required String propertyPath, // Add this parameter
  }) : _propertyPath = propertyPath;

  StringPropertyStream getStringProperty(String key) {
    final fullPath = _propertyPath.isEmpty ? key : '$_propertyPath.$key';
    return _parserController
        .getPropertyStreamController(fullPath)
        .propertyStream as StringPropertyStream;
  }
}
```

---

## 🟡 High Priority Issues (Functionality Gaps)

### 5. Whitespace Handling Missing
**Status:** 🟡 HIGH - Causes parsing failures with formatted JSON

**Problems:**
- [ ] `ListPropertyDelegate` doesn't skip whitespace before values
- [ ] Should ignore ` `, `\t`, `\n`, `\r` when not in a value

**What's Needed:**
```dart
if (!_isReadingValue && (character == ' ' || character == '\t' || 
    character == '\n' || character == '\r')) {
  return; // Skip whitespace
}
```

**Test That Needs This:**
- `test/properties/list_property_test.dart` line 317: `'{ "values" : [ 1 , 2 , 3 ] }'`

---

### 6. List Element Collection Missing
**Status:** 🟡 HIGH - Lists never accumulate their elements

**Problem:**
- [ ] When child delegates complete, their values aren't stored
- [ ] List future never resolves with the actual list content
- [ ] Need to store parsed values and emit them on completion

**What's Needed:**
```dart
class ListPropertyDelegate {
  final List<dynamic> _elements = [];
  
  void onChildComplete() {
    // Store the completed child's value
    final childPath = _currentElementPath;
    final childController = parserController.getPropertyStreamController(childPath);
    final childValue = await childController.completer.future;
    _elements.add(childValue);
    
    _isReadingValue = false;
    _activeChildDelegate = null;
    _index += 1;
  }
}
```

---

### 7. Analysis Options Error
**Status:** 🟡 HIGH - Prevents code analysis from running

**Problem:**
```yaml
# analysis_options.yaml line 17
prefer_final_fields: ignore ignore  # ❌ INVALID - has "ignore" twice
```

**Fix:**
```yaml
prefer_final_fields: ignore  # ✅ CORRECT
```

---

## 🟢 Medium Priority Issues (Code Quality)

### 8. Unused Field Warning
**Status:** 🟢 MEDIUM - Code quality issue

**File:** `lib/classes/json_stream_parser.dart` line 203
```dart
final Set<String> _previousPropertyControllerKeys = {};
// This field is never used - remove it or implement its purpose
```

---

### 9. Unused Import Warnings
**Status:** 🟢 MEDIUM - Code cleanliness

**Files with unused imports:**
- [ ] `test/properties/list_property_test.dart` line 3: `import 'package:json_stream_parser/json_stream_parser.dart';`
- [ ] `test/properties/map_property_test.dart` line 3: Same import
- [ ] `test/properties/null_property_test.dart` line 3: Same import
- [ ] `test/properties/number_property_test.dart` line 3: Same import
- [ ] `lib/classes/mixins.dart` line 9: `import 'package:json_stream_parser/classes/property_stream.dart';`

**Fix:** Remove these unused imports

---

### 10. Unused Variable Warning
**Status:** 🟢 MEDIUM - Dead code

**File:** `lib/test.dart` line 6
```dart
final stream = streamTextInChunks(...);
// Variable declared but never used
```

---

### 11. TODO Comments Not Addressed
**Status:** 🟢 MEDIUM - Technical debt

**Files with TODOs:**
- [ ] `lib/classes/json_stream_parser.dart` line 170: `// TODO: Fix casting. Maybe remove generics?`
- [ ] `test/properties/string_property_test.dart` line 8: `// TODO: HANDLE ESCAPE SEQUENCES IN STRINGS MORE CLEARLY`
- [ ] `test/properties/string_property_test.dart` line 51: `// TODO: Reconsider if the expected finalValue should contain the literal \n or an actual newline character`
- [ ] `lib/src/json_stream_parser_base.dart` line 1: `// TODO: Put public facing types in this file.`
- [ ] `lib/json_stream_parser.dart` line 8: `// TODO: Export any libraries intended for clients of this package.`

---

## 🔵 Low Priority Issues (Polish)

### 12. Property Delegate Comment Outdated
**Status:** 🔵 LOW - Documentation

**File:** `lib/classes/property_delegates/property_delegate.dart` lines 39-47
```dart
///
/// ! THIS IS WHERE YOU LEFT OFF
///
/// YOU HAVE TO FIX THIS METHOD SO THAT STREAMING WORKS
///
/// YOU NEED TO FIGURE OUT HOW TO "ADD" OR "EMIT" VALUES TO [PROPERTYSTREAMS]
/// DO REMEMBER THERE ARE DIFFERENT TYPES WITH DIFFERENT EMISSION REQUIREMENTS AND DIFFERENT PUBLIC APIS
///
```

This comment is outdated - the issue was already solved. Can be removed.

---

### 13. Mixin Comment Outdated
**Status:** 🔵 LOW - Documentation

**File:** `lib/classes/mixins.dart` lines 80-82
```dart
/// ! You left off trying to determine what would be the interface for the map stream properties and such, so that you could emit values from the delegates
///
/// You did really well again, goodjob!
```

This is outdated - can be removed.

---

## 📋 Implementation Priority Order

### Phase 1: Core List Functionality (Do First)
1. ✅ Fix `analysis_options.yaml` (5 seconds)
2. ✅ Add `propertyPath` field to `MapPropertyStream` and `ListPropertyStream`
3. ✅ Implement `ListPropertyDelegate` state machine
4. ✅ Add list element collection in `onChildComplete()`
5. ✅ Add list completion logic (handle `]`)
6. ✅ Add whitespace handling in `ListPropertyDelegate`

### Phase 2: onElement Feature (Do Second)
7. ✅ Add `onElement()` method to `ListPropertyStream`
8. ✅ Fix `ListPropertyDelegate` to use controller's callbacks
9. ✅ Test `onElement` functionality

### Phase 3: Code Quality (Do Third)
10. ✅ Remove unused imports
11. ✅ Remove unused field `_previousPropertyControllerKeys`
12. ✅ Remove unused variable in `test.dart`
13. ✅ Clean up outdated TODO comments
14. ✅ Remove outdated code comments

---

## 🧪 Test Coverage Status

### ✅ Passing Tests
- [x] String property tests (all passing)
- [x] Number property tests (all passing)
- [x] Boolean property tests (all passing)
- [x] Null property tests (all passing)
- [x] Map property tests (all passing)

### 🔴 Failing Tests
- [ ] **All list property tests** - ListPropertyDelegate incomplete
- [ ] `simple list - get entire list` - List doesn't complete
- [ ] `list of strings` - List doesn't complete
- [ ] `array index access` - Paths not resolved
- [ ] `array of objects` - Nested paths broken
- [ ] `empty array` - `[]` not handled
- [ ] `nested arrays` - Deep paths broken
- [ ] `mixed-type array` - No element collection
- [ ] `chainable property access` - Path prepending missing
- [ ] **`list iteration with onElement`** - onElement() doesn't exist
- [ ] `deeply nested structure` - Complex paths broken
- [ ] `list with whitespace` - Whitespace not handled
- [ ] `single element array` - List doesn't complete

**Estimated Fix Time:**
- Phase 1: 2-3 hours
- Phase 2: 1-2 hours
- Phase 3: 30 minutes
- **Total: 4-6 hours of focused work**

---

## 🎯 Quick Win Recommendations

If you want to see progress fast, do these in order:

1. **Fix `analysis_options.yaml`** (30 seconds) - Unlocks error detection
2. **Add state machine to `ListPropertyDelegate`** (1 hour) - Gets basic lists working
3. **Add `propertyPath` tracking** (30 minutes) - Fixes chaining
4. **Implement `onElement()`** (45 minutes) - Completes the API

After these 4 items, most tests should pass!

---

## 📝 Notes

- The architecture is solid - most issues are in `ListPropertyDelegate`
- The `MapPropertyDelegate` is a perfect template to copy from
- The onElement feature is unique and cool - worth getting right!
- Once lists work, the parser will be feature-complete for the MVP

Good luck! 🚀
