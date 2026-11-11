# The SQLite library of the otok recipe: the amalgamation's sqlite3.c, static or shared as BUILD_SHARED_LIBS says, without the
# shell. SQLITE_DEFINES is the list of the compile definitions the recipe's options choose.
cmake_minimum_required(VERSION 3.20)
project(sqlite VERSION 3.54.1 LANGUAGES C)

set(SQLITE_DEFINES "" CACHE STRING "Compile definitions of the library")

add_library(sqlite3 sqlite3.c)
target_compile_definitions(sqlite3 PRIVATE ${SQLITE_DEFINES})
if(WIN32 AND BUILD_SHARED_LIBS)
    # sqlite3.h declares the API without __declspec: the DLL exports it
    target_compile_definitions(sqlite3 PRIVATE "SQLITE_API=__declspec(dllexport)")
endif()
if(UNIX)
    find_library(SQLITE_MATH_LIBRARY m)
    find_package(Threads REQUIRED)
    target_link_libraries(sqlite3 PRIVATE ${SQLITE_MATH_LIBRARY} Threads::Threads ${CMAKE_DL_LIBS})
endif()
set_target_properties(sqlite3 PROPERTIES VERSION 3.54.1 SOVERSION 0)

install(TARGETS sqlite3 RUNTIME DESTINATION bin LIBRARY DESTINATION lib ARCHIVE DESTINATION lib)
install(FILES sqlite3.h sqlite3ext.h DESTINATION include)
