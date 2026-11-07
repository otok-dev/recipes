# The Lua library of the otok recipe: the core and the standard libraries of the release's src/Makefile
# (CORE_O and LIB_O), without the lua and luac programs, static or shared as BUILD_SHARED_LIBS says.
cmake_minimum_required(VERSION 3.20)
project(lua VERSION 5.5.1 LANGUAGES C)

# LUA_USE_LINUX, LUA_USE_MACOSX, LUA_USE_IOS, as the Makefile's targets set them; empty on Windows, where
# luaconf.h sees _WIN32
set(LUA_SYSTEM "" CACHE STRING "The target system's definition for luaconf.h")

set(core lapi lcode lctype ldebug ldo ldump lfunc lgc llex lmem lobject lopcodes lparser lstate lstring ltable ltm lundump lvm lzio)
set(libs lauxlib lbaselib lcorolib ldblib liolib lmathlib loadlib loslib lstrlib ltablib lutf8lib linit)
set(sources "")
foreach(name IN LISTS core libs)
    list(APPEND sources src/${name}.c)
endforeach()

add_library(lua ${sources})
if(LUA_SYSTEM)
    target_compile_definitions(lua PRIVATE ${LUA_SYSTEM})
endif()
if(WIN32 AND BUILD_SHARED_LIBS)
    # luaconf.h exports the API from the DLL
    target_compile_definitions(lua PRIVATE LUA_BUILD_AS_DLL)
endif()
if(UNIX)
    target_link_libraries(lua PRIVATE m ${CMAKE_DL_LIBS})
endif()
set_target_properties(lua PROPERTIES VERSION ${PROJECT_VERSION} SOVERSION ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR})

install(TARGETS lua RUNTIME DESTINATION bin LIBRARY DESTINATION lib ARCHIVE DESTINATION lib)
install(FILES src/lua.h src/luaconf.h src/lualib.h src/lauxlib.h src/lua.hpp DESTINATION include)
