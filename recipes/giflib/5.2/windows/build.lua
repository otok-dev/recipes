-- giflib through the recipe's CMakeLists.txt, libgif only. What it installs: gif.lib (static), or gif.lib, the import library,
-- with gif.dll.
function build(slice, options, deps)
    otok.copy(slice.recipe .. "/CMakeLists.txt", slice.source .. "/CMakeLists.txt")
    otok.cmake{}
    local p = slice.prefix
    local lib = otok.glob("lib/gif.lib", p)[1]
    local dll = otok.glob("bin/gif.dll", p)[1]
    return { libraries = { gif = dll and { link = lib, runtime = dll } or lib }, headers = p .. "/include" }
end
