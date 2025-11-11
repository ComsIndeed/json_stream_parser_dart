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
    - Got the string delegates to work again, still working on booleans
    - Got booleans working
    - Found an issue that if booleans went first in a map it would break
      - Fixed that issue
      - Got null values working, used AI since logic is similar to booleans
      - Got numbers working too, and used AI since logic is similar to strings
      - trying to get nested maps working now
- Got nested maps working, surprisingly it was already working, just needed one
  tweak that the AI spotted.
  - Strings now work again
  - Got to work on lists now
  - want to ask Gemini if this move of making AI do the work is a good idea
  - tried to let Copilot do the list delegate but its failing right now
  - Found bugs in map nesting, where nesteds dont seem to work again
  - Found issues with type casting in main parser on the addPropertyChunk
    method:
    > `type 'MapPropertyStreamController' is not a subtype of type 'PropertyStreamController<String>' in type cast`
  - Completely forgot about why I had this issue above this line, moved onto other stuff for now
  - Added onElement callback on public API for ListPropertyStream'
  - ISSUE: 
    - We need a way to check values if they are done
    - But, the ending quotes will signal to wait for comma while the comma as delimiters for numbers will signal to wait for value (or the ending bracket signalling completion)
    - This makes us have to handle the same thing twice
    - The two issues:
      ```

        |"Testing",|
                 ^ this is the delimiter, await for comma

        |09123123,|
                 ^ this is the delimiter, await for value

        solution: let the delegates determine if they're done and then let the parent delegate determine if its time to shine? 

        whats the solution here

      ```
    - IDEAS:
      - Do the thing Claude did where we let them pass? How tho
      - Constantly check for completion. If its already completed, check the current character if it is a comma or end to determine next 

## Architecture

- PropertyStreams are whats exposed to the user
- PropertyStreamControllers are what creates PropertyStreams and is for
  controlling the stream
- PropertyDelegates are the ones doing the parsing work
- JsonStreamParser provides all the delegates the methods; holds the records
