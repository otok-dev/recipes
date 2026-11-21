-- libdeflate's CMake project, the library only (no libdeflate-gzip, no tests), with compression and decompression of
-- DEFLATE, zlib and gzip. What it installs: libdeflate.a, or libdeflate.dylib with its links.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    otok.cmake{ defines = {
        LIBDEFLATE_BUILD_STATIC_LIB = static, LIBDEFLATE_BUILD_SHARED_LIB = not static, LIBDEFLATE_BUILD_GZIP = false,
        LIBDEFLATE_BUILD_TESTS = false, CMAKE_INSTALL_LIBDIR = "lib",
    } }
    local p = slice.prefix
    return { libraries = { deflate = otok.glob(static and "lib/libdeflate.a" or "lib/libdeflate.dylib", p)[1] },
             headers = p .. "/include" }
end
