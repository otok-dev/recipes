-- Highway's CMake project, the library hwy only: no contrib (sorting, image, math, …), tests or examples. What it installs:
-- libhwy.a, or libhwy.so with its links; the headers in include/hwy.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    otok.cmake{ defines = {
        BUILD_SHARED_LIBS = not static, HWY_ENABLE_CONTRIB = false, HWY_ENABLE_EXAMPLES = false, HWY_ENABLE_TESTS = false,
        HWY_ENABLE_INSTALL = true, HWY_WARNINGS_ARE_ERRORS = false, BUILD_TESTING = false, CMAKE_INSTALL_LIBDIR = "lib",
        CMAKE_POSITION_INDEPENDENT_CODE = true,  -- a static hwy goes into shared libraries too (libjxl)
    } }
    local p = slice.prefix
    return { libraries = { hwy = otok.glob(static and "lib/libhwy.a" or "lib/libhwy.so", p)[1] }, headers = p .. "/include" }
end
