-- nghttp3's CMake project, libnghttp3 only: no examples and no tests. What it installs: libnghttp3.a, or libnghttp3.dylib with
-- its links.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    otok.cmake{ defines = {
        ENABLE_LIB_ONLY = true, ENABLE_STATIC_LIB = static, ENABLE_SHARED_LIB = not static, BUILD_TESTING = false,
    } }
    local p = slice.prefix
    return { libraries = { nghttp3 = otok.glob(static and "lib/libnghttp3.a" or "lib/libnghttp3.dylib", p)[1] }, headers = p .. "/include" }
end
