-- The CMake project in build/cmake, the library only (no programs, tests or contrib). What it installs: libzstd.a, or libzstd.so
-- with its links.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    otok.cmake{
        source = slice.source .. "/build/cmake",
        defines = { ZSTD_BUILD_STATIC = static, ZSTD_BUILD_SHARED = not static, ZSTD_BUILD_PROGRAMS = false,
            ZSTD_BUILD_TESTS = false, ZSTD_BUILD_CONTRIB = false, ZSTD_FRAMEWORK = false },
    }
    local p = slice.prefix
    return { libraries = { zstd = otok.glob(static and "lib/libzstd.a" or "lib/libzstd.so", p)[1] }, headers = p .. "/include" }
end
