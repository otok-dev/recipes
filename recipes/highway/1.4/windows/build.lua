-- Highway's CMake project, the library hwy only: no contrib (sorting, image, math, …), tests or examples. What it installs:
-- hwy.lib, static or the import library with hwy.dll; the headers in include/hwy.
-- A DLL needs HWY_SHARED_DEFINE in its consumers (without it highway_export.h declares the functions of a static library):
-- the installed header defines it.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    otok.cmake{ defines = {
        BUILD_SHARED_LIBS = not static, HWY_ENABLE_CONTRIB = false, HWY_ENABLE_EXAMPLES = false, HWY_ENABLE_TESTS = false,
        HWY_ENABLE_INSTALL = true, HWY_WARNINGS_ARE_ERRORS = false, BUILD_TESTING = false, CMAKE_INSTALL_LIBDIR = "lib",
    } }
    local p = slice.prefix
    local headers = p .. "/include"
    local link = otok.glob("lib/hwy.lib", p)[1]
    if static then return { libraries = { hwy = link }, headers = headers } end
    local header = headers .. "/hwy/highway_export.h"
    local text, n = otok.read(header):gsub("\n#if !defined%(HWY_SHARED_DEFINE%)\n",
        "\n#ifndef HWY_SHARED_DEFINE\n#define HWY_SHARED_DEFINE /* the DLL of this build */\n#endif\n%0", 1)
    if n ~= 1 then error("no HWY_SHARED_DEFINE test in " .. header) end
    otok.write(header, text)
    return { libraries = { hwy = { link = link, runtime = otok.glob("bin/hwy.dll", p)[1] } }, headers = headers }
end
