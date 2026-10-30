-- LunaSVG's CMake project without its examples, with the plutovg of the dependency: CMake fails rather
-- than build the copy in the tree. What it installs: liblunasvg.a, liblunasvg.so with its links,
-- liblunasvg.dylib, or lunasvg.lib (with lunasvg.dll) with MSVC; the header in include/lunasvg/.
function build(slice, options, deps)
    otok.cmake{ defines = { USE_SYSTEM_PLUTOVG = true, CMAKE_REQUIRE_FIND_PACKAGE_plutovg = true, LUNASVG_BUILD_EXAMPLES = false } }
    local p = slice.prefix
    -- a static library is told by LUNASVG_BUILD_STATIC, which its CMake config gives its consumers: the
    -- header says so itself, as the others have no config
    if slice.linkage == "static" then
        local header = p .. "/include/lunasvg/lunasvg.h"
        local text, n = otok.read(header):gsub("defined%(LUNASVG_BUILD_STATIC%)", "1")
        assert(n > 0, "lunasvg.h no longer tests LUNASVG_BUILD_STATIC")
        otok.write(header, text)
    end
    local dll = otok.glob("bin/*lunasvg*.dll", p)[1]
    if dll then
        return { libraries = { lunasvg = { link = otok.glob("lib/lunasvg*.lib", p)[1], runtime = dll } }, headers = p .. "/include" }
    end
    local lib = otok.glob("lib/liblunasvg.so", p)[1] or otok.glob("lib/liblunasvg.dylib", p)[1] or otok.glob("lib/liblunasvg.a", p)[1]
        or otok.glob("lib/lunasvg*.lib", p)[1]
    return { libraries = { lunasvg = lib }, headers = p .. "/include" }
end
