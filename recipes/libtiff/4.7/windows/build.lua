-- libtiff's CMake project, the C library only. Every codec libtiff can look for on the machine is given or switched off:
-- the libraries of deps, as the options ask, and nothing else (zlib on Apple and Android is the SDK's or the NDK's). What it installs: tiff.lib (static), or tiff.lib, the import library, with tiff.dll.
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
    -- the lzma.h of a static liblzma declares its functions without dllimport only with LZMA_API_STATIC
    if options.lzma and deps.lzma.linkage == "static" then
        local file = slice.source .. "/CMakeLists.txt"
        otok.write(file, "add_definitions(-DLZMA_API_STATIC)\n" .. otok.read(file))
    end
    otok.cmake{ defines = defines }
    local p = slice.prefix
    local lib = otok.glob("lib/tiff.lib", p)[1]
    local dll = otok.glob("bin/tiff.dll", p)[1]
    return { libraries = { tiff = dll and { link = lib, runtime = dll } or lib }, headers = p .. "/include" }
end
