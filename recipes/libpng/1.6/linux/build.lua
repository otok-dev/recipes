-- libpng's CMake project, the library only. What it installs: libpng16.a, or libpng16.so with its links (libpng16d in
-- debug); the headers in include/ and include/libpng16/, and libpng.pc.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    -- FindZLIB takes a static zlib only when told to look for one
    otok.cmake{ defines = { PNG_SHARED = not static, PNG_STATIC = static, PNG_TESTS = false, PNG_TOOLS = false, PNG_FRAMEWORK = false,
        ZLIB_USE_STATIC_LIBS = deps.zlib.linkage == "static" } }
    local p = slice.prefix
    local lib = otok.glob(static and "lib/libpng16*.a" or "lib/libpng16*.so", p)[1]
    return { libraries = { png16 = lib }, headers = p .. "/include" }
end
