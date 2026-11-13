-- The detours library through the recipe's CMakeLists.txt, which compiles what src/Makefile puts into detours.lib.

function build(slice, options, deps)
    otok.copy(slice.recipe .. "/CMakeLists.txt", slice.source .. "/CMakeLists.txt")
    otok.cmake{}
    local p = slice.prefix
    return { libraries = { detours = p .. "/lib/detours.lib" }, headers = p .. "/include" }
end
