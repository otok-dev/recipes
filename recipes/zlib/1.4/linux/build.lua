-- zlib's CMake project, the library only. What it installs: libz.a, or libz.so with its links.

function build(slice, options, deps)
    local static = slice.linkage == "static"
    otok.cmake{ defines = { ZLIB_BUILD_SHARED = not static, ZLIB_BUILD_STATIC = static, ZLIB_BUILD_TESTING = false } }
    local p = slice.prefix
    local lib = otok.glob(static and "lib/libz.a" or "lib/libz.so", p)[1]
    return { libraries = { z = lib }, headers = p .. "/include" }
end
