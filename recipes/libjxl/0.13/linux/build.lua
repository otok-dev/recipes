-- libjxl's CMake project, the libraries only: no tools, examples, benchmark, JNI, documentation or plugins. Highway and
-- Brotli of deps, found by libjxl's FindHWY.cmake and FindBrotli.cmake from the variables given; skcms from the resource
-- in third_party/skcms (no lcms2), no libpng and no sjpeg (of the tools only). What it installs: libjxl, libjxl_threads
-- and libjxl_cms, .a or .so with their links.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    local hwy, brotli = deps.highway, deps.brotli
    otok.copy(slice.resources.skcms, slice.source .. "/third_party/skcms")
    otok.cmake{ defines = {
        BUILD_SHARED_LIBS = not static, BUILD_TESTING = false,
        JPEGXL_ENABLE_TOOLS = false, JPEGXL_ENABLE_DEVTOOLS = false, JPEGXL_ENABLE_EXAMPLES = false,
        JPEGXL_ENABLE_BENCHMARK = false, JPEGXL_ENABLE_FUZZERS = false, JPEGXL_ENABLE_JNI = false,
        JPEGXL_ENABLE_DOXYGEN = false, JPEGXL_ENABLE_MANPAGES = false, JPEGXL_ENABLE_PLUGINS = false,
        JPEGXL_ENABLE_VIEWERS = false, JPEGXL_ENABLE_SJPEG = false, JPEGXL_ENABLE_OPENEXR = false,
        JPEGXL_ENABLE_TCMALLOC = false, JPEGXL_ENABLE_SKCMS = true, JPEGXL_BUNDLE_LIBPNG = false,
        JPEGXL_WARNINGS_AS_ERRORS = false, CMAKE_DISABLE_FIND_PACKAGE_PNG = true,
        JPEGXL_FORCE_SYSTEM_HWY = true, HWY_INCLUDE_DIR = hwy.include, HWY_LIBRARY = hwy.libraries.hwy,
        JPEGXL_FORCE_SYSTEM_BROTLI = true, BROTLI_INCLUDE_DIR = brotli.include,
        BROTLICOMMON_LIBRARY = brotli.libraries.brotlicommon, BROTLIDEC_LIBRARY = brotli.libraries.brotlidec,
        BROTLIENC_LIBRARY = brotli.libraries.brotlienc, CMAKE_INSTALL_LIBDIR = "lib",
        CMAKE_POSITION_INDEPENDENT_CODE = true,  -- a static libjxl goes into shared libraries too (opencv_world)
    } }
    local p = slice.prefix
    local libraries = {}
    for _, name in ipairs{ "jxl", "jxl_threads", "jxl_cms" } do
        libraries[name] = otok.glob("lib/lib" .. name .. (static and ".a" or ".so"), p)[1]
    end
    return { libraries = libraries, headers = p .. "/include" }
end
