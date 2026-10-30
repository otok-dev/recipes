# The superproject's CMakeLists.txt, which the release archive leaves out (tools/cmake/README.md). The recipe builds
# Boost with CMake for the windows target, from the release's own tools/cmake and the CMakeLists.txt of each library.
cmake_minimum_required(VERSION 3.16...3.31)
project(Boost VERSION 1.92.0 LANGUAGES CXX)
set(BOOST_SUPERPROJECT_VERSION ${PROJECT_VERSION})
set(BOOST_SUPERPROJECT_SOURCE_DIR ${PROJECT_SOURCE_DIR})
list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/tools/cmake/include)
# the headers of boost/ in the root (CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES), for the checks of the libraries too
list(APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES CMAKE_C_STANDARD_INCLUDE_DIRECTORIES CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES)
include(BoostRoot)

# What b2 builds and Boost's CMake leaves to the headers, so that the products are those of every target (b2 builds
# exception for the libraries that depend on it, cobalt, contract and others, whichever are selected):
# libboost_exception, static as b2 makes it, and boost_regex, its POSIX API (regcomp and the like).
add_library(otok_boost_exception STATIC libs/exception/src/clone_current_exception_non_intrusive.cpp)
set_target_properties(otok_boost_exception PROPERTIES OUTPUT_NAME libboost_exception PREFIX "")
add_library(otok_boost_regex libs/regex/src/posix_api.cpp libs/regex/src/wide_posix_api.cpp)
if(BUILD_SHARED_LIBS)
  set_target_properties(otok_boost_regex PROPERTIES OUTPUT_NAME boost_regex)
  target_compile_definitions(otok_boost_regex PRIVATE BOOST_REGEX_DYN_LINK=1)
else()
  set_target_properties(otok_boost_regex PROPERTIES OUTPUT_NAME libboost_regex PREFIX "")
endif()

# Boost.Context for x86_64 with BOOST_CONTEXT_ASSEMBLER gas: GNU syntax in .asm files (MinGW's), which clang-cl does not
# take for assembly; the same in clang's .S (make_x86_64_ms_pe_clang_gas.S)
if(TARGET boost_context)
  get_target_property(otok_context_sources boost_context SOURCES)
  set(otok_context_clang "")
  foreach(source IN LISTS otok_context_sources)
    if(source MATCHES "_x86_64_ms_pe_gas\.asm$")
      string(REGEX REPLACE "_gas\.asm$" "_clang_gas.S" source "${PROJECT_SOURCE_DIR}/libs/context/${source}")
    endif()
    list(APPEND otok_context_clang "${source}")
  endforeach()
  set_property(TARGET boost_context PROPERTY SOURCES ${otok_context_clang})
endif()
