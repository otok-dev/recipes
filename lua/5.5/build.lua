-- The Lua library through the recipe's CMakeLists.txt, which builds what the release's src/Makefile
-- builds into liblua.a, static or shared, on every platform (the Makefile has no shared library and no
-- MSVC build).

-- the system's definition for luaconf.h, as the Makefile's targets set it
local function system(slice)
    if slice.platform == "macosx" then return "LUA_USE_MACOSX" end
    -- the other Apple platforms have no system(): LUA_USE_IOS replaces it with a stub
    if slice.os == "apple" then return "LUA_USE_IOS" end
    if slice.triple:find("linux") then return "LUA_USE_LINUX" end
    if slice.triple:find("apple") then return "LUA_USE_MACOSX" end
    return ""  -- Windows: luaconf.h sees _WIN32
end

function build(slice, options, deps)
    otok.copy(slice.recipe .. "/CMakeLists.txt", slice.source .. "/CMakeLists.txt")
    otok.cmake{ defines = { LUA_SYSTEM = system(slice) } }

    -- lua.hpp is for C++ only (extern "C"), so it stays out of the module
    local p = slice.prefix
    otok.write(p .. "/module.modulemap", 'module Lua {\n    header "../lua.h"\n    header "../lualib.h"\n    header "../lauxlib.h"\n    export *\n}\n')
    local result = { headers = p .. "/include", module_map = p .. "/module.modulemap" }
    local dll = otok.glob("bin/lua.dll", p)[1]
    if dll then
        result.libraries = { lua = { link = p .. "/lib/lua.lib", runtime = dll } }
    else
        result.libraries = { lua = otok.glob("lib/liblua.so", p)[1] or otok.glob("lib/liblua.dylib", p)[1] or otok.glob("lib/liblua.a", p)[1]
            or otok.glob("lib/lua.lib", p)[1] }
    end
    return result
end
