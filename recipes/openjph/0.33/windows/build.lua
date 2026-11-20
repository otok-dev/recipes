-- OpenJPH's CMake project, the library only: no programs (ojph_compress, ojph_expand), so no TIFF, and no tests. What it
-- installs: openjph.0.33.lib (OpenJPH names its library after its version with MSVC's flavor), static or with
-- openjph.0.33.dll; the headers in include/openjph. Its consumers define nothing: it imports nothing through
-- __declspec(dllimport).
function build(slice, options, deps)
    local static = slice.linkage == "static"
    otok.cmake{ defines = {
        BUILD_SHARED_LIBS = not static, OJPH_BUILD_EXECUTABLES = false, OJPH_ENABLE_TIFF_SUPPORT = false,
        OJPH_BUILD_TESTS = false, OJPH_BUILD_STREAM_EXPAND = false, OJPH_BUILD_FUZZER = false, CMAKE_INSTALL_LIBDIR = "lib",
    } }
    local p = slice.prefix
    local link = otok.glob("lib/openjph*.lib", p)[1]
    if static then return { libraries = { openjph = link }, headers = p .. "/include" } end
    return { libraries = { openjph = { link = link, runtime = otok.glob("bin/openjph*.dll", p)[1] } }, headers = p .. "/include" }
end
