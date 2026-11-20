-- OpenJPEG's CMake project, the library openjp2 only (no codec programs, no JPIP, no tests). What it installs: libopenjp2,
-- .a or .so; the headers in include/openjpeg-2.5, the directory consumers include.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    otok.cmake{ defines = {
        BUILD_STATIC_LIBS = static, BUILD_CODEC = false, BUILD_JPIP = false, BUILD_JPIP_SERVER = false,
        BUILD_VIEWER = false, BUILD_JAVA = false, BUILD_THIRDPARTY = false, BUILD_TESTING = false, BUILD_DOC = false,
        BUILD_UNIT_TESTS = false, BUILD_LUTS_GENERATOR = false, CMAKE_INSTALL_LIBDIR = "lib",
    } }
    local p = slice.prefix
    return { libraries = { openjp2 = otok.glob(static and "lib/libopenjp2.a" or "lib/libopenjp2.so", p)[1] },
             headers = p .. "/include/openjpeg-2.5" }
end
