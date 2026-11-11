-- libtiff's CMake project, the C library only. Every codec libtiff can look for on the machine is given or switched off:
-- the libraries of deps, as the options ask, and nothing else (zlib on Apple and Android is the SDK's or the NDK's). What it installs: libtiff.a, or libtiff.so with its links.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    local defines = {
        ["tiff-static"] = static, ["tiff-tools"] = false, ["tiff-tests"] = false, ["tiff-contrib"] = false, ["tiff-docs"] = false,
        ["tiff-cxx"] = false, sphinx = false, ["tiff-opengl"] = false,
        libdeflate = false, jbig = false, lerc = false, ["old-jpeg"] = options.jpeg,
        zlib = options.zlib, pixarlog = options.zlib, jpeg = options.jpeg, lzma = options.lzma, zstd = options.zstd, webp = options.webp,
    }
    if options.zlib and deps.zlib then
        local z = deps.zlib
        defines.ZLIB_USE_STATIC_LIBS = z.linkage == "static"
        defines.ZLIB_INCLUDE_DIR = z.include
        defines.ZLIB_LIBRARY = z.libraries.z
    end
    if options.jpeg then
        local jpeg = deps["libjpeg-turbo"]
        defines["jpeg-prefer-standard"] = true
        defines.JPEG_INCLUDE_DIR = jpeg.include
        defines.JPEG_LIBRARY_RELEASE = jpeg.libraries.jpeg
    end
    if options.lzma then
        local lzma = deps.lzma
        defines.LIBLZMA_INCLUDE_DIR = lzma.include
        defines.LIBLZMA_LIBRARY = lzma.libraries.lzma
    end
    if options.zstd then
        local zstd = deps.zstd
        defines.ZSTD_INCLUDE_DIR = zstd.include
        defines.ZSTD_LIBRARY = zstd.libraries.zstd
    end
    if options.webp then
        local webp = deps.libwebp
        defines.WebP_INCLUDE_DIR = webp.include
        defines.WebP_LIBRARY = webp.libraries.webp
    end
    otok.cmake{ defines = defines }
    local p = slice.prefix
    -- one include/ for all ABIs: the 64-bit types and ssize_t of tiffconf.h by the width of long, as the NDK has them
    local conf = p .. "/include/tiffconf.h"
    local text = otok.read(conf)
    local function by_width(name, lp64, ilp32)
        local block = "#if defined(__LP64__)\n#define " .. name .. " " .. lp64 .. "\n#else\n#define " .. name .. " " .. ilp32 .. "\n#endif"
        text = text:gsub("#define " .. name .. " [^\n]*", function() return block end)
    end
    by_width("TIFF_INT64_T", "long", "long long")
    by_width("TIFF_UINT64_T", "unsigned long", "unsigned long long")
    by_width("TIFF_SSIZE_T", "long", "int")
    otok.write(conf, text)
    local lib = otok.glob(static and "lib/libtiff.a" or "lib/libtiff.so", p)[1]
    return { libraries = { tiff = lib }, headers = p .. "/include" }
end
