-- OpenEXR's CMake project, the libraries only: no tools, examples, tests, Python bindings or documentation. Imath,
-- libdeflate, OpenJPH and zstd of deps, found through their CMake packages (OpenEXR would use the copies in external/
-- or fetch Imath otherwise). What it installs: libOpenEXR-3_5, libOpenEXRUtil-3_5, libOpenEXRCore-3_5, libIex-3_5 and
-- libIlmThread-3_5 (OpenEXR names its libraries after the version of its API), .a or .so with their links; the headers
-- in include/OpenEXR.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    -- OpenEXR adds the directories of what it links to the RUNPATH of its libraries, which would name otok's cache
    local setup = slice.source .. "/cmake/OpenEXRSetup.cmake"
    local text, n = otok.read(setup):gsub("set%(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE%)", "set(CMAKE_INSTALL_RPATH_USE_LINK_PATH FALSE)")
    if n ~= 1 then error("no CMAKE_INSTALL_RPATH_USE_LINK_PATH in " .. setup) end
    otok.write(setup, text)
    -- under a strict C standard of the project (-std=c11) glibc's endian.h declares no le64toh and the like, which
    -- OpenEXRCore calls: the BSD declarations asked for with _DEFAULT_SOURCE
    local lists = slice.source .. "/CMakeLists.txt"
    text, n = otok.read(lists):gsub("(\nproject%(OpenEXR [^\n]*\n)", "%1add_compile_definitions(_DEFAULT_SOURCE)\n", 1)
    if n ~= 1 then error("no project(OpenEXR) in " .. lists) end
    otok.write(lists, text)
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
        CMAKE_POSITION_INDEPENDENT_CODE = true,  -- a static OpenEXR goes into shared libraries too (opencv_world)
    } }
    local p = slice.prefix
    local libraries = {}
    for _, name in ipairs{ "OpenEXRUtil", "OpenEXR", "IlmThread", "Iex", "OpenEXRCore" } do
        libraries[name] = otok.glob("lib/lib" .. name .. "-*" .. (static and ".a" or ".so"), p)[1]
    end
    return { libraries = libraries, headers = p .. "/include" }
end
