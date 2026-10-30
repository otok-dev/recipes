-- libpng's CMake project, the library only. What it installs: libpng16.a, libpng16.so with its links,
-- libpng16.dylib, or with MSVC libpng16_static.lib (static) or libpng16.lib with libpng16.dll, with the suffix d in
-- debug; the headers in include/ and include/libpng16/.

-- libpng installs libpng.pc only where it is not MSVC: one of the same contents, with the library's file name, so
-- that pkg-config's consumers (meson) find it; the prefix is the file's (pkgconf's ${pcfiledir})
local function write_pkg_config(p, lib)
    local name = lib:match("([^/]+)%.lib$")
    if not name or otok.exists(p .. "/lib/pkgconfig/libpng.pc") then return end
    local text = table.concat({
        "prefix=${pcfiledir}/../..",
        "exec_prefix=${prefix}",
        "libdir=${prefix}/lib",
        "includedir=${prefix}/include/libpng16",
        "",
        "Name: libpng",
        "Description: Loads and saves PNG files",
        "Version: 1.6.47",
        "Requires.private: zlib",
        "Libs: -L${libdir} -l" .. name,
        "Cflags: -I${includedir}",
        "",
    }, "\n")
    for _, file in ipairs{ "libpng.pc", "libpng16.pc" } do otok.write(p .. "/lib/pkgconfig/" .. file, text) end
end

function build(slice, options, deps)
    local static = slice.linkage == "static"
    -- FindZLIB knows the static library of MSVC's zlib (zs.lib) only when told to look for one. For Windows libpng
    -- generates no libpng.pc and libpng-config, but installs them unless the build machine is Windows (CMAKE_HOST_WIN32):
    -- not those files, nor the manual pages (this recipe writes the .pc)
    local windows = slice.triple:find("windows") ~= nil
    otok.cmake{ defines = { PNG_SHARED = not static, PNG_STATIC = static, PNG_TESTS = false, PNG_TOOLS = false, PNG_FRAMEWORK = false,
        ZLIB_USE_STATIC_LIBS = deps.zlib.linkage == "static", SKIP_INSTALL_FILES = windows } }
    local p = slice.prefix
    local dll = otok.glob("bin/libpng16*.dll", p)[1]
    if dll then
        local link = otok.glob("lib/libpng16*.lib", p)[1]
        write_pkg_config(p, link)
        return { libraries = { png16 = { link = link, runtime = dll } }, headers = p .. "/include" }
    end
    local lib = otok.glob("lib/libpng16.so", p)[1] or otok.glob("lib/libpng16.dylib", p)[1] or otok.glob("lib/libpng16.a", p)[1]
        or otok.glob("lib/libpng16_static*.lib", p)[1]
    write_pkg_config(p, lib)
    return { libraries = { png16 = lib }, headers = p .. "/include" }
end
