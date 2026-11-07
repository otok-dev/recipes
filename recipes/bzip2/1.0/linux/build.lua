-- libbz2 through the recipe's CMakeLists.txt: the release has only makefiles (a static library, a Linux
-- shared one, MSVC's makefile.msc), no CMake project. What it installs: libbz2.a, or libbz2.so with its links.
function build(slice, options, deps)
    otok.copy(slice.recipe .. "/CMakeLists.txt", slice.source .. "/CMakeLists.txt")
    otok.cmake{}
    local p = slice.prefix
    local lib = otok.glob(slice.linkage == "static" and "lib/libbz2.a" or "lib/libbz2.so", p)[1]
    return { libraries = { bz2 = lib }, headers = p .. "/include" }
end
