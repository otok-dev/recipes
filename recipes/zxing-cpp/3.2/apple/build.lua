-- The CMake project of the reader (with `writers`, the writer too): libZXing.a and include/ZXing/, with the module map
-- of the C API.
function build(slice, options, deps)
    -- the project of core/, as the wrappers build it: the top one adds, with the C API, the C wrapper's test
    -- program, for which it fetches stb; the writer's libzint is the submodule zint/ beside core/
    otok.cmake{
        source = slice.source .. "/core",
        defines = { ZXING_READERS = true, ZXING_WRITERS = options.writers and "NEW" or "OFF", ZXING_C_API = true },
    }
    local p = slice.prefix
    -- the module of the Swift API (wrappers/ZXingSwift): the C API and the headers it includes in C, the
    -- other headers are C++
    otok.write(p .. "/module.modulemap", 'module CZXing {\n    header "../ZXing/Version.h"\n    header "../ZXing/BarcodeFormat.h"\n'
        .. '    header "../ZXing/ZXingC.h"\n    export *\n}\n')
    return { libraries = { ZXing = p .. "/lib/libZXing.a" }, headers = p .. "/include", module_map = p .. "/module.modulemap" }
end
