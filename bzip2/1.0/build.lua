-- libbz2 through the recipe's CMakeLists.txt: the release has only makefiles (a static library, a Linux
-- shared one, MSVC's makefile.msc), no CMake project.
function build(slice, options, deps)
    otok.copy(slice.recipe .. "/CMakeLists.txt", slice.source .. "/CMakeLists.txt")
    otok.cmake{}
    local p = slice.prefix
    local dll = otok.glob("bin/bz2.dll", p)[1]
    if dll then
        return { libraries = { bz2 = { link = p .. "/lib/bz2.lib", runtime = dll } }, headers = p .. "/include" }
    end
    local lib = otok.glob("lib/libbz2.so", p)[1] or otok.glob("lib/libbz2.dylib", p)[1] or otok.glob("lib/libbz2.a", p)[1]
        or otok.glob("lib/bz2.lib", p)[1]
    return { libraries = { bz2 = lib }, headers = p .. "/include" }
end
