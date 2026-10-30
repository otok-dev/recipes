-- FreeType's CMake project without its optional dependencies. What it installs: libfreetype.a, libfreetype.so with
-- its links, libfreetype.dylib, or freetype.lib (with freetype.dll) with MSVC, freetyped in debug; the headers in
-- include/freetype2/.

-- freetype2.pc names the library -lfreetype, also MSVC's freetyped of a debug build: the file's name, so that
-- pkg-config's consumers (meson) link it
local function fix_pkg_config(p, lib)
    local pc = p .. "/lib/pkgconfig/freetype2.pc"
    local name = lib:match("([^/]+)%.lib$")
    if not name or not otok.exists(pc) then return end
    local text, n = otok.read(pc):gsub("%-lfreetype%f[%s]", "-l" .. name)
    assert(n > 0, "freetype2.pc no longer links -lfreetype")
    otok.write(pc, text)
end

function build(slice, options, deps)
    otok.cmake{ defines = { FT_DISABLE_ZLIB = true, FT_DISABLE_BZIP2 = true, FT_DISABLE_PNG = true, FT_DISABLE_HARFBUZZ = true,
        FT_DISABLE_BROTLI = true } }
    local p = slice.prefix
    local dll = otok.glob("bin/freetype*.dll", p)[1]
    if dll then
        local link = otok.glob("lib/freetype*.lib", p)[1]
        fix_pkg_config(p, link)
        return { libraries = { freetype = { link = link, runtime = dll } }, headers = p .. "/include/freetype2" }
    end
    local lib = otok.glob("lib/libfreetype*.so", p)[1] or otok.glob("lib/libfreetype*.dylib", p)[1] or otok.glob("lib/libfreetype*.a", p)[1]
        or otok.glob("lib/freetype*.lib", p)[1]
    fix_pkg_config(p, lib)
    return { libraries = { freetype = lib }, headers = p .. "/include/freetype2" }
end
