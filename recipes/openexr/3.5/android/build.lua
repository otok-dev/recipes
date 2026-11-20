-- OpenEXR's CMake project, the libraries only: no tools, examples, tests, Python bindings or documentation. Imath,
-- libdeflate, OpenJPH and zstd of deps, found through their CMake packages (OpenEXR would use the copies in external/
-- or fetch Imath otherwise). What it installs: libOpenEXR-3_5, libOpenEXRUtil-3_5, libOpenEXRCore-3_5, libIex-3_5 and
-- libIlmThread-3_5 (OpenEXR names its libraries after the version of its API), .a or .so; the headers
-- in include/OpenEXR.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    -- OpenEXR adds the directories of what it links to the RUNPATH of its libraries, which would name otok's cache
    local setup = slice.source .. "/cmake/OpenEXRSetup.cmake"
    local text, n = otok.read(setup):gsub("set%(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE%)", "set(CMAKE_INSTALL_RPATH_USE_LINK_PATH FALSE)")
    if n ~= 1 then error("no CMAKE_INSTALL_RPATH_USE_LINK_PATH in " .. setup) end
    otok.write(setup, text)
    -- no links libOpenEXR.so -> libOpenEXR-3_5.so: CMake makes them while configuring, which on a Windows build machine
    -- needs a privilege, and an app ships the libraries themselves
    for _, file in ipairs{ "/cmake/LibraryDefine.cmake", "/cmake/OpenEXRLibraryDefine.cmake" } do
        local path = slice.source .. file
        text, n = otok.read(path):gsub('AND %(NOT "%${OPENEXR_LIB_SUFFIX}" STREQUAL ""%) AND NOT WIN32%)',
            'AND (NOT "${OPENEXR_LIB_SUFFIX}" STREQUAL "") AND NOT WIN32 AND NOT ANDROID)', 1)
        if n ~= 1 then error("no links of the libraries in " .. path) end
        otok.write(path, text)
    end
    -- aligned_alloc, which OpenEXRCore calls, is in bionic from API level 28: posix_memalign below, as for older macOS
    local zstd = slice.source .. "/src/lib/OpenEXRCore/internal_zstd.c"
    text, n = otok.read(zstd):gsub("#elif defined%(__APPLE__%) && %(MAC_OS_X_VERSION_MIN_REQUIRED < 101500%)",
        "#elif (defined(__APPLE__) && (MAC_OS_X_VERSION_MIN_REQUIRED < 101500)) || (defined(__ANDROID__) && __ANDROID_API__ < 28)", 1)
    if n ~= 1 then error("no choice of the aligned allocation in " .. zstd) end
    otok.write(zstd, text)
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
