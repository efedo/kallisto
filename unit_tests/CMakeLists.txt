file(GLOB sources CONFIGURE_DEPENDS *.cpp)

add_executable(tests ${sources})
add_test(NAME unittest COMMAND tests)
target_link_libraries(tests PRIVATE kallisto_core ${KALLISTO_ZLIB_TARGET})
