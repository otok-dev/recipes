-- nghttp2's CMake project, libnghttp2 only, static: nothing of the applications, examples, tests or documentation, and none
-- of the libraries they look for. What it installs: nghttp2.lib.
function build(slice, options, deps)
    otok.cmake{ defines = {
        ENABLE_LIB_ONLY = true, ENABLE_DOC = false, ENABLE_FAILMALLOC = false, ENABLE_HTTP3 = false, BUILD_TESTING = false,
        BUILD_STATIC_LIBS = true, ENABLE_STATIC_CRT = false, WITH_LIBXML2 = false, WITH_JEMALLOC = false,
    } }
    local p = slice.prefix
    return { libraries = { nghttp2 = otok.glob("lib/nghttp2.lib", p)[1] }, headers = p .. "/include" }
end
