-- protobuf's CMake project, the runtime libraries only, static, with the Abseil of deps and no protoc (the compiler runs on the
-- build machine: a program that generates code gets it from its own tools). Nothing is fetched. What it installs: libprotobuf.a or libprotobuf-lite.a, libutf8_validity.a and libutf8_range.a.
function build(slice, options, deps)
    local defines = {
        protobuf_BUILD_TESTS = false, protobuf_BUILD_CONFORMANCE = false, protobuf_BUILD_EXAMPLES = false,
        protobuf_BUILD_PROTOC_BINARIES = false, protobuf_BUILD_LIBPROTOC = false, protobuf_BUILD_LIBUPB = false,
        protobuf_BUILD_SHARED_LIBS = false, protobuf_MSVC_STATIC_RUNTIME = false,
        protobuf_LOCAL_DEPENDENCIES_ONLY = true, protobuf_WITH_ZLIB = options.zlib,
        absl_DIR = deps.abseil.prefix .. "/lib/cmake/absl",
    }
    otok.cmake{ defines = defines }
    local p = slice.prefix
    local lite = options.runtime == "lite"
    local libraries = {}
    for _, name in ipairs{ lite and "protobuf-lite" or "protobuf", "utf8_validity", "utf8_range" } do
        libraries[name] = otok.glob("lib/lib" .. name .. ".a", p)[1]
    end
    return { libraries = libraries, headers = p .. "/include" }
end
