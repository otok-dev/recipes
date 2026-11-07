-- libbz2 through the recipe's CMakeLists.txt: the release has only makefiles (a static library, a Linux
-- shared one, MSVC's makefile.msc), no CMake project. What it installs: bz2.lib, or bz2.lib with bz2.dll.
function build(slice, options, deps)
    otok.copy(slice.recipe .. "/CMakeLists.txt", slice.source .. "/CMakeLists.txt")
    otok.cmake{}
    local p = slice.prefix
    local dll = otok.glob("bin/bz2.dll", p)[1]
    if dll then return { libraries = { bz2 = { link = p .. "/lib/bz2.lib", runtime = dll } }, headers = p .. "/include" } end
    return { libraries = { bz2 = p .. "/lib/bz2.lib" }, headers = p .. "/include" }
end
