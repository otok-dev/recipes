-- Imath's CMake project, the library only: no Python bindings, tests or website. What it installs: libImath-3_2.a or
-- libImath-3_2.so (Imath names its library after the version of its API); the headers in include/Imath.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    otok.cmake{ defines = {
        BUILD_SHARED_LIBS = not static, BUILD_TESTING = false, PYTHON = false, PYBIND11 = false, BUILD_WEBSITE = false,
        IMATH_INSTALL_PKG_CONFIG = true, CMAKE_INSTALL_LIBDIR = "lib",
        -- no link libImath.so -> libImath-3_2.so: CMake makes it while configuring, which on a Windows build machine needs
        -- a privilege, and an app ships the library itself
        IMATH_INSTALL_SYM_LINK = false,
    } }
    local p = slice.prefix
    local lib = otok.glob(static and "lib/libImath-*.a" or "lib/libImath-*.so", p)[1]
    return { libraries = { Imath = lib }, headers = p .. "/include" }
end
