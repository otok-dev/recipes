-- libxml2's CMake project, the library only: no programs, tests, documentation, Python, ICU, readline, loadable modules or
-- network code. iconv is the system library. What it installs: libxml2.a, or libxml2.so with its links.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    local defines = {
        LIBXML2_WITH_PROGRAMS = false, LIBXML2_WITH_TESTS = false, LIBXML2_WITH_DOCS = false, LIBXML2_WITH_PYTHON = false,
        LIBXML2_WITH_ICU = false, LIBXML2_WITH_READLINE = false, LIBXML2_WITH_MODULES = false, LIBXML2_WITH_HTTP = false,
        LIBXML2_WITH_ICONV = true, LIBXML2_WITH_ZLIB = options.zlib,
    }
    if options.zlib then
        local z = deps.zlib
        defines.ZLIB_USE_STATIC_LIBS = z.linkage == "static"
        defines.ZLIB_INCLUDE_DIR = z.include
        defines.ZLIB_LIBRARY = z.libraries.z
    end
    otok.cmake{ defines = defines }
    local p = slice.prefix
    return { libraries = { xml2 = otok.glob(static and "lib/libxml2.a" or "lib/libxml2.so", p)[1] }, headers = p .. "/include/libxml2" }
end
