# Data Flow

This document provides complete examples of data flowing through the parser.

## Example 1: Simple String Property

**JSON:** `{"name": "Alice"}`

**User Code:**
```dart
final parser = JsonStreamParser(stream);
final nameStream = parser.getStringProperty('name');
nameStream.stream.listen((chunk) => print('Chunk: $chunk'));
final name = await nameStream.future;
print('Final: $name');
```

### Flow Diagram

```mermaid
sequenceDiagram
    participant User
    participant Parser as JsonStreamParser
    participant SPSC as StringPropertyStreamController
    participant MPD as MapPropertyDelegate
    participant SPD as StringPropertyDelegate
    
    User->>Parser: getStringProperty('name')
    Parser->>SPSC: create controller
    Parser-->>User: StringPropertyStream
    User->>SPSC: listen to stream
    
    Note over Parser: Stream emits: {"name": "Alice"}
    
    Parser->>MPD: create root delegate
    Parser->>MPD: addCharacter('{')
    Parser->>MPD: addCharacter('"')
    MPD->>MPD: state → readingKey
    Parser->>MPD: addCharacter('n')
    MPD->>MPD: _keyBuffer.write('n')
    Parser->>MPD: addCharacter('a')
    Parser->>MPD: addCharacter('m')
    Parser->>MPD: addCharacter('e')
    Parser->>MPD: addCharacter('"')
    MPD->>MPD: state → waitingForValue
    Parser->>MPD: addCharacter(':')
    Parser->>MPD: addCharacter(' ')
    Parser->>MPD: addCharacter('"')
    
    Note over MPD: Value starts - create child delegate
    MPD->>SPD: create delegate for 'name'
    MPD->>SPD: addCharacter('"')
    
    Parser->>MPD: addCharacter('A')
    MPD->>SPD: addCharacter('A')
    SPD->>SPD: _buffer.write('A')
    
    Parser->>MPD: addCharacter('l'...'e')
    MPD->>SPD: addCharacter('l'...'e')
    SPD->>SPD: _buffer.write(...)
    
    Parser->>MPD: addCharacter('"')
    MPD->>SPD: addCharacter('"')
    SPD->>SPSC: addChunk('Alice')
    SPSC-->>User: stream event: 'Alice'
    SPD->>SPSC: complete('')
    SPSC-->>User: future resolves: 'Alice'
    SPD-->>MPD: onComplete()
    
    Parser->>MPD: addCharacter('}')
    MPD->>MPD: isDone = true
```

---

## Example 2: Nested Map

**JSON:** `{"user": {"name": "Bob", "age": 30}}`

**User Code:**
```dart
final parser = JsonStreamParser(stream);
final name = await parser.getStringProperty('user.name').future;
final age = await parser.getNumberProperty('user.age').future;
```

### Flow Diagram

```mermaid
sequenceDiagram
    participant Parser
    participant RootMap as MapDelegate<br/>(root)
    participant UserMap as MapDelegate<br/>(user)
    participant NameStr as StringDelegate<br/>(user.name)
    participant AgeNum as NumberDelegate<br/>(user.age)
    participant NameCtrl as StringController
    participant AgeCtrl as NumberController
    
    Note over Parser: {"user": {"name": "Bob", "age": 30}}
    
    Parser->>RootMap: addCharacter('{')
    
    Note over RootMap: Parse key "user"
    
    Parser->>RootMap: addCharacter('"')
    Parser->>RootMap: addCharacter('u','s','e','r')
    Parser->>RootMap: addCharacter('"')
    Parser->>RootMap: addCharacter(':')
    Parser->>RootMap: addCharacter(' ')
    Parser->>RootMap: addCharacter('{')
    
    RootMap->>UserMap: create delegate
    RootMap->>UserMap: addCharacter('{')
    
    Note over UserMap: Parse key "name"
    
    Parser->>RootMap: addCharacter('"')
    RootMap->>UserMap: addCharacter('"')
    Parser->>RootMap: addCharacter('n','a','m','e')
    RootMap->>UserMap: addCharacter(...)
    Parser->>RootMap: addCharacter('"')
    RootMap->>UserMap: addCharacter('"')
    Parser->>RootMap: addCharacter(':')
    RootMap->>UserMap: addCharacter(':')
    
    Note over UserMap: Create string delegate
    
    Parser->>RootMap: addCharacter('"')
    RootMap->>UserMap: addCharacter('"')
    UserMap->>NameStr: create delegate
    
    Parser->>RootMap: addCharacter('B','o','b')
    RootMap->>UserMap: addCharacter(...)
    UserMap->>NameStr: addCharacter(...)
    
    Parser->>RootMap: addCharacter('"')
    RootMap->>UserMap: addCharacter('"')
    UserMap->>NameStr: addCharacter('"')
    NameStr->>NameCtrl: complete('Bob')
    NameStr-->>UserMap: onComplete()
    
    Note over UserMap: Parse "age": 30
    
    Parser->>RootMap: addCharacter(',')
    RootMap->>UserMap: addCharacter(',')
    
    Note over UserMap: ... parse age key ...
    
    Parser->>RootMap: addCharacter('3','0')
    RootMap->>UserMap: addCharacter(...)
    UserMap->>AgeNum: addCharacter(...)
    
    Parser->>RootMap: addCharacter('}')
    RootMap->>UserMap: addCharacter('}')
    UserMap->>AgeNum: addCharacter('}')
    AgeNum->>AgeCtrl: complete(30)
    AgeNum-->>UserMap: onComplete()
    UserMap->>UserMap: isDone = true
    UserMap-->>RootMap: onComplete()
    
    Parser->>RootMap: addCharacter('}')
    RootMap->>RootMap: isDone = true
```

---

## Example 3: Array with onElement

**JSON:** `{"items": [{"id": 1}, {"id": 2}]}`

**User Code:**
```dart
final parser = JsonStreamParser(stream);
final items = parser.getListProperty('items');

items.onElement((element, index) {
  print('Element $index started');
  if (element is MapPropertyStream) {
    element.getNumberProperty('id').future.then((id) {
      print('Item $index has id: $id');
    });
  }
});
```

### Flow Diagram

```mermaid
sequenceDiagram
    participant User
    participant Parser
    participant RootMap as MapDelegate
    participant ListDel as ListDelegate<br/>(items)
    participant Map1 as MapDelegate<br/>(items[0])
    participant Map2 as MapDelegate<br/>(items[1])
    participant ListCtrl as ListController
    
    User->>Parser: getListProperty('items')
    Parser->>ListCtrl: create controller
    User->>ListCtrl: onElement callback
    
    Note over Parser: Parse until items array
    
    Parser->>RootMap: addCharacter('[')
    RootMap->>ListDel: create delegate
    
    Parser->>RootMap: addCharacter('{')
    RootMap->>ListDel: addCharacter('{')
    ListDel->>Map1: create delegate for items[0]
    
    Note over ListCtrl: Fire onElement callback
    ListCtrl-->>User: onElement(MapStream, 0)
    User->>User: Subscribe to items[0].id
    
    Note over Map1: Parse {id: 1}
    
    ListDel->>Map1: complete
    Map1-->>ListDel: onComplete()
    
    Parser->>RootMap: addCharacter(',')
    RootMap->>ListDel: addCharacter(',')
    
    Parser->>RootMap: addCharacter('{')
    RootMap->>ListDel: addCharacter('{')
    ListDel->>Map2: create delegate for items[1]
    
    Note over ListCtrl: Fire onElement callback
    ListCtrl-->>User: onElement(MapStream, 1)
    User->>User: Subscribe to items[1].id
    
    Note over Map2: Parse {id: 2}
```

---

## Example 4: Chunked String Streaming

**Input:** Stream emits `["{"desc":"Hel", "lo World"}"]` as two chunks

**User Code:**
```dart
final parser = JsonStreamParser(stream);
parser.getStringProperty('desc').stream.listen((chunk) {
  print('Received: "$chunk"');
});
```

### Flow Diagram

```mermaid
sequenceDiagram
    participant Stream as Input Stream
    participant Parser
    participant MPD as MapDelegate
    participant SPD as StringDelegate
    participant Ctrl as StringController
    participant User
    
    Note over Stream: Emit chunk 1: {"desc":"Hel
    
    Stream->>Parser: '{"desc":"Hel'
    
    loop Each character in chunk 1
        Parser->>MPD: addCharacter(c)
        MPD->>SPD: addCharacter(c) for value chars
        SPD->>SPD: _buffer.write(c)
    end
    
    Parser->>MPD: onChunkEnd()
    MPD->>SPD: onChunkEnd()
    
    Note over SPD: Buffer has "Hel"
    SPD->>Ctrl: addChunk('Hel')
    Ctrl-->>User: stream event: 'Hel'
    SPD->>SPD: _buffer.clear()
    
    Note over Stream: Emit chunk 2: lo World"}
    
    Stream->>Parser: 'lo World"}'
    
    loop Each character until "
        Parser->>MPD: addCharacter(c)
        MPD->>SPD: addCharacter(c)
        SPD->>SPD: _buffer.write(c)
    end
    
    Parser->>MPD: addCharacter('"')
    MPD->>SPD: addCharacter('"')
    
    Note over SPD: Closing quote - complete
    SPD->>Ctrl: addChunk('lo World')
    Ctrl-->>User: stream event: 'lo World'
    SPD->>Ctrl: complete('')
    Ctrl-->>User: future resolves: 'Hello World'
```

### Output:
```
Received: "Hel"
Received: "lo World"
```

---

## Example 5: Type Mismatch Error

**JSON:** `{"count": "not a number"}`

**User Code:**
```dart
final parser = JsonStreamParser(stream);
try {
  final count = await parser.getNumberProperty('count').future;
} catch (e) {
  print('Error: $e');
}
```

### Flow Diagram

```mermaid
sequenceDiagram
    participant User
    participant Parser
    participant NumCtrl as NumberController
    participant MPD as MapDelegate
    
    User->>Parser: getNumberProperty('count')
    Parser->>NumCtrl: create NumberController
    Parser-->>User: NumberPropertyStream
    
    Note over Parser: Stream emits: {"count": "not a number"}
    
    Parser->>MPD: create root delegate
    
    Note over MPD: Parse key "count"
    
    MPD->>MPD: Key complete, waiting for value
    MPD->>MPD: First value char is '"'
    
    Note over MPD: Type detection: String
    
    MPD->>Parser: getPropertyStream('count', String)
    
    Note over Parser: Type mismatch detected!
    Parser->>Parser: NumCtrl exists but expecting String
    Parser->>NumCtrl: completeError(TypeMismatch)
    
    NumCtrl-->>User: future rejects
    User->>User: catch: "Type mismatch..."
```

### Output:
```
Error: Exception: Type mismatch at path "count": 
requested Number but found String in JSON
```

---

## Example 6: Late Subscription with Replay

**JSON:** `{"message": "Hello"}`

**Scenario:** User subscribes to stream AFTER parsing completes

```dart
final controller = StreamController<String>();
final parser = JsonStreamParser(controller.stream);

// Add all JSON at once
controller.add('{"message": "Hello"}');
controller.close();

// Wait a bit, then subscribe
await Future.delayed(Duration(milliseconds: 100));

// Even though parsing is done, stream should replay
final chunks = <String>[];
await for (final chunk in parser.getStringProperty('message').stream) {
  chunks.add(chunk);
}
print('Chunks: $chunks');  // ["Hello"]
```

### How Replay Works

```mermaid
sequenceDiagram
    participant Parser
    participant Delegate
    participant Controller
    participant Buffer as StringBuffer
    participant User
    
    Note over Parser,Buffer: Parsing completes before user subscribes
    
    Delegate->>Controller: addChunk('Hello')
    Controller->>Buffer: _buffer.write('Hello')
    Controller->>Controller: streamController.add('Hello')
    
    Note over Controller: No listeners yet, event lost from live stream
    
    Delegate->>Controller: complete('')
    Controller->>Controller: completer.complete('Hello')
    
    Note over User: User subscribes late
    
    User->>Controller: subscribe to .stream
    Controller->>Controller: createReplayableStream()
    
    Note over Controller: Check buffer
    Controller->>Buffer: toString() → 'Hello'
    Controller-->>User: yield 'Hello'
    
    Note over User: User receives buffered content!
```

---

## Summary: Complete Data Flow

```mermaid
graph TB
    subgraph Input
        IS[Input Stream<String>]
    end
    
    subgraph "Character Processing"
        IS --> JSP[JsonStreamParser]
        JSP --> PC[_parseChunk]
        PC --> |"for each char"| RD[Root Delegate]
    end
    
    subgraph "Delegate Tree"
        RD --> |"nested values"| CD1[Child Delegate]
        CD1 --> |"more nesting"| CD2[Child Delegate]
    end
    
    subgraph "Value Emission"
        CD1 --> |"addChunk"| CTRL[getPropertyStreamController]
        CD2 --> |"addChunk"| CTRL
        CTRL --> PSC[PropertyStreamController]
    end
    
    subgraph "Buffering"
        PSC --> BUF[Buffer/Last Value]
        PSC --> SC[StreamController]
        PSC --> COMP[Completer]
    end
    
    subgraph "User API"
        SC --> |"broadcast"| LS[Live Stream]
        BUF --> |"replay"| RS[Replayable Stream]
        COMP --> FUT[Future]
        
        LS --> USER[User Code]
        RS --> USER
        FUT --> USER
    end
```

---

## Key Takeaways

1. **Characters flow down** through delegate hierarchy
2. **Values flow up** through controller system
3. **Buffers enable replay** for late subscribers
4. **onChunkEnd flushes** partial string buffers
5. **Type mismatches** are caught at controller creation time
6. **Callbacks fire early** (before values complete)
