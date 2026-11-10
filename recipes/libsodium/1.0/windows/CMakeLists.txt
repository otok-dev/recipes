# libsodium for MSVC, as its Visual Studio projects (builds/msvc/vs2026/libsodium) build it: every C file of
# src/libsodium with the same definitions, the prebuilt builds/msvc/version.h and, for the DLL, its version resource.
# SODIUM_SOURCE is the root of libsodium's sources.
cmake_minimum_required(VERSION 3.20)
project(libsodium C)

set(src "${SODIUM_SOURCE}/src/libsodium")
file(GLOB_RECURSE sources CONFIGURE_DEPENDS "${src}/*.c")
list(SORT sources)
if(BUILD_SHARED_LIBS)
    list(APPEND sources "${SODIUM_SOURCE}/builds/msvc/resource.rc")
endif()

add_library(libsodium ${sources})
# version.h first: the one of builds/msvc, written for this release, before version.h.in
target_include_directories(libsodium PRIVATE "${SODIUM_SOURCE}/builds/msvc" "${src}/include" "${src}/include/sodium")
target_compile_definitions(libsodium PRIVATE inline=__inline NATIVE_LITTLE_ENDIAN _CRT_SECURE_NO_WARNINGS
    UNICODE _UNICODE $<IF:$<BOOL:${BUILD_SHARED_LIBS}>,SODIUM_DLL_EXPORT,SODIUM_STATIC>)
if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(ARM64|arm64|aarch64)$")
    target_compile_definitions(libsodium PRIVATE ARM64)
else()
    target_compile_definitions(libsodium PRIVATE x64)
endif()
target_link_libraries(libsodium PRIVATE advapi32)

include(GNUInstallDirs)
install(TARGETS libsodium RUNTIME DESTINATION bin LIBRARY DESTINATION lib ARCHIVE DESTINATION lib)
install(FILES "${src}/include/sodium.h" DESTINATION include)
install(DIRECTORY "${src}/include/sodium/" DESTINATION include/sodium
    FILES_MATCHING PATTERN "*.h" PATTERN "private" EXCLUDE)
install(FILES "${SODIUM_SOURCE}/builds/msvc/version.h" DESTINATION include/sodium)
