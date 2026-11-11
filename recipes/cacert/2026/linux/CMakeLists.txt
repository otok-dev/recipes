# libcacert of the otok recipe: cacert.c, which build.lua writes, with the bundle in it or without, static or shared as
# BUILD_SHARED_LIBS says.
cmake_minimum_required(VERSION 3.20...4.0)
project(cacert VERSION 1.0.0 LANGUAGES C)

add_library(cacert cacert.c)
target_include_directories(cacert PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
set_target_properties(cacert PROPERTIES VERSION ${PROJECT_VERSION} SOVERSION 1)
if(WIN32)
    # the two functions of otok_cacert.h are declared without dllexport
    set_target_properties(cacert PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS ON)
endif()

install(TARGETS cacert RUNTIME DESTINATION bin LIBRARY DESTINATION lib ARCHIVE DESTINATION lib)
install(FILES otok_cacert.h DESTINATION include)
