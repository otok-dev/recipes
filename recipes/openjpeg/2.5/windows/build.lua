-- OpenJPEG's CMake project, the library openjp2 only (no codec programs, no JPIP, no tests). What it installs: openjp2.lib,
-- static or the import library with openjp2.dll; the headers in include/openjpeg-2.5, the directory consumers include.
-- A static library needs OPJ_STATIC in its consumers (without it openjpeg.h declares the functions imported from a DLL):
-- the installed header defines it.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    otok.cmake{ defines = {
        BUILD_STATIC_LIBS = static, BUILD_CODEC = false, BUILD_JPIP = false, BUILD_JPIP_SERVER = false,
        BUILD_VIEWER = false, BUILD_JAVA = false, BUILD_THIRDPARTY = false, BUILD_TESTING = false, BUILD_DOC = false,
        BUILD_UNIT_TESTS = false, BUILD_LUTS_GENERATOR = false, CMAKE_INSTALL_LIBDIR = "lib",
    } }
    local p = slice.prefix
    local headers = p .. "/include/openjpeg-2.5"
    local link = otok.glob("lib/openjp2.lib", p)[1]
    if static then
        local header = headers .. "/openjpeg.h"
        local text, n = otok.read(header):gsub("\n#if defined%(OPJ_STATIC%) || !defined%(_WIN32%)\n",
            "\n#ifndef OPJ_STATIC\n#define OPJ_STATIC /* the static library of this build */\n#endif\n%0", 1)
        if n ~= 1 then error("no OPJ_STATIC test in " .. header) end
        otok.write(header, text)
        return { libraries = { openjp2 = link }, headers = headers }
    end
    return { libraries = { openjp2 = { link = link, runtime = otok.glob("bin/openjp2.dll", p)[1] } }, headers = headers }
end
