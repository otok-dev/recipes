-- The Lua library through the recipe's CMakeLists.txt, which builds what the release's src/Makefile
-- builds into liblua.a, static or as a DLL (the Makefile has no MSVC build). luaconf.h sees _WIN32.

function build(slice, options, deps)
    otok.copy(slice.recipe .. "/CMakeLists.txt", slice.source .. "/CMakeLists.txt")
    otok.cmake{ defines = { LUA_SYSTEM = "" } }
    local p = slice.prefix
    local dll = otok.glob("bin/lua.dll", p)[1]
    if dll then return { libraries = { lua = { link = p .. "/lib/lua.lib", runtime = dll } }, headers = p .. "/include" } end
    return { libraries = { lua = p .. "/lib/lua.lib" }, headers = p .. "/include" }
end
