-- libbz2 through the recipe's CMakeLists.txt: the release has only makefiles (a static library, a Linux
-- shared one, MSVC's makefile.msc), no CMake project.
function build(slice, options, deps)
    otok.copy(slice.recipe .. "/CMakeLists.txt", slice.source .. "/CMakeLists.txt")
    otok.cmake{}
    local p = slice.prefix
    return { libraries = { bz2 = p .. "/lib/libbz2.a" }, headers = p .. "/include" }
end
