# Memory Growth Tech Notes

## Observed Risk Areas
- Repeated `.task`-driven loads on navigation could re-fetch and re-decode JSON on every appearance.
- `AllEntriesView` rendered large lists in a non-lazy `VStack`, keeping every row in memory.
- View model lifecycles were opaque, making it hard to confirm deinit and repeated loads.

## Fixes Applied
- Added a shared, cached `ThoughtRecordStore` with `loadOnce()` to read/decode entries once per app launch.
- Switched persistence to mutate the in-memory cache and debounce disk writes (no full decode/encode loop on every save).
- Added `flushPendingWrites()` and app lifecycle hooks to force pending writes on background/inactive and final save.
- Added `loadIfNeeded` guards to view models to prevent redundant loads per screen lifecycle.
- Switched `AllEntriesView` to `LazyVStack` for section and row rendering.
- Added DEBUG-only init/deinit/load logging to view models plus disk read/decode logs in the store.

## Expected Outcome
- Reduced repeated JSON decode churn and fewer concurrent tasks.
- Lower view memory footprint for large entry lists.
- Clear instrumentation to confirm view models deinit as expected.
- Disk read/decode should occur once per app launch unless explicitly refreshed.
- Pending writes should persist when backgrounding or completing a thought.

