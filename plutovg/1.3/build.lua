-- PlutoVG's CMake project without its examples. What it installs: libplutovg.a, libplutovg.so with its
-- links, libplutovg.dylib, or plutovg.lib (with plutovg.dll) with MSVC; the header in include/plutovg/.
function build(slice, options, deps)
    otok.cmake{ defines = { PLUTOVG_BUILD_EXAMPLES = false } }
    local p = slice.prefix
    -- a static library is told by PLUTOVG_BUILD_STATIC, which its CMake config gives its consumers: the
    -- header says so itself, as the others have no config
    if slice.linkage == "static" then
        local header = p .. "/include/plutovg/plutovg.h"
        local text, n = otok.read(header):gsub("defined%(PLUTOVG_BUILD_STATIC%)", "1")
        assert(n > 0, "plutovg.h no longer tests PLUTOVG_BUILD_STATIC")
        otok.write(header, text)
    end
    local dll = otok.glob("bin/*plutovg*.dll", p)[1]
    if dll then
        return { libraries = { plutovg = { link = otok.glob("lib/plutovg*.lib", p)[1], runtime = dll } }, headers = p .. "/include" }
    end
    local lib = otok.glob("lib/libplutovg.so", p)[1] or otok.glob("lib/libplutovg.dylib", p)[1] or otok.glob("lib/libplutovg.a", p)[1]
        or otok.glob("lib/plutovg*.lib", p)[1]
    return { libraries = { plutovg = lib }, headers = p .. "/include" }
end
