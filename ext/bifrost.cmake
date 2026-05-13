include(FetchContent)

FetchContent_Declare(
    bifrost
    GIT_REPOSITORY https://github.com/efedo/bifrost.git
    GIT_TAG        master
    GIT_SHALLOW    TRUE
)

# Configure bifrost BEFORE making it available
set(MAX_KMER_SIZE "${MAX_KMER_SIZE}" CACHE STRING "Maximum k-mer size for Bifrost" FORCE)
set(MAX_GMER_SIZE "${MAX_KMER_SIZE}" CACHE STRING "Maximum g-mer size for Bifrost" FORCE)

# Set ENABLE_AVX2 based on kallisto's settings
if(ENABLE_AVX2 MATCHES "OFF")
    set(ENABLE_AVX2 "OFF" CACHE STRING "Enable AVX2 instructions" FORCE)
else()
    set(ENABLE_AVX2 "ON" CACHE STRING "Enable AVX2 instructions" FORCE)
endif()

# Set COMPILATION_ARCH based on kallisto's settings
if(COMPILATION_ARCH MATCHES "OFF")
    set(COMPILATION_ARCH "OFF" CACHE STRING "Compilation architecture" FORCE)
else()
    if(NOT COMPILATION_ARCH)
        set(COMPILATION_ARCH "native" CACHE STRING "Compilation architecture" FORCE)
    else()
        set(COMPILATION_ARCH "${COMPILATION_ARCH}" CACHE STRING "Compilation architecture" FORCE)
    endif()
endif()

# Disable Bifrost's unit tests (they require HDF5)
set(BUILD_TESTING OFF CACHE BOOL "Build Bifrost unit tests" FORCE)

# Ensure ZLIB variables are set before bifrost configuration
# Bifrost's CMakeLists.txt will call find_package(ZLIB REQUIRED)
if(NOT ZLIB_FOUND)
    message(WARNING "ZLIB not found before bifrost configuration. Bifrost may fail to configure.")
endif()

# Populate bifrost but don't add it yet - we need to patch its CMakeLists.txt
FetchContent_GetProperties(bifrost)
if(NOT bifrost_POPULATED)
    FetchContent_Populate(bifrost)
    
    # Patch Bifrost's src/CMakeLists.txt to avoid duplicate bifrost.lib output
    # The problem: both bifrost_static and bifrost_dynamic have OUTPUT_NAME "bifrost"
    # On Windows, this causes "multiple rules generate bifrost.lib" error
    # Solution: Give the dynamic library a different output name
    file(READ "${bifrost_SOURCE_DIR}/src/CMakeLists.txt" BIFROST_SRC_CMAKE)
    string(REPLACE 
        "set_target_properties(bifrost_dynamic PROPERTIES OUTPUT_NAME \"bifrost\")"
        "set_target_properties(bifrost_dynamic PROPERTIES OUTPUT_NAME \"bifrost_shared\")"
        BIFROST_SRC_CMAKE "${BIFROST_SRC_CMAKE}")
    file(WRITE "${bifrost_SOURCE_DIR}/src/CMakeLists.txt" "${BIFROST_SRC_CMAKE}")
    
    # Add the patched bifrost subdirectory, EXCLUDE_FROM_ALL hides it from parent install
    add_subdirectory(${bifrost_SOURCE_DIR} ${bifrost_BINARY_DIR} EXCLUDE_FROM_ALL)
endif()

# CMakeLists.txt - Add compiler detection
if(MSVC)
    # MSVC-specific flags
#    add_compile_options(/W3 /wd4996)
else()
    # GCC/Clang flags
#    add_compile_options(-Wno-subobject-linkage)
endif()

# Platform-specific header handling
#ifdef _WIN32
    #include <windows.h>
#else
    #include <unistd.h>
    #include <getopt.h>
#endif

