-- nghttp3's CMake project, libnghttp3 only, static: no examples and no tests. What it installs: nghttp3.lib.
function build(slice, options, deps)
    otok.cmake{ defines = {
        ENABLE_LIB_ONLY = true, ENABLE_STATIC_LIB = true, ENABLE_SHARED_LIB = false, BUILD_TESTING = false,
        ENABLE_STATIC_CRT = false,
    } }
    local p = slice.prefix
    return { libraries = { nghttp3 = otok.glob("lib/nghttp3.lib", p)[1] }, headers = p .. "/include" }
end
