include(FetchContent)

# Prefer a system HDF5 package, but make a native build self-contained when it
# is unavailable (the normal case on a fresh Windows developer machine).
find_package(HDF5 QUIET COMPONENTS C)

add_library(kallisto_hdf5 INTERFACE)
if(HDF5_FOUND)
    target_include_directories(kallisto_hdf5 INTERFACE ${HDF5_INCLUDE_DIRS})
    target_link_libraries(kallisto_hdf5 INTERFACE ${HDF5_LIBRARIES})
else()
    set(HDF5_BUILD_CPP_LIB OFF CACHE BOOL "Do not build the HDF5 C++ API" FORCE)
    set(HDF5_BUILD_FORTRAN OFF CACHE BOOL "Do not build Fortran bindings" FORCE)
    set(HDF5_BUILD_EXAMPLES OFF CACHE BOOL "Do not build HDF5 examples" FORCE)
    set(HDF5_BUILD_TOOLS OFF CACHE BOOL "Do not build HDF5 command-line tools" FORCE)
    set(HDF5_BUILD_UTILS OFF CACHE BOOL "Do not build HDF5 utilities" FORCE)
    set(HDF5_BUILD_TESTING OFF CACHE BOOL "Do not build HDF5 tests" FORCE)
    set(HDF5_ENABLE_Z_LIB_SUPPORT ON CACHE BOOL "Enable compressed kallisto output" FORCE)
    set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build static third-party libraries" FORCE)

    FetchContent_Declare(
        hdf5
        GIT_REPOSITORY https://github.com/HDFGroup/hdf5.git
        GIT_TAG hdf5_1.14.6
        GIT_SHALLOW TRUE)
    FetchContent_MakeAvailable(hdf5)

    if(TARGET hdf5-static)
        target_link_libraries(kallisto_hdf5 INTERFACE hdf5-static)
        set(KALLISTO_HDF5_TARGET hdf5-static)
    elseif(TARGET hdf5)
        target_link_libraries(kallisto_hdf5 INTERFACE hdf5)
    else()
        message(FATAL_ERROR "Fetched HDF5 but no C library target was created.")
    endif()
endif()

# FindHDF5 accepts a library filename, whereas zlib-ng exports a CMake target.
# Replace the unresolved legacy `zlib` item left by HDF5's discovery step with
# the target supplied by our dependency graph.
if(DEFINED KALLISTO_HDF5_TARGET AND DEFINED KALLISTO_ZLIB_TARGET)
    foreach(property LINK_LIBRARIES INTERFACE_LINK_LIBRARIES)
        get_target_property(HDF5_LINK_ITEMS ${KALLISTO_HDF5_TARGET} ${property})
        if(HDF5_LINK_ITEMS)
            list(REMOVE_ITEM HDF5_LINK_ITEMS zlib zlib-ng zlibstatic)
            list(APPEND HDF5_LINK_ITEMS "$<TARGET_FILE:${KALLISTO_ZLIB_TARGET}>")
            set_property(TARGET ${KALLISTO_HDF5_TARGET} PROPERTY ${property} "${HDF5_LINK_ITEMS}")
        endif()
    endforeach()
    if(MSVC)
        set_property(TARGET ${KALLISTO_HDF5_TARGET} PROPERTY INTERFACE_LINK_LIBRARIES
            "$<TARGET_FILE:${KALLISTO_ZLIB_TARGET}>;shlwapi")
    endif()
endif()
