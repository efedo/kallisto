include(FetchContent)

FetchContent_Declare(
    zlib
    GIT_REPOSITORY https://github.com/madler/zlib.git
    GIT_TAG        v1.3.1
    GIT_SHALLOW    TRUE
)

# Configure zlib BEFORE making it available - skip all installs
set(SKIP_INSTALL_ALL ON CACHE BOOL "Skip zlib install" FORCE)
set(SKIP_INSTALL_LIBRARIES ON CACHE BOOL "Skip zlib library install" FORCE)
set(SKIP_INSTALL_HEADERS ON CACHE BOOL "Skip zlib header install" FORCE)
set(SKIP_INSTALL_FILES ON CACHE BOOL "Skip zlib file install" FORCE)

# Populate zlib and add with EXCLUDE_FROM_ALL to hide from parent install
FetchContent_GetProperties(zlib)
if(NOT zlib_POPULATED)
    FetchContent_Populate(zlib)
    add_subdirectory(${zlib_SOURCE_DIR} ${zlib_BINARY_DIR} EXCLUDE_FROM_ALL)
endif()

# Ensure zlibstatic is built but not installed
if(TARGET zlibstatic)
    set_target_properties(zlibstatic PROPERTIES 
        EXCLUDE_FROM_ALL FALSE
        POSITION_INDEPENDENT_CODE ON
    )
endif()
# Hide shared zlib from build
if(TARGET zlib)
    set_target_properties(zlib PROPERTIES EXCLUDE_FROM_ALL)
endif()

# Set variables for FindZLIB.cmake compatibility and parent scope
set(ZLIB_FOUND TRUE CACHE BOOL "ZLIB found" FORCE)
set(ZLIB_LIBRARY zlibstatic CACHE STRING "ZLIB library" FORCE)
set(ZLIB_LIBRARIES zlibstatic CACHE STRING "ZLIB libraries" FORCE)
set(ZLIB_INCLUDE_DIR "${zlib_SOURCE_DIR};${zlib_BINARY_DIR}" CACHE STRING "ZLIB include directories" FORCE)
set(ZLIB_INCLUDE_DIRS "${ZLIB_INCLUDE_DIR}" CACHE STRING "ZLIB include directories" FORCE)