-- The CMake project of the reader (with `writers`, the writer too): libZXing.a, or libZXing.so with its links, and
-- include/ZXing/.
function build(slice, options, deps)
    -- the project of core/, as the wrappers build it: the top one adds, with the C API, the C wrapper's test
    -- program, for which it fetches stb; the writer's libzint is the submodule zint/ beside core/
    otok.cmake{
        source = slice.source .. "/core",
        defines = { ZXING_READERS = true, ZXING_WRITERS = options.writers and "NEW" or "OFF", ZXING_C_API = true },
    }
    local p = slice.prefix
    local library = otok.glob(slice.linkage == "static" and "lib/libZXing.a" or "lib/libZXing.so", p)[1]
    return { libraries = { ZXing = library }, headers = p .. "/include" }
end
