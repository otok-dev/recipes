-- libdeflate's CMake project, the library only (no libdeflate-gzip, no tests), with compression and decompression of
-- DEFLATE, zlib and gzip. What it installs: deflatestatic.lib (libdeflate's name of its static library on Windows), or
-- deflate.lib with deflate.dll. LIBDEFLATE_DLL, which a DLL's consumers may define, only makes the calls a little
-- faster (libdeflate.h): libdeflate exports no data.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    otok.cmake{ defines = {
        LIBDEFLATE_BUILD_STATIC_LIB = static, LIBDEFLATE_BUILD_SHARED_LIB = not static, LIBDEFLATE_BUILD_GZIP = false,
        LIBDEFLATE_BUILD_TESTS = false, CMAKE_INSTALL_LIBDIR = "lib",
    } }
    local p = slice.prefix
    if static then return { libraries = { deflate = otok.glob("lib/deflatestatic.lib", p)[1] }, headers = p .. "/include" } end
    return { libraries = { deflate = { link = otok.glob("lib/deflate.lib", p)[1], runtime = otok.glob("bin/deflate.dll", p)[1] } },
             headers = p .. "/include" }
end
