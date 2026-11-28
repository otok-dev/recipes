-- Expat's CMake project, the library only (no xmlwf, examples or tests). What it installs: libexpat.a, or libexpat.dylib with its links.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    otok.cmake{ defines = {
        EXPAT_SHARED_LIBS = not static, EXPAT_BUILD_TOOLS = false, EXPAT_BUILD_EXAMPLES = false, EXPAT_BUILD_TESTS = false,
        EXPAT_BUILD_DOCS = false, EXPAT_BUILD_FUZZERS = false,
    } }
    local p = slice.prefix
    return { libraries = { expat = otok.glob(static and "lib/libexpat.a" or "lib/libexpat.dylib", p)[1] }, headers = p .. "/include" }
end
