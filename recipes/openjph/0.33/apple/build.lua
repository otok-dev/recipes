-- OpenJPH's CMake project, the library only: no programs (ojph_compress, ojph_expand), so no TIFF, and no tests. What it
-- installs: libopenjph.a, or libopenjph.dylib with its links; the headers in include/openjph.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    otok.cmake{ defines = {
        BUILD_SHARED_LIBS = not static, OJPH_BUILD_EXECUTABLES = false, OJPH_ENABLE_TIFF_SUPPORT = false,
        OJPH_BUILD_TESTS = false, OJPH_BUILD_STREAM_EXPAND = false, OJPH_BUILD_FUZZER = false, CMAKE_INSTALL_LIBDIR = "lib",
    } }
    local p = slice.prefix
    return { libraries = { openjph = otok.glob(static and "lib/libopenjph.a" or "lib/libopenjph.dylib", p)[1] },
             headers = p .. "/include" }
end
