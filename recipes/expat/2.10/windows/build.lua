-- Expat's CMake project, the library only, static. What it installs: libexpat.lib or libexpatMD.lib (the name carries the CRT).
function build(slice, options, deps)
    otok.cmake{ defines = {
        EXPAT_SHARED_LIBS = false, EXPAT_BUILD_TOOLS = false, EXPAT_BUILD_EXAMPLES = false, EXPAT_BUILD_TESTS = false,
        EXPAT_BUILD_DOCS = false, EXPAT_BUILD_FUZZERS = false, EXPAT_MSVC_STATIC_CRT = false,
    } }
    local p = slice.prefix
    return { libraries = { expat = otok.glob("lib/*expat*.lib", p)[1] }, headers = p .. "/include" }
end
