# libbz2 of the otok recipe: the objects of the release's Makefile (OBJS), without the bzip2 and bzip2recover
# programs, static or shared as BUILD_SHARED_LIBS says.
cmake_minimum_required(VERSION 3.20...4.0)
project(bzip2 VERSION 1.0.8 LANGUAGES C)

add_library(bz2 blocksort.c huffman.c crctable.c randtable.c compress.c decompress.c bzlib.c)
# the soname of Makefile-libbz2_so: libbz2.so.1.0
set_target_properties(bz2 PROPERTIES VERSION ${PROJECT_VERSION} SOVERSION 1.0)
if(WIN32)
    # bzlib.h declares the API without dllexport
    set_target_properties(bz2 PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS ON)
endif()
if(MSVC)
    target_compile_definitions(bz2 PRIVATE _CRT_SECURE_NO_WARNINGS)
endif()

install(TARGETS bz2 RUNTIME DESTINATION bin LIBRARY DESTINATION lib ARCHIVE DESTINATION lib)
install(FILES bzlib.h DESTINATION include)
