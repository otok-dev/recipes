-- OpenEXR's CMake project, the libraries only: no tools, examples, tests, Python bindings or documentation. Imath,
-- libdeflate, OpenJPH and zstd of deps, found through their CMake packages (OpenEXR would use the copies in external/
-- or fetch Imath otherwise). What it installs: OpenEXR-3_5.lib, OpenEXRUtil-3_5.lib, OpenEXRCore-3_5.lib, Iex-3_5.lib and
-- IlmThread-3_5.lib (OpenEXR names its libraries after the version of its API), static or the import libraries with
-- their DLLs; the headers in include/OpenEXR. DLLs need OPENEXR_DLL in their consumers: the installed OpenEXRConfig.h,
-- which every export header of OpenEXR includes first, defines it.
local names = { "OpenEXRUtil", "OpenEXR", "IlmThread", "Iex", "OpenEXRCore" }

-- OpenEXR takes _MSC_VER for MSVC, which clang-cl defines too: SSE4.1 code without clang's -msse4.1, MSVC's arm64_neon.h
-- in place of arm_neon.h. Those tests leave clang-cl out (MSVC's builds are as before).
local function patch(path, from, to)
    local text, n = otok.read(path):gsub(from, to)
    if n == 0 then error("nothing to patch in " .. path) end
    otok.write(path, text)
end

function build(slice, options, deps)
    local static = slice.linkage == "static"
    local core = slice.source .. "/src/lib/OpenEXRCore/internal_zip.c"
    patch(core, "#if defined __SSE4_1__ || %(_MSC_VER", "#if defined __SSE4_1__ || (!defined(__clang__) && _MSC_VER")
    patch(core, "#    if defined%(_MSC_VER%)\n#        include <arm64_neon.h>",
        "#    if defined(_MSC_VER) && !defined(__clang__)\n#        include <arm64_neon.h>")
    patch(slice.source .. "/src/lib/OpenEXR/ImfSimd.h", "#if defined __SSE4_1__ || %(_MSC_VER",
        "#if defined __SSE4_1__ || (!defined(__clang__) && _MSC_VER")
    otok.cmake{ defines = {
        BUILD_SHARED_LIBS = not static, BUILD_TESTING = false, BUILD_WEBSITE = false,
        OPENEXR_BUILD_TOOLS = false, OPENEXR_INSTALL_TOOLS = false, OPENEXR_BUILD_EXAMPLES = false,
        OPENEXR_BUILD_PYTHON = false, OPENEXR_BUILD_OSS_FUZZ = false, OPENEXR_INSTALL_DOCS = false,
        OPENEXR_ENABLE_THREADING = true, OPENEXR_USE_TBB = false, OPENEXR_INSTALL_PKG_CONFIG = true,
        OPENEXR_FORCE_INTERNAL_IMATH = false, OPENEXR_FORCE_INTERNAL_DEFLATE = false,
        OPENEXR_FORCE_INTERNAL_OPENJPH = false, OPENEXR_FORCE_INTERNAL_ZSTD = false,
        Imath_DIR = deps.imath.prefix .. "/lib/cmake/Imath",
        libdeflate_DIR = deps.libdeflate.prefix .. "/lib/cmake/libdeflate",
        openjph_DIR = deps.openjph.prefix .. "/lib/cmake/openjph",
        zstd_DIR = deps.zstd.prefix .. "/lib/cmake/zstd",
        CMAKE_INSTALL_LIBDIR = "lib",
    } }
    local p = slice.prefix
    local libraries = {}
    for _, name in ipairs(names) do
        local link = otok.glob("lib/" .. name .. "-*.lib", p)[1]
        libraries[name] = static and link or { link = link, runtime = otok.glob("bin/" .. name .. "-*.dll", p)[1] }
    end
    if not static then
        local header = p .. "/include/OpenEXR/OpenEXRConfig.h"
        local text, n = otok.read(header):gsub("(\r?\n)#define INCLUDED_OPENEXR_CONFIG_H 1\r?\n",
            "%0#ifndef OPENEXR_DLL%1#define OPENEXR_DLL /* the DLLs of this build */%1#endif%1", 1)
        if n ~= 1 then error("no include guard in " .. header) end
        otok.write(header, text)
    end
    return { libraries = libraries, headers = p .. "/include" }
end
