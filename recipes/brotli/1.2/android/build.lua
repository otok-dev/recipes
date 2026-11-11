-- Brotli's CMake project, the libraries only (no command-line tool, no tests). What it installs: libbrotlicommon, libbrotlidec
-- and libbrotlienc as .a, or as .so with their links.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    otok.cmake{ defines = { BROTLI_BUILD_TOOLS = false, BROTLI_DISABLE_TESTS = true } }
    local p = slice.prefix
    local libraries = {}
    for _, name in ipairs{ "brotlienc", "brotlidec", "brotlicommon" } do
        libraries[name] = otok.glob("lib/lib" .. name .. (static and ".a" or ".so"), p)[1]
    end
    return { libraries = libraries, headers = p .. "/include" }
end
