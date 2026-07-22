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
    if(POLICY CMP0169)
        cmake_policy(SET CMP0169 OLD)
    endif()
    FetchContent_Populate(zlib-ng)
    add_subdirectory(${zlib-ng_SOURCE_DIR} ${zlib-ng_BINARY_DIR} EXCLUDE_FROM_ALL)
endif()

# Set variables that FindZLIB.cmake expects (zlib-ng in compat mode provides these)
if(TARGET zlib-ng)
    # Ensure zlib target is built (not excluded) but not installed
    #set_target_properties(zlib PROPERTIES EXCLUDE_FROM_ALL FALSE)
    
    set(ZLIB_FOUND TRUE CACHE BOOL "ZLIB found" FORCE)
    set(KALLISTO_ZLIB_TARGET zlib-ng CACHE INTERNAL "kallisto zlib target" FORCE)
    set(ZLIB_LIBRARY ${KALLISTO_ZLIB_TARGET} CACHE STRING "ZLIB library" FORCE)
    set(ZLIB_LIBRARIES ${KALLISTO_ZLIB_TARGET} CACHE STRING "ZLIB libraries" FORCE)
    set(ZLIB_INCLUDE_DIR "${zlib-ng_SOURCE_DIR};${zlib-ng_BINARY_DIR}" CACHE STRING "ZLIB include directories" FORCE)
    set(ZLIB_INCLUDE_DIRS "${zlib-ng_SOURCE_DIR};${zlib-ng_BINARY_DIR}" CACHE STRING "ZLIB include directories" FORCE)
endif()
if(TARGET zlibstatic)
    #set_target_properties(zlibstatic PROPERTIES EXCLUDE_FROM_ALL FALSE)
endif()
if(NOT DEFINED KALLISTO_ZLIB_TARGET AND TARGET zlib)
    set(KALLISTO_ZLIB_TARGET zlib CACHE INTERNAL "kallisto zlib target" FORCE)
endif()
