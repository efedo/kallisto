# Bifrost FetchContent Integration Changes

## Summary
Successfully replaced the nested copy of Bifrost with a FetchContent-based approach and fixed ZLIB variable propagation issues.

## Changes Made

### 1. Created `ext/bifrost.cmake`
- Uses `FetchContent_Declare` to fetch Bifrost from https://github.com/pmelsted/bifrost.git
- Configures Bifrost build parameters before making it available
- Includes a warning check to ensure ZLIB is configured before Bifrost

### 2. Updated `ext/zlib.cmake`
- **Added PARENT_SCOPE exports** for all ZLIB variables:
  - `ZLIB_FOUND`
  - `ZLIB_LIBRARY` 
  - `ZLIB_LIBRARIES`
  - `ZLIB_INCLUDE_DIR`
  - `ZLIB_INCLUDE_DIRS`
- These exports ensure that when Bifrost's CMakeLists.txt calls `find_package(ZLIB REQUIRED)`, the variables are already populated

### 3. Updated `ext/zlib-ng.cmake`
- **Added PARENT_SCOPE exports** for all ZLIB variables (same as zlib.cmake)
- Added target check `if(TARGET zlib)` to ensure zlib-ng is properly configured
- Created `ZLIB::ZLIB` alias for compatibility with find_package

### 4. Updated `CMakeLists.txt`
- Removed `add_subdirectory(ext/bifrost)` 
- Removed duplicate Bifrost configuration code
- Added `include(${PROJECT_SOURCE_DIR}/ext/bifrost.cmake)` to use FetchContent

## Why These Changes Were Needed

### The Problem
When Bifrost's `src/CMakeLists.txt` calls `find_package(ZLIB REQUIRED)`, CMake's FindZLIB module looks for these variables:
- `ZLIB_LIBRARY`
- `ZLIB_INCLUDE_DIR`

However, when using `include()` to load zlib.cmake, variables set with only `CACHE` aren't automatically visible in the subdirectory scope that FetchContent creates for Bifrost.

### The Solution
By adding `set(...PARENT_SCOPE)` calls, we ensure the ZLIB variables are propagated to:
1. The parent scope (kallisto's main CMakeLists.txt)
2. All subdirectories created by FetchContent
3. Bifrost's build system when it runs find_package(ZLIB)

## How It Works

### Execution Order
1. `CMakeLists.txt` includes either `zlib.cmake` or `zlib-ng.cmake`
2. ZLIB is fetched and built via FetchContent
3. ZLIB variables are set in both CACHE and PARENT_SCOPE
4. `CMakeLists.txt` includes `bifrost.cmake`
5. Bifrost is fetched via FetchContent
6. Bifrost's CMakeLists.txt calls `find_package(ZLIB REQUIRED)`
7. FindZLIB finds the already-populated ZLIB variables
8. Build succeeds!

### Variable Scoping
```
kallisto (main CMakeLists.txt)
??? zlib.cmake (include) 
?   ??? Sets ZLIB_* in PARENT_SCOPE ? visible to kallisto scope
??? bifrost.cmake (include)
?   ??? FetchContent creates subdirectory
?       ??? Bifrost's CMakeLists.txt
?           ??? find_package(ZLIB) ? finds ZLIB_* from parent scope
??? src (add_subdirectory)
    ??? Can also use ZLIB_* variables
```

## Testing
You can verify the changes work by:
1. Deleting the build directory
2. Running CMake configuration
3. Checking that Bifrost configures without "Could NOT find ZLIB" errors

## Benefits
1. **Cleaner repository**: No nested Bifrost copy to maintain
2. **Easier updates**: Change `GIT_TAG` in bifrost.cmake to update version
3. **Consistency**: Matches the pattern used for other dependencies
4. **Proper scoping**: ZLIB variables correctly propagate to all subdirectories

## Notes
- The existing `.gitignore` already handles FetchContent directories
- You can safely delete the entire `ext/bifrost` directory from version control
- The `master` branch is used for Bifrost to get the latest compatible version
