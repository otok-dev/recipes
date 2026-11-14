# libtomlplusplus of the otok recipe: src/toml.cpp compiled as the library, as toml++'s meson.build does with
# build_lib (its CMake project is header-only), static or shared as BUILD_SHARED_LIBS says.
cmake_minimum_required(VERSION 3.20...4.0)
project(tomlplusplus VERSION 3.4.0 LANGUAGES CXX)

add_library(tomlplusplus src/toml.cpp)
target_include_directories(tomlplusplus PRIVATE include)
target_compile_definitions(tomlplusplus PRIVATE TOML_HEADER_ONLY=0)
if(BUILD_SHARED_LIBS)
    # TOML_SHARED_LIB: dllexport on Windows, default visibility of the exported classes and functions elsewhere
    target_compile_definitions(tomlplusplus PRIVATE TOML_SHARED_LIB=1)
    set_target_properties(tomlplusplus PROPERTIES CXX_VISIBILITY_PRESET hidden VISIBILITY_INLINES_HIDDEN ON)
endif()
# the soname of meson's build: libtomlplusplus.so.3
set_target_properties(tomlplusplus PROPERTIES VERSION ${PROJECT_VERSION} SOVERSION 3)

install(TARGETS tomlplusplus RUNTIME DESTINATION bin LIBRARY DESTINATION lib ARCHIVE DESTINATION lib)
install(DIRECTORY include/toml++ DESTINATION include)
