include(FetchContent)

FetchContent_Declare(
    zlib-ng
    GIT_REPOSITORY https://github.com/zlib-ng/zlib-ng
    GIT_TAG        2.3.1
    GIT_SHALLOW    TRUE
)

set(ZLIB_COMPAT ON CACHE BOOL "Zlib compatibility mode on" FORCE)
set(ZLIB_ENABLE_TESTS OFF CACHE BOOL "Skip zlib-ng tests" FORCE)
set(ZLIB_ENABLE_EXAMPLES OFF CACHE BOOL "Skip zlib-ng examples" FORCE)
set(SKIP_INSTALL_ALL ON CACHE BOOL "Skip zlib-ng install" FORCE)

# Populate zlib-ng and add with EXCLUDE_FROM_ALL to hide from parent install
FetchContent_GetProperties(zlib-ng)
if(NOT zlib-ng_POPULATED)
    FetchContent_Populate(zlib-ng)
    add_subdirectory(${zlib-ng_SOURCE_DIR} ${zlib-ng_BINARY_DIR} EXCLUDE_FROM_ALL)
endif()

# Set variables that FindZLIB.cmake expects (zlib-ng in compat mode provides these)
if(TARGET zlib)
    # Ensure zlib target is built (not excluded) but not installed
    #set_target_properties(zlib PROPERTIES EXCLUDE_FROM_ALL FALSE)
    
    set(ZLIB_FOUND TRUE CACHE BOOL "ZLIB found" FORCE)
    set(ZLIB_LIBRARY zlib CACHE STRING "ZLIB library" FORCE)
    set(ZLIB_LIBRARIES zlib CACHE STRING "ZLIB libraries" FORCE)
    set(ZLIB_INCLUDE_DIR "${zlib-ng_SOURCE_DIR};${zlib-ng_BINARY_DIR}" CACHE STRING "ZLIB include directories" FORCE)
    set(ZLIB_INCLUDE_DIRS "${zlib-ng_SOURCE_DIR};${zlib-ng_BINARY_DIR}" CACHE STRING "ZLIB include directories" FORCE)
endif()
if(TARGET zlibstatic)
    #set_target_properties(zlibstatic PROPERTIES EXCLUDE_FROM_ALL FALSE)
endif()