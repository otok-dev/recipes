-- libsodium's sources with the recipe's CMakeLists.txt, which builds them as builds/msvc/vs2026/libsodium does. What it
-- installs: libsodium.lib, or libsodium.lib with libsodium.dll.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    otok.copy(slice.recipe .. "/CMakeLists.txt", slice.source .. "/otok/CMakeLists.txt")
    otok.cmake{ source = slice.source .. "/otok", defines = { SODIUM_SOURCE = slice.source } }
    local p = slice.prefix
    if static then
        -- consumers of the static library define nothing: its export.h says so itself, as libsodium's own static
        -- builds for MSVC ask SODIUM_STATIC of them
        local header = p .. "/include/sodium/export.h"
        local text, n = otok.read(header):gsub("#ifdef SODIUM_STATIC\n", "#if 1 /* static, SODIUM_STATIC */\n")
        assert(n == 1, "export.h has no '#ifdef SODIUM_STATIC'")
        otok.write(header, text)
        return { libraries = { sodium = p .. "/lib/libsodium.lib" }, headers = p .. "/include" }
    end
    return { libraries = { sodium = { link = p .. "/lib/libsodium.lib", runtime = p .. "/bin/libsodium.dll" } },
             headers = p .. "/include" }
end
