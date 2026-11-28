-- giflib through the recipe's CMakeLists.txt, libgif only. What it installs: libgif.a, or libgif.so with its links.
function build(slice, options, deps)
    otok.copy(slice.recipe .. "/CMakeLists.txt", slice.source .. "/CMakeLists.txt")
    otok.cmake{}
    local p = slice.prefix
    local static = slice.linkage == "static"
    return { libraries = { gif = otok.glob(static and "lib/libgif.a" or "lib/libgif.so", p)[1] }, headers = p .. "/include" }
end
