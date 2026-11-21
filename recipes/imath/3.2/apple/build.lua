-- Imath's CMake project, the library only: no Python bindings, tests or website. What it installs: libImath-3_2.a, or
-- libImath-3_2.dylib with its links (Imath names its library after the version of its API); the headers in include/Imath.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    otok.cmake{ defines = {
        BUILD_SHARED_LIBS = not static, BUILD_TESTING = false, PYTHON = false, PYBIND11 = false, BUILD_WEBSITE = false,
        IMATH_INSTALL_PKG_CONFIG = true, CMAKE_INSTALL_LIBDIR = "lib",
        -- Imath would name its own install directory in the RPATH, which is in otok's cache
        CMAKE_INSTALL_RPATH = "@loader_path",
    } }
    local p = slice.prefix
    local lib = otok.glob(static and "lib/libImath-3_2.a" or "lib/libImath-3_2.dylib", p)[1]
    return { libraries = { Imath = lib }, headers = p .. "/include" }
end
