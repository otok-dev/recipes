-- zlib's CMake project, the library only. What it installs: libzs.lib (static), or libz.lib with libz.dll (dynamic),
-- with the suffix d in debug. zlib 1.4 prefixes the names with lib on MSVC (and clang-cl); 1.3 did not.

-- zlib.pc names the library -lz whatever MSVC's file is (libzs, libzd, libzsd): the file's name, so that pkg-config's
-- consumers (meson) link it
local function fix_pkg_config(p, lib)
    local pc = p .. "/lib/pkgconfig/zlib.pc"
    local name = lib:match("([^/]+)%.lib$")
    if not name or not otok.exists(pc) then return end
    local text, n = otok.read(pc):gsub("%-lz%f[%s]", "-l" .. name)
    assert(n > 0, "zlib.pc no longer links -lz")
    otok.write(pc, text)
end

function build(slice, options, deps)
    local static = slice.linkage == "static"
    otok.cmake{ defines = { ZLIB_BUILD_SHARED = not static, ZLIB_BUILD_STATIC = static, ZLIB_BUILD_TESTING = false } }
    local p = slice.prefix
    local dll = otok.glob("bin/libz*.dll", p)[1]
    if dll then
        local link = otok.glob("lib/libz*.lib", p)[1]
        fix_pkg_config(p, link)
        return { libraries = { z = { link = link, runtime = dll } }, headers = p .. "/include" }
    end
    local lib = otok.glob("lib/libzs*.lib", p)[1]
    fix_pkg_config(p, lib)
    return { libraries = { z = lib }, headers = p .. "/include" }
end
