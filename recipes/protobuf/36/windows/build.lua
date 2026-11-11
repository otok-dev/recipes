-- protobuf's CMake project, the runtime libraries only, static, with the Abseil of deps and no protoc (the compiler runs on the
-- build machine: a program that generates code gets it from its own tools). Nothing is fetched. What it installs: libprotobuf.lib or libprotobuf-lite.lib, libutf8_validity.lib and libutf8_range.lib.
function build(slice, options, deps)
    local defines = {
        protobuf_BUILD_TESTS = false, protobuf_BUILD_CONFORMANCE = false, protobuf_BUILD_EXAMPLES = false,
        protobuf_BUILD_PROTOC_BINARIES = false, protobuf_BUILD_LIBPROTOC = false, protobuf_BUILD_LIBUPB = false,
        protobuf_BUILD_SHARED_LIBS = false, protobuf_MSVC_STATIC_RUNTIME = false,
        protobuf_LOCAL_DEPENDENCIES_ONLY = true, protobuf_WITH_ZLIB = options.zlib,
        absl_DIR = deps.abseil.prefix .. "/lib/cmake/absl",
    }
    if options.zlib then
        local z = deps.zlib
        defines.ZLIB_USE_STATIC_LIBS = z.linkage == "static"
        defines.ZLIB_INCLUDE_DIR = z.include
        defines.ZLIB_LIBRARY = z.libraries.z
    end
    otok.cmake{ defines = defines }
    local p = slice.prefix
    local lite = options.runtime == "lite"
    local libraries = {
        [lite and "protobuf-lite" or "protobuf"] = otok.glob(lite and "lib/libprotobuf-lite.lib" or "lib/libprotobuf.lib", p)[1],
        utf8_validity = otok.glob("lib/libutf8_validity.lib", p)[1],
        utf8_range = otok.glob("lib/libutf8_range.lib", p)[1],
    }
    return { libraries = libraries, headers = p .. "/include" }
end
