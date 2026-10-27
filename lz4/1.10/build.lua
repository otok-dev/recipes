-- The CMake project in build/cmake, the library only. What it installs: liblz4.a, liblz4.so with its
-- links, liblz4.dylib, or lz4.lib (with lz4.dll) with MSVC.
function build(slice, options, deps)
    otok.cmake{
        source = slice.source .. "/build/cmake",
        defines = { BUILD_STATIC_LIBS = slice.linkage == "static", LZ4_BUILD_CLI = false, LZ4_BUILD_LEGACY_LZ4C = false },
    }
    local p = slice.prefix
    -- lz4file.h includes lz4frame_static.h, which the CMake project does not install
    otok.copy(slice.source .. "/lib/lz4frame_static.h", p .. "/include/lz4frame_static.h")
    local dll = otok.glob("bin/*lz4*.dll", p)[1]
    if dll then
        return { libraries = { lz4 = { link = otok.glob("lib/lz4*.lib", p)[1], runtime = dll } }, headers = p .. "/include" }
    end
    local lib = otok.glob("lib/liblz4.so", p)[1] or otok.glob("lib/liblz4.dylib", p)[1] or otok.glob("lib/liblz4.a", p)[1]
        or otok.glob("lib/lz4*.lib", p)[1]
    return { libraries = { lz4 = lib }, headers = p .. "/include" }
end
