# The GIF library of the otok recipe: libgif of the release's Makefile (SOURCES), without the programs and without libutil,
# static or shared as BUILD_SHARED_LIBS says. The release has no CMake and no MSVC build.
cmake_minimum_required(VERSION 3.20)
project(giflib VERSION 5.2.2 LANGUAGES C)

add_library(gif dgif_lib.c egif_lib.c gifalloc.c gif_err.c gif_font.c gif_hash.c openbsd-reallocarray.c)
if(WIN32)
    # gif_font.c calls POSIX strtok_r; the CRT has strtok_s
    target_compile_definitions(gif PRIVATE strtok_r=strtok_s)
endif()
if(WIN32 AND BUILD_SHARED_LIBS)
    # the headers declare the functions without __declspec: a DLL exports them all
    set_target_properties(gif PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS ON)
endif()
set_target_properties(gif PROPERTIES VERSION 7.2.0 SOVERSION 7)

install(TARGETS gif RUNTIME DESTINATION bin LIBRARY DESTINATION lib ARCHIVE DESTINATION lib)
install(FILES gif_lib.h DESTINATION include)
