-- nghttp2's CMake project, libnghttp2 only: nothing of the applications, examples, tests or documentation, and none of the
-- libraries they look for. What it installs: libnghttp2.a, or libnghttp2.dylib with its links.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    otok.cmake{ defines = {
        ENABLE_LIB_ONLY = true, ENABLE_DOC = false, ENABLE_FAILMALLOC = false, ENABLE_HTTP3 = false, BUILD_TESTING = false,
        BUILD_STATIC_LIBS = static, WITH_LIBXML2 = false, WITH_JEMALLOC = false,
    } }
    local p = slice.prefix
    return { libraries = { nghttp2 = otok.glob(static and "lib/libnghttp2.a" or "lib/libnghttp2.dylib", p)[1] }, headers = p .. "/include" }
end
