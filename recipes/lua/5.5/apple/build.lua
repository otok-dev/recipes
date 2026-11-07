-- The Lua library through the recipe's CMakeLists.txt, which builds what the release's src/Makefile
-- builds into liblua.a.

function build(slice, options, deps)
    otok.copy(slice.recipe .. "/CMakeLists.txt", slice.source .. "/CMakeLists.txt")
    -- the system's definition for luaconf.h, as the Makefile's targets set it; the other Apple platforms have no
    -- system(): LUA_USE_IOS replaces it with a stub
    otok.cmake{ defines = { LUA_SYSTEM = slice.platform == "macosx" and "LUA_USE_MACOSX" or "LUA_USE_IOS" } }

    -- lua.hpp is for C++ only (extern "C"), so it stays out of the module
    local p = slice.prefix
    otok.write(p .. "/module.modulemap", 'module Lua {\n    header "../lua.h"\n    header "../lualib.h"\n    header "../lauxlib.h"\n    export *\n}\n')
    return { libraries = { lua = p .. "/lib/liblua.a" }, headers = p .. "/include", module_map = p .. "/module.modulemap" }
end
