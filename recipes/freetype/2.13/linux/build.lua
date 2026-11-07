-- FreeType's CMake project without its optional dependencies. What it installs: libfreetype.a, or libfreetype.so with
-- its links (libfreetyped in debug); the headers in include/freetype2/.
function build(slice, options, deps)
    otok.cmake{ defines = { FT_DISABLE_ZLIB = true, FT_DISABLE_BZIP2 = true, FT_DISABLE_PNG = true, FT_DISABLE_HARFBUZZ = true,
        FT_DISABLE_BROTLI = true } }
    local p = slice.prefix
    local lib = otok.glob(slice.linkage == "static" and "lib/libfreetype*.a" or "lib/libfreetype*.so", p)[1]
    return { libraries = { freetype = lib }, headers = p .. "/include/freetype2" }
end
