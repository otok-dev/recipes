-- libavif's CMake project, the library only (no apps, tests or examples), decoding through dav1d of deps, found by
-- libavif's Finddav1d.cmake from the variables given; its own subset of libyuv (libavif finds no libyuv on the machine),
-- no libsharpyuv, no libxml2. What it installs: avif.lib, static or the import library with avif.dll.
-- A DLL needs AVIF_DLL in its consumers (without it avif.h declares the functions of a static library): the installed
-- header defines it.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    -- the static library is merged by lib.exe's syntax with the target's archiver (llvm-lib with clang-cl), not by
    -- ar's MRI scripts, which libavif would choose for clang-cl
    local merge = slice.source .. "/cmake/Modules/merge_static_libs.cmake"
    local text, n = otok.read(merge):gsub('(elseif%(CMAKE_C_COMPILER_ID MATCHES "%^%(Clang|GNU|Intel|IntelLLVM%)%$")%)',
        '%1 AND NOT MSVC)', 1)
    if n ~= 1 then error("no choice of the archiver in " .. merge) end
    otok.write(merge, text)
    otok.cmake{ defines = {
        CMAKE_LIBTOOL = slice.toolchain.ar,
        BUILD_SHARED_LIBS = not static, AVIF_BUILD_APPS = false, AVIF_BUILD_TESTS = false, AVIF_BUILD_EXAMPLES = false,
        AVIF_CODEC_DAV1D = "SYSTEM", DAV1D_INCLUDE_DIR = deps.dav1d.include, DAV1D_LIBRARY = deps.dav1d.libraries.dav1d,
        AVIF_CODEC_AOM = "OFF", AVIF_CODEC_LIBGAV1 = "OFF", AVIF_CODEC_RAV1E = "OFF", AVIF_CODEC_SVT = "OFF",
        AVIF_CODEC_AVM = "OFF", AVIF_LIBYUV = "OFF", AVIF_LIBSHARPYUV = "OFF", AVIF_LIBXML2 = "OFF",
        AVIF_ZLIBPNG = "OFF", AVIF_JPEG = "OFF", CMAKE_INSTALL_LIBDIR = "lib",
    } }
    local p = slice.prefix
    local headers = p .. "/include"
    local link = otok.glob("lib/avif.lib", p)[1]
    if static then return { libraries = { avif = link }, headers = headers } end
    local header = headers .. "/avif/avif.h"
    local text, n = otok.read(header):gsub("\n#if defined%(AVIF_DLL%)\n",
        "\n#ifndef AVIF_DLL\n#define AVIF_DLL /* the DLL of this build */\n#endif\n%0", 1)
    if n ~= 1 then error("no AVIF_DLL test in " .. header) end
    otok.write(header, text)
    return { libraries = { avif = { link = link, runtime = otok.glob("bin/avif.dll", p)[1] } }, headers = headers }
end
