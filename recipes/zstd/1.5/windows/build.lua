-- The CMake project in build/cmake, the library only (no programs, tests or contrib). What it installs: zstd_static.lib
-- (static), or zstd.lib, the import library, with zstd.dll.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    otok.cmake{
        source = slice.source .. "/build/cmake",
        defines = { ZSTD_BUILD_STATIC = static, ZSTD_BUILD_SHARED = not static, ZSTD_BUILD_PROGRAMS = false,
            ZSTD_BUILD_TESTS = false, ZSTD_BUILD_CONTRIB = false,
            ZSTD_USE_STATIC_RUNTIME = false },
    }
    local p = slice.prefix
    if static then
        return { libraries = { zstd = otok.glob("lib/zstd_static.lib", p)[1] }, headers = p .. "/include" }
    end
    return { libraries = { zstd = { link = otok.glob("lib/zstd.lib", p)[1], runtime = otok.glob("bin/zstd.dll", p)[1] } },
        headers = p .. "/include" }
end
