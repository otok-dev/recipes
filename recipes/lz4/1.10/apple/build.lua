-- The CMake project in build/cmake, the static library only.
function build(slice, options, deps)
    otok.cmake{
        source = slice.source .. "/build/cmake",
        defines = { BUILD_STATIC_LIBS = true, LZ4_BUILD_CLI = false, LZ4_BUILD_LEGACY_LZ4C = false },
    }
    local p = slice.prefix
    -- lz4file.h includes lz4frame_static.h, which the CMake project does not install
    otok.copy(slice.source .. "/lib/lz4frame_static.h", p .. "/include/lz4frame_static.h")
    return { libraries = { lz4 = p .. "/lib/liblz4.a" }, headers = p .. "/include" }
end
