# Internals

Internal implementation details for contributors. These are not part of the public API.

> **Note**: The classes documented here are internal implementation details and are
> not exported from the public API. They are documented here for contributors who
> want to understand or modify the parser internals.

## Architecture

For a comprehensive understanding of the internal architecture, see the 
[Contributor Documentation](../CONTRIBUTING/README.md):

- [Architecture Overview](../CONTRIBUTING/architecture-overview.md) - System design
- [Core Components](../CONTRIBUTING/core-components.md) - Parser and controller
- [Delegates](../CONTRIBUTING/delegates.md) - JSON type parsers
- [Property Streams & Controllers](../CONTRIBUTING/property-streams-controllers.md) - Stream management
- [Mechanisms](../CONTRIBUTING/mechanisms.md) - Path system, streaming, nesting
- [Data Flow](../CONTRIBUTING/data-flow.md) - Complete examples

## Key Internal Components

### Delegates

Delegates are workers that parse specific JSON value types character-by-character:

- **MapPropertyDelegate**: Parses JSON objects `{}`
- **ListPropertyDelegate**: Parses JSON arrays `[]`
- **StringPropertyDelegate**: Parses JSON strings `""`
- **NumberPropertyDelegate**: Parses JSON numbers
- **BooleanPropertyDelegate**: Parses `true`/`false`
- **NullPropertyDelegate**: Parses `null`

### Controllers

Controllers manage the streams and completers for each property path:

- **StringPropertyStreamController**: Buffers string chunks
- **NumberPropertyStreamController**: Holds atomic number values
- **BooleanPropertyStreamController**: Holds atomic boolean values
- **NullPropertyStreamController**: Holds null values
- **MapPropertyStreamController**: Manages map snapshots
- **ListPropertyStreamController**: Manages list snapshots

### Mixins

- **PropertyGetterMixin**: Provides `getStringProperty()`, `getMapProperty()`, etc.
- **DelegatorMixin**: Factory for creating appropriate delegates based on JSON type

## Performance Optimizations

The internals use several optimizations:

1. **StringBuffer**: All string accumulation uses `StringBuffer` instead of `+=`
2. **Type checks**: Uses `is` operator instead of `runtimeType.toString()`
3. **Set lookups**: Character classification uses `Set` for O(1) lookups
4. **Single buffer**: Collections store only the latest state, not full history
