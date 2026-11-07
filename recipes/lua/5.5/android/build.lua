-- The Lua library through the recipe's CMakeLists.txt, which builds what the release's src/Makefile
-- builds into liblua.a, static or shared (the Makefile has no shared library).

function build(slice, options, deps)
    otok.copy(slice.recipe .. "/CMakeLists.txt", slice.source .. "/CMakeLists.txt")
    -- POSIX and dlopen, which Bionic has, as on Linux
    otok.cmake{ defines = { LUA_SYSTEM = "LUA_USE_LINUX" } }
    local p = slice.prefix
    local lib = otok.glob(slice.linkage == "static" and "lib/liblua.a" or "lib/liblua.so", p)[1]
    return { libraries = { lua = lib }, headers = p .. "/include" }
end
