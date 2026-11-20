-- libjxl's CMake project, the libraries only: no tools, examples, benchmark, JNI, documentation or plugins. Highway and
-- Brotli of deps, found by libjxl's FindHWY.cmake and FindBrotli.cmake from the variables given; skcms from the resource
-- in third_party/skcms (no lcms2), no libpng and no sjpeg (of the tools only). What it installs: jxl.lib, jxl_threads.lib
-- and jxl_cms.lib, static or the import libraries with their DLLs.
-- Static libraries need JXL_STATIC_DEFINE, JXL_THREADS_STATIC_DEFINE and JXL_CMS_STATIC_DEFINE in their consumers (without
-- them the export headers declare functions imported from DLLs): the installed headers define them.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    local hwy, brotli = deps.highway, deps.brotli
    otok.copy(slice.resources.skcms, slice.source .. "/third_party/skcms")
    otok.cmake{ defines = {
        BUILD_SHARED_LIBS = not static, BUILD_TESTING = false,
        JPEGXL_ENABLE_TOOLS = false, JPEGXL_ENABLE_DEVTOOLS = false, JPEGXL_ENABLE_EXAMPLES = false,
        JPEGXL_ENABLE_BENCHMARK = false, JPEGXL_ENABLE_FUZZERS = false, JPEGXL_ENABLE_JNI = false,
        JPEGXL_ENABLE_DOXYGEN = false, JPEGXL_ENABLE_MANPAGES = false, JPEGXL_ENABLE_PLUGINS = false,
        JPEGXL_ENABLE_VIEWERS = false, JPEGXL_ENABLE_SJPEG = false, JPEGXL_ENABLE_OPENEXR = false,
        JPEGXL_ENABLE_TCMALLOC = false, JPEGXL_ENABLE_SKCMS = true, JPEGXL_BUNDLE_LIBPNG = false,
        JPEGXL_WARNINGS_AS_ERRORS = false, CMAKE_DISABLE_FIND_PACKAGE_PNG = true,
        JPEGXL_FORCE_SYSTEM_HWY = true, HWY_INCLUDE_DIR = hwy.include, HWY_LIBRARY = hwy.libraries.hwy,
        JPEGXL_FORCE_SYSTEM_BROTLI = true, BROTLI_INCLUDE_DIR = brotli.include,
        BROTLICOMMON_LIBRARY = brotli.libraries.brotlicommon, BROTLIDEC_LIBRARY = brotli.libraries.brotlidec,
        BROTLIENC_LIBRARY = brotli.libraries.brotlienc, CMAKE_INSTALL_LIBDIR = "lib",
    } }
    local p = slice.prefix
    local headers = p .. "/include"
    local libraries = {}
    for _, name in ipairs{ "jxl", "jxl_threads", "jxl_cms" } do
        local link = otok.glob("lib/" .. name .. ".lib", p)[1]
        libraries[name] = static and link or { link = link, runtime = otok.glob("bin/" .. name .. ".dll", p)[1] }
    end
    if static then
        for file, macro in pairs{ jxl_export = "JXL_STATIC_DEFINE", jxl_threads_export = "JXL_THREADS_STATIC_DEFINE",
                                  jxl_cms_export = "JXL_CMS_STATIC_DEFINE" } do
            local header = headers .. "/jxl/" .. file .. ".h"
            -- CMake's GenerateExportHeader writes CRLF line ends on Windows
            local text, n = otok.read(header):gsub("(\r?\n)#ifdef " .. macro .. "\r?\n",
                "%1#ifndef " .. macro .. "%1#define " .. macro .. " /* the static library of this build */%1#endif%0", 1)
            if n ~= 1 then error("no " .. macro .. " test in " .. header) end
            otok.write(header, text)
        end
    end
    return { libraries = libraries, headers = headers }
end
