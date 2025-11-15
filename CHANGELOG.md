## [0.1.1] - 2024-06-20
- Minor documentation updates

## 0.1.0

- **Initial release** 🚀
- Streaming JSON parser optimized for LLM responses
- Path-based property subscriptions with chainable API
- Support for all JSON types: String, Number, Boolean, Null, Map, List
- Array index access and dynamic element callbacks
- Handles leading whitespace before root JSON elements
- Comprehensive error handling and edge case coverage
- **Total: 160 tests passing** ✅

### Features

- **Reactive property access**: Subscribe to JSON properties as they complete in the stream
- **Nested structures**: Full support for deeply nested objects and arrays
- **Chainable API**: Access nested properties with fluent syntax
- **Type safety**: Typed property streams for all JSON types
- **Memory safe**: Proper stream lifecycle management and closed stream guards

### Fixed Issues

- ✅ Root maps completing properly
- ✅ Nested maps completing correctly
- ✅ List chainable property access working
- ✅ "Cannot add event after closing" errors resolved
- ✅ Proper delimiter handling between primitives and containers
- ✅ Child delegate completion detection
