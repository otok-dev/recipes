-- The CMake project in build/cmake, the library only. What it installs: liblz4.a, or liblz4.so with its links.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    otok.cmake{
        source = slice.source .. "/build/cmake",
        defines = { BUILD_STATIC_LIBS = static, LZ4_BUILD_CLI = false, LZ4_BUILD_LEGACY_LZ4C = false },
    }
    local p = slice.prefix
    -- lz4file.h includes lz4frame_static.h, which the CMake project does not install
    otok.copy(slice.source .. "/lib/lz4frame_static.h", p .. "/include/lz4frame_static.h")
    return { libraries = { lz4 = otok.glob(static and "lib/liblz4.a" or "lib/liblz4.so", p)[1] }, headers = p .. "/include" }
end
