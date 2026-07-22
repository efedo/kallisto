cmake_minimum_required(VERSION 3.20)

project(kallisto LANGUAGES C CXX)

include(GNUInstallDirs)
include(FetchContent)
option(BUILD_TESTING "Build unit tests" OFF)
include(CTest)

set(MAX_KMER_SIZE "32" CACHE STRING "Maximum k-mer size")
option(ENABLE_AVX2 "Enable AVX2 instructions in Bifrost" ON)
option(USE_BAM "Compile BAM support through HTSlib" OFF)
option(USE_HDF5 "Compile HDF5 output support (required by this source tree)" ON)
option(ZLIBNG "Use zlib-ng in zlib compatibility mode" ON)
option(BUILD_FUNCTESTING "Build functional tests" OFF)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(MSVC)
    add_compile_definitions(NOMINMAX WIN32_LEAN_AND_MEAN)
    add_compile_options(/wd4244 /wd4996)
else()
    add_compile_options(-Wno-deprecated-declarations -Wno-subobject-linkage)
endif()

add_compile_definitions(MAX_KMER_SIZE=${MAX_KMER_SIZE})

if(USE_BAM)
    if(WIN32)
        message(FATAL_ERROR "USE_BAM is not supported by the vendored HTSlib on native Windows. Configure with -DUSE_BAM=OFF.")
    endif()
    message(FATAL_ERROR "USE_BAM has no maintained CMake build in this source tree. Configure with -DUSE_BAM=OFF.")
else()
    add_compile_definitions(NO_HTSLIB=ON)
endif()

if(ZLIBNG)
    include(${PROJECT_SOURCE_DIR}/ext/zlib-ng.cmake)
else()
    include(${PROJECT_SOURCE_DIR}/ext/zlib.cmake)
endif()

if(NOT USE_HDF5)
    message(FATAL_ERROR "HDF5 output is required by kallisto's compiled sources; configure with -DUSE_HDF5=ON.")
endif()
include(${PROJECT_SOURCE_DIR}/ext/hdf5.cmake)
add_compile_definitions(USE_HDF5=ON)

include(${PROJECT_SOURCE_DIR}/ext/bifrost.cmake)

add_subdirectory(src)

if(BUILD_TESTING)
    add_subdirectory(${PROJECT_SOURCE_DIR}/ext/catch)
    add_subdirectory(unit_tests)
endif()

if(BUILD_FUNCTESTING)
    if(WIN32)
        message(FATAL_ERROR "The functional test runner requires Bash; run it through WSL or disable BUILD_FUNCTESTING.")
    endif()
    add_subdirectory(func_tests)
    add_custom_target(functional-tests
        COMMAND /bin/bash ${PROJECT_SOURCE_DIR}/func_tests/runtests.sh
        DEPENDS kallisto
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR})
endif()
