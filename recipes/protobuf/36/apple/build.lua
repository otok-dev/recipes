-- protobuf's CMake project, the runtime libraries, static, with the Abseil of deps; in the tool slice (a tool dependency, or a
-- tool a project delivers to its own build) protoc too, with libprotoc and libupb, which its upb generator needs. Nothing is
-- fetched. What it installs: libprotobuf.a or libprotobuf-lite.a and libutf8_validity.a (it holds utf8_range as well).
function build(slice, options, deps)
    local defines = {
        protobuf_BUILD_TESTS = false, protobuf_BUILD_CONFORMANCE = false, protobuf_BUILD_EXAMPLES = false,
        protobuf_BUILD_PROTOC_BINARIES = slice.is_tool, protobuf_BUILD_LIBPROTOC = slice.is_tool,
        protobuf_BUILD_LIBUPB = slice.is_tool,
        protobuf_BUILD_SHARED_LIBS = false, protobuf_MSVC_STATIC_RUNTIME = false,
        protobuf_LOCAL_DEPENDENCIES_ONLY = true, protobuf_WITH_ZLIB = options.zlib,
        absl_DIR = deps.abseil.prefix .. "/lib/cmake/absl",
    }
    otok.cmake{ defines = defines }
    local p = slice.prefix
    local lite = options.runtime == "lite"
    local libraries = {}
    for _, name in ipairs{ lite and "protobuf-lite" or "protobuf", "utf8_validity" } do
        libraries[name] = otok.glob("lib/lib" .. name .. ".a", p)[1]
    end
    local out = { libraries = libraries, headers = p .. "/include" }
    if slice.is_tool then out.programs = { protoc = p .. "/bin/protoc" .. (slice.os == "windows" and ".exe" or "") } end
    return out
end
