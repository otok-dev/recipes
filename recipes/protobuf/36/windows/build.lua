-- protobuf's CMake project, the runtime libraries, static, with the Abseil of deps; in the tool slice (a tool dependency, or a
-- tool a project delivers to its own build) protoc too, with libprotoc and libupb, which its upb generator needs. Nothing is
-- fetched. What it installs: libprotobuf.lib or libprotobuf-lite.lib and libutf8_validity.lib.
function build(slice, options, deps)
    local defines = {
        protobuf_BUILD_TESTS = false, protobuf_BUILD_CONFORMANCE = false, protobuf_BUILD_EXAMPLES = false,
        protobuf_BUILD_PROTOC_BINARIES = slice.is_tool, protobuf_BUILD_LIBPROTOC = slice.is_tool,
        protobuf_BUILD_LIBUPB = slice.is_tool,
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
    }
    local out = { libraries = libraries, headers = p .. "/include" }
    if slice.is_tool then out.programs = { protoc = p .. "/bin/protoc" .. (slice.os == "windows" and ".exe" or "") } end
    return out
end
