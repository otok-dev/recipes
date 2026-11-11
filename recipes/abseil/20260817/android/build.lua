-- Abseil's CMake project, static, without the tests and test helpers. What it installs: one library for each of its parts
-- (absl_base, absl_strings, ...), all of them returned: which a program needs depends on the Abseil it uses, and the product
-- lists them in link order.
function build(slice, options, deps)
    otok.cmake{ defines = {
        ABSL_BUILD_TESTING = false, ABSL_BUILD_TEST_HELPERS = false, ABSL_PROPAGATE_CXX_STD = true,
        ABSL_MSVC_STATIC_RUNTIME = false, ABSL_ENABLE_INSTALL = true, CMAKE_POSITION_INDEPENDENT_CODE = true,
    } }
    local p = slice.prefix
    local libraries = {}
    for _, name in ipairs(otok.glob("lib/libabsl_*.a", p)) do
        libraries[name:match("lib(absl_[^/]+)%.a$")] = name
    end
    return { libraries = libraries, headers = p .. "/include" }
end
