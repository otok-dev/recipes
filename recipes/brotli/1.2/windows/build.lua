-- Brotli's CMake project, the libraries only (no command-line tool, no tests). What it installs: brotlicommon.lib,
-- brotlidec.lib and brotlienc.lib, static archives, or import libraries with the DLLs of the same names.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    otok.cmake{ defines = { BROTLI_BUILD_TOOLS = false, BROTLI_DISABLE_TESTS = true } }
    local p = slice.prefix
    local libraries = {}
    for _, name in ipairs{ "brotlienc", "brotlidec", "brotlicommon" } do
        local lib = otok.glob("lib/" .. name .. ".lib", p)[1]
        libraries[name] = static and lib or { link = lib, runtime = otok.glob("bin/" .. name .. ".dll", p)[1] }
    end
    return { libraries = libraries, headers = p .. "/include" }
end
