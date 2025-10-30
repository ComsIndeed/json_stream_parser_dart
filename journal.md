10/27/2025 00:54

- Fixed two-way dependency of propertystream and controllers
- Added seperate method property getters
- Working on making the API adhere to the test interface to continue
- Currently handling type casting for controller and propertystream futures and
  controllers and whatever

10/30/2025 23:59

- Trying to get the simple string property test to pass
- Added the addPropertyChunk method
- Figuring out why theres nothing outputting when running the stream
  - Checking the emitters in json stream parser
  - It was indeed the emitter in json stream parser
  - Got it Fixed
- Figuring out why theres no output for boolean objects
  - The delegate is being created yes
  - The first character is now being fed yes, but still not working
  - The string property seems to work for some reason but the booleans aren't?

## Architecture

- PropertyStreams are whats exposed to the user
- PropertyStreamControllers are what creates PropertyStreams and is for
  controlling the stream
- PropertyDelegates are the ones doing the parsing work
- JsonStreamParser provides all the delegates the methods; holds the records
