-- libavif's CMake project, the library only (no apps, tests or examples), decoding through dav1d of deps, found by
-- libavif's Finddav1d.cmake from the variables given; its own subset of libyuv (libavif finds no libyuv on the machine),
-- no libsharpyuv, no libxml2. What it installs: libavif.a, or libavif.dylib with its links.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    otok.cmake{ defines = {
        BUILD_SHARED_LIBS = not static, AVIF_BUILD_APPS = false, AVIF_BUILD_TESTS = false, AVIF_BUILD_EXAMPLES = false,
        AVIF_CODEC_DAV1D = "SYSTEM", DAV1D_INCLUDE_DIR = deps.dav1d.include, DAV1D_LIBRARY = deps.dav1d.libraries.dav1d,
        AVIF_CODEC_AOM = "OFF", AVIF_CODEC_LIBGAV1 = "OFF", AVIF_CODEC_RAV1E = "OFF", AVIF_CODEC_SVT = "OFF",
        AVIF_CODEC_AVM = "OFF", AVIF_LIBYUV = "OFF", AVIF_LIBSHARPYUV = "OFF", AVIF_LIBXML2 = "OFF",
        AVIF_ZLIBPNG = "OFF", AVIF_JPEG = "OFF", CMAKE_INSTALL_LIBDIR = "lib", CMAKE_INSTALL_RPATH = "@loader_path",
    } }
    local p = slice.prefix
    return { libraries = { avif = otok.glob(static and "lib/libavif.a" or "lib/libavif.dylib", p)[1] }, headers = p .. "/include" }
end
