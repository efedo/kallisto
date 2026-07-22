file(GLOB sources CONFIGURE_DEPENDS *.cpp)
file(GLOB headers CONFIGURE_DEPENDS *.h *.hpp)

list(REMOVE_ITEM sources ${CMAKE_CURRENT_SOURCE_DIR}/main.cpp)

add_library(kallisto_core ${sources} ${headers})
target_include_directories(kallisto_core PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

add_executable(kallisto main.cpp)

find_package(Threads REQUIRED)
target_link_libraries(kallisto_core PUBLIC Threads::Threads bifrost_static ${KALLISTO_ZLIB_TARGET})
target_link_libraries(kallisto PRIVATE kallisto_core)

target_link_libraries(kallisto_core PUBLIC kallisto_hdf5)

install(TARGETS kallisto RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
