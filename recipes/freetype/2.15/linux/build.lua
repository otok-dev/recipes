-- FreeType's CMake project without its optional dependencies. What it installs: libfreetype.a, or libfreetype.so with
-- its links (libfreetyped in debug); the headers in include/freetype2/.

-- freetype2.pc names the library -lfreetype, also libfreetyped of a debug build: the file's name, so that
-- pkg-config's consumers (meson: HarfBuzz) link it
local function fix_pkg_config(p, lib)
    local pc = p .. "/lib/pkgconfig/freetype2.pc"
    local name = lib:match("/lib([^/]+)%.[as]o?$")
    if not otok.exists(pc) then return end
    local text, n = otok.read(pc):gsub("%-lfreetype%f[%s]", "-l" .. name)
    assert(n > 0, "freetype2.pc no longer links -lfreetype")
    otok.write(pc, text)
end

function build(slice, options, deps)
    otok.cmake{ defines = { FT_DISABLE_ZLIB = true, FT_DISABLE_BZIP2 = true, FT_DISABLE_PNG = true, FT_DISABLE_HARFBUZZ = true,
        FT_DISABLE_BROTLI = true } }
    local p = slice.prefix
    local lib = otok.glob(slice.linkage == "static" and "lib/libfreetype*.a" or "lib/libfreetype*.so", p)[1]
    fix_pkg_config(p, lib)
    return { libraries = { freetype = lib }, headers = p .. "/include/freetype2" }
end
