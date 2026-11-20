-- Imath's CMake project, the library only: no Python bindings, tests or website. What it installs: Imath-3_2.lib (Imath
-- names its library after the version of its API), static or the import library with Imath-3_2.dll; the headers in
-- include/Imath. A DLL needs IMATH_DLL in its consumers (half's lookup table is data the DLL exports, which needs
-- __declspec(dllimport)): the installed ImathConfig.h, which every header of Imath includes, defines it.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    otok.cmake{ defines = {
        BUILD_SHARED_LIBS = not static, BUILD_TESTING = false, PYTHON = false, PYBIND11 = false, BUILD_WEBSITE = false,
        IMATH_INSTALL_PKG_CONFIG = true, CMAKE_INSTALL_LIBDIR = "lib",
    } }
    local p = slice.prefix
    local link = otok.glob("lib/Imath-*.lib", p)[1]
    if static then return { libraries = { Imath = link }, headers = p .. "/include" } end
    local header = p .. "/include/Imath/ImathConfig.h"
    local text, n = otok.read(header):gsub("(\r?\n)#define INCLUDED_IMATH_CONFIG_H 1\r?\n",
        "%0#ifndef IMATH_DLL%1#define IMATH_DLL /* the DLL of this build */%1#endif%1", 1)
    if n ~= 1 then error("no include guard in " .. header) end
    otok.write(header, text)
    return { libraries = { Imath = { link = link, runtime = otok.glob("bin/Imath-*.dll", p)[1] } }, headers = p .. "/include" }
end
