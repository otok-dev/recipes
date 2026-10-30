-- zlib's CMake project, the library only. What it installs: libz.a, libz.so with its links, libz.dylib,
-- or with MSVC zs.lib (static), z.lib with z.dll (dynamic), with the suffix d in debug.

-- zlib.pc names the library -lz whatever MSVC's file is (zs, zd, zsd): the file's name, so that pkg-config's
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
    local dll = otok.glob("bin/z*.dll", p)[1]
    if dll then
        local link = otok.glob("lib/z*.lib", p)[1]
        fix_pkg_config(p, link)
        return { libraries = { z = { link = link, runtime = dll } }, headers = p .. "/include" }
    end
    local lib = otok.glob("lib/libz.so", p)[1] or otok.glob("lib/libz.dylib", p)[1] or otok.glob("lib/libz.a", p)[1]
        or otok.glob("lib/zs*.lib", p)[1]
    fix_pkg_config(p, lib)
    return { libraries = { z = lib }, headers = p .. "/include" }
end
