include(FetchContent)

# Pin the Bifrost tree from the last revision where it was vendored with
# kallisto. It carries the binary-index API used by this source tree; neither
# upstream Bifrost nor the separate Windows fork has that API.
FetchContent_Declare(
    bifrost
    GIT_REPOSITORY https://github.com/efedo/kallisto.git
    GIT_TAG 53be8c92830ae0bb2940e919039d3f16d8b182f3
    GIT_SHALLOW FALSE)

set(MAX_KMER_SIZE "${MAX_KMER_SIZE}" CACHE STRING "Maximum k-mer size for Bifrost" FORCE)
set(MAX_GMER_SIZE "${MAX_KMER_SIZE}" CACHE STRING "Maximum g-mer size for Bifrost" FORCE)

if(MSVC)
    set(COMPILATION_ARCH "OFF" CACHE STRING "Compilation architecture" FORCE)
    set(ENABLE_AVX2 "OFF" CACHE STRING "Enable AVX2 instructions" FORCE)
elseif(ENABLE_AVX2)
    set(COMPILATION_ARCH "native" CACHE STRING "Compilation architecture" FORCE)
else()
    set(COMPILATION_ARCH "OFF" CACHE STRING "Compilation architecture" FORCE)
    set(ENABLE_AVX2 "OFF" CACHE STRING "Enable AVX2 instructions" FORCE)
endif()

FetchContent_GetProperties(bifrost)
if(NOT bifrost_POPULATED)
    if(POLICY CMP0169)
        cmake_policy(SET CMP0169 OLD)
    endif()
    FetchContent_Populate(bifrost)
    set(bifrost_SOURCE_DIR "${bifrost_SOURCE_DIR}/ext/bifrost")

    # The upstream CMake project unconditionally adds GCC/Clang flags and gives
    # its static and import libraries the same name on Windows.  Keep this small
    # compatibility patch local until it is accepted upstream.
    file(READ "${bifrost_SOURCE_DIR}/CMakeLists.txt" BIFROST_CMAKE)
    string(REGEX REPLACE "cmake_minimum_required\\(VERSION [0-9.]+\\)" "cmake_minimum_required(VERSION 3.20)" BIFROST_CMAKE "${BIFROST_CMAKE}")
    string(REGEX REPLACE "set\\(CMAKE_C_FLAGS [^\\n]*-std=c11[^\\n]*\\)" "" BIFROST_CMAKE "${BIFROST_CMAKE}")
    string(REGEX REPLACE "set\\(CMAKE_CXX_FLAGS [^\\n]*-std=c\\+\\+11[^\\n]*\\)" "" BIFROST_CMAKE "${BIFROST_CMAKE}")
    string(REPLACE "set_property(SOURCE BlockedBloomFilter.cpp APPEND_STRING PROPERTY COMPILE_FLAGS \" -funroll-loops\")" "" BIFROST_CMAKE "${BIFROST_CMAKE}")
    string(REPLACE "add_compile_options(-g)" "" BIFROST_CMAKE "${BIFROST_CMAKE}")
    string(REPLACE "add_compile_options(-O3)" "" BIFROST_CMAKE "${BIFROST_CMAKE}")
    string(REPLACE "add_compile_options(-pg)" "" BIFROST_CMAKE "${BIFROST_CMAKE}")
    string(REPLACE "set(CMAKE_SHARED_LINKER_FLAGS \"-pg\")" "" BIFROST_CMAKE "${BIFROST_CMAKE}")
    string(REPLACE "set(CMAKE_EXE_LINKER_FLAGS \"-pg\")" "" BIFROST_CMAKE "${BIFROST_CMAKE}")
    string(REGEX REPLACE "set\\(CMAKE_C_FLAGS [^\\n]*-mno-avx2[^\\n]*\\)" "" BIFROST_CMAKE "${BIFROST_CMAKE}")
    string(REGEX REPLACE "set\\(CMAKE_CXX_FLAGS [^\\n]*-mno-avx2[^\\n]*\\)" "" BIFROST_CMAKE "${BIFROST_CMAKE}")
    string(REPLACE "set_target_properties(bifrost_dynamic PROPERTIES OUTPUT_NAME \"bifrost\")"
                   "set_target_properties(bifrost_dynamic PROPERTIES OUTPUT_NAME \"bifrost_shared\")"
                   BIFROST_CMAKE "${BIFROST_CMAKE}")
    file(WRITE "${bifrost_SOURCE_DIR}/CMakeLists.txt" "${BIFROST_CMAKE}")

    file(READ "${bifrost_SOURCE_DIR}/src/CMakeLists.txt" BIFROST_SRC_CMAKE)
    string(REPLACE "set_target_properties(bifrost_dynamic PROPERTIES OUTPUT_NAME \"bifrost\")"
                   "set_target_properties(bifrost_dynamic PROPERTIES OUTPUT_NAME \"bifrost_shared\")"
                   BIFROST_SRC_CMAKE "${BIFROST_SRC_CMAKE}")
    string(REPLACE "list(REMOVE_ITEM sources Bifrost.cpp)"
                   "list(REMOVE_ITEM sources Bifrost.cpp)\nlist(FILTER sources EXCLUDE REGEX \"Bifrost\\.cpp$\")"
                   BIFROST_SRC_CMAKE "${BIFROST_SRC_CMAKE}")
    string(REPLACE "target_link_libraries(bifrost_static pthread)" "" BIFROST_SRC_CMAKE "${BIFROST_SRC_CMAKE}")
    string(REPLACE "target_link_libraries(bifrost_dynamic pthread)" "" BIFROST_SRC_CMAKE "${BIFROST_SRC_CMAKE}")
    string(REPLACE "target_link_libraries(bifrost_static \${ZLIB_LIBRARIES})" "" BIFROST_SRC_CMAKE "${BIFROST_SRC_CMAKE}")
    string(REPLACE "target_link_libraries(bifrost_dynamic \${ZLIB_LIBRARIES})" "" BIFROST_SRC_CMAKE "${BIFROST_SRC_CMAKE}")
    file(WRITE "${bifrost_SOURCE_DIR}/src/CMakeLists.txt" "${BIFROST_SRC_CMAKE}")

    # Bifrost 1.0.6.4 predates its later Windows allocation wrapper.
    # Supply the MSVC equivalent only for that older compatible API release.
    file(READ "${bifrost_SOURCE_DIR}/src/TinyBitmap.cpp" BIFROST_TINY_BITMAP)
    if(NOT BIFROST_TINY_BITMAP MATCHES "bitmap_posix_memalign")
        file(READ "${bifrost_SOURCE_DIR}/src/Common.hpp" BIFROST_COMMON)
        string(FIND "${BIFROST_COMMON}" "bfg_posix_memalign" BIFROST_HAS_POSIX_MEMALIGN)
        if(BIFROST_HAS_POSIX_MEMALIGN EQUAL -1)
            string(REPLACE "#include <sys/stat.h>"
                "#include <sys/stat.h>\n#ifdef _MSC_VER\n#include <cerrno>\n#include <intrin.h>\n#include <malloc.h>\ninline int bfg_posix_memalign(void** ptr, size_t alignment, size_t size) {\n    *ptr = _aligned_malloc(size, alignment);\n    return *ptr == nullptr ? ENOMEM : 0;\n}\ninline int __builtin_ffsll(unsigned long long value) { unsigned long bit; return _BitScanForward64(&bit, value) ? static_cast<int>(bit + 1) : 0; }\n#define posix_memalign bfg_posix_memalign\n#define BFG_ALIGNED_FREE(ptr) _aligned_free(ptr)\n#else\n#define BFG_ALIGNED_FREE(ptr) free(ptr)\n#endif"
                BIFROST_COMMON "${BIFROST_COMMON}")
            file(WRITE "${bifrost_SOURCE_DIR}/src/Common.hpp" "${BIFROST_COMMON}")
        endif()
        string(REPLACE "free(tiny_bmp);" "BFG_ALIGNED_FREE(tiny_bmp);" BIFROST_TINY_BITMAP "${BIFROST_TINY_BITMAP}")
        string(REPLACE "free(tiny_bmp_new);" "BFG_ALIGNED_FREE(tiny_bmp_new);" BIFROST_TINY_BITMAP "${BIFROST_TINY_BITMAP}")
        string(FIND "${BIFROST_TINY_BITMAP}" "bfg_tiny_bitmap_posix_memalign" BIFROST_HAS_TINY_BITMAP_ALLOCATOR)
        if(BIFROST_HAS_TINY_BITMAP_ALLOCATOR EQUAL -1)
            string(REPLACE "#include \"TinyBitmap.hpp\""
                "#include \"TinyBitmap.hpp\"\n#ifdef _MSC_VER\n#include <cerrno>\n#include <malloc.h>\ninline int bfg_tiny_bitmap_posix_memalign(void** ptr, size_t alignment, size_t size) { *ptr = _aligned_malloc(size, alignment); return *ptr == nullptr ? ENOMEM : 0; }\n#define posix_memalign bfg_tiny_bitmap_posix_memalign\n#define BFG_ALIGNED_FREE(ptr) _aligned_free(ptr)\n#else\n#define BFG_ALIGNED_FREE(ptr) free(ptr)\n#endif"
                BIFROST_TINY_BITMAP "${BIFROST_TINY_BITMAP}")
        endif()
        file(WRITE "${bifrost_SOURCE_DIR}/src/TinyBitmap.cpp" "${BIFROST_TINY_BITMAP}")
    endif()

    file(READ "${bifrost_SOURCE_DIR}/src/CompactedDBG.hpp" BIFROST_COMPACTED_DBG)
    string(REPLACE "#include <getopt.h>" "#include \"getopt_compat.h\"" BIFROST_COMPACTED_DBG "${BIFROST_COMPACTED_DBG}")
    file(WRITE "${bifrost_SOURCE_DIR}/src/CompactedDBG.hpp" "${BIFROST_COMPACTED_DBG}")
    file(READ "${bifrost_SOURCE_DIR}/src/KmerStream.hpp" BIFROST_KMER_STREAM)
    string(REPLACE "#include <getopt.h>" "#include \"getopt_compat.h\"" BIFROST_KMER_STREAM "${BIFROST_KMER_STREAM}")
    file(WRITE "${bifrost_SOURCE_DIR}/src/KmerStream.hpp" "${BIFROST_KMER_STREAM}")

    if(MSVC)
        file(READ "${bifrost_SOURCE_DIR}/src/BooPHF.h" BIFROST_BOOPHF)
        string(REPLACE "#include <sys/time.h>"
            "#include <chrono>\n#include <intrin.h>\n#include <windows.h>\nstruct timeval { long long tv_sec; long long tv_usec; };\ninline int gettimeofday(timeval* tv, void*) {\n    const auto now = std::chrono::system_clock::now().time_since_epoch();\n    const auto usec = std::chrono::duration_cast<std::chrono::microseconds>(now).count();\n    tv->tv_sec = usec / 1000000;\n    tv->tv_usec = usec % 1000000;\n    return 0;\n}\nstruct pthread_mutex_t {\n    CRITICAL_SECTION value;\n    pthread_mutex_t() { InitializeCriticalSection(&value); }\n    pthread_mutex_t(const pthread_mutex_t&) { InitializeCriticalSection(&value); }\n    pthread_mutex_t& operator=(const pthread_mutex_t&) { return *this; }\n    ~pthread_mutex_t() { DeleteCriticalSection(&value); }\n};\ninline int pthread_mutex_init(pthread_mutex_t*, void*) { return 0; }\ninline int pthread_mutex_destroy(pthread_mutex_t*) { return 0; }\ninline int pthread_mutex_lock(pthread_mutex_t* mutex) { EnterCriticalSection(&mutex->value); return 0; }\ninline int pthread_mutex_unlock(pthread_mutex_t* mutex) { LeaveCriticalSection(&mutex->value); return 0; }\ninline uint64_t bfg_atomic_fetch_or(uint64_t* value, uint64_t bits) { return _InterlockedOr64(reinterpret_cast<volatile long long*>(value), static_cast<long long>(bits)); }\ninline uint64_t bfg_atomic_fetch_and(uint64_t* value, uint64_t bits) { return _InterlockedAnd64(reinterpret_cast<volatile long long*>(value), static_cast<long long>(bits)); }\ninline uint64_t bfg_atomic_fetch_add(uint64_t* value, uint64_t increment) { return _InterlockedExchangeAdd64(reinterpret_cast<volatile long long*>(value), static_cast<long long>(increment)); }\ninline int bfg_atomic_fetch_add(int* value, int increment) { return _InterlockedExchangeAdd(reinterpret_cast<volatile long*>(value), increment); }\n#define __sync_fetch_and_or bfg_atomic_fetch_or\n#define __sync_fetch_and_and bfg_atomic_fetch_and\n#define __sync_fetch_and_add bfg_atomic_fetch_add"
            BIFROST_BOOPHF "${BIFROST_BOOPHF}")
        string(FIND "${BIFROST_BOOPHF}" "struct pthread_t" BIFROST_HAS_PTHREAD_WRAPPER)
        if(BIFROST_HAS_PTHREAD_WRAPPER EQUAL -1)
            string(REPLACE "#include <string.h>"
                "#include <thread>\n#include <string.h>"
                BIFROST_BOOPHF "${BIFROST_BOOPHF}")
            string(REPLACE "struct pthread_mutex_t {"
                "struct pthread_t { std::thread thread; };\ninline int pthread_create(pthread_t* thread, void*, void* (*start)(void*), void* arg) { thread->thread = std::thread([start, arg] { start(arg); }); return 0; }\ninline int pthread_join(pthread_t& thread, void**) { if (thread.thread.joinable()) thread.thread.join(); return 0; }\nstruct pthread_mutex_t {"
                BIFROST_BOOPHF "${BIFROST_BOOPHF}")
        endif()
        file(WRITE "${bifrost_SOURCE_DIR}/src/BooPHF.h" "${BIFROST_BOOPHF}")
    endif()

    # Roaring's sampling helper uses GCC's __uint128_t to obtain the high
    # half of a 64-bit multiplication. MSVC exposes the same operation as
    # _umul128.
    if(MSVC)
        file(READ "${bifrost_SOURCE_DIR}/src/roaring.c" BIFROST_ROARING)
        string(REPLACE "#include <string.h>"
            "#include <string.h>\n#include <intrin.h>"
            BIFROST_ROARING "${BIFROST_ROARING}")
        string(REPLACE
            "        __uint128_t tmp;\n        tmp = (__uint128_t)l_seed * UINT64_C(0xa3b195354a39b70d);\n        uint64_t m1 = (tmp >> 64) ^ tmp;\n        tmp = (__uint128_t)m1 * UINT64_C(0x1b03738712fad5c9);\n        uint64_t m2 = (tmp >> 64) ^ tmp;"
            "        unsigned __int64 high;\n        uint64_t low = _umul128(l_seed, UINT64_C(0xa3b195354a39b70d), &high);\n        uint64_t m1 = high ^ low;\n        low = _umul128(m1, UINT64_C(0x1b03738712fad5c9), &high);\n        uint64_t m2 = high ^ low;"
            BIFROST_ROARING "${BIFROST_ROARING}")
        file(WRITE "${bifrost_SOURCE_DIR}/src/roaring.c" "${BIFROST_ROARING}")
    endif()

    add_subdirectory("${bifrost_SOURCE_DIR}" "${bifrost_BINARY_DIR}" EXCLUDE_FROM_ALL)

    target_include_directories(bifrost_static PUBLIC "${PROJECT_SOURCE_DIR}/src")
    target_include_directories(bifrost_dynamic PUBLIC "${PROJECT_SOURCE_DIR}/src")
    set_property(TARGET bifrost_static bifrost_dynamic PROPERTY CXX_STANDARD 14)

    if(WIN32)
        target_link_libraries(bifrost_static Psapi)
        target_link_libraries(bifrost_dynamic Psapi)
    endif()
endif()
