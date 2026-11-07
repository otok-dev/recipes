-- LunaSVG's CMake project without its examples, with the plutovg of the dependency: CMake fails rather
-- than build the copy in the tree. What it installs: liblunasvg.a, or liblunasvg.so with its
-- links; the header in include/lunasvg/.
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
    local lib = otok.glob(slice.linkage == "static" and "lib/liblunasvg.a" or "lib/liblunasvg.so", p)[1]
    return { libraries = { lunasvg = lib }, headers = p .. "/include" }
end
