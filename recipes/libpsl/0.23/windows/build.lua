-- libpsl's meson build, the library only (no tests, no documentation), static, with the built-in list and no IDNA library.
-- What it installs: libpsl.a or psl.lib, whichever the toolchain names a static library (MSVC's: libpsl.a).
function build(slice, options, deps)
    otok.meson{ options = { runtime = "no", builtin = true, tests = false, docs = false } }
    local p = slice.prefix
    local lib = otok.glob("lib/psl.lib", p)[1] or otok.glob("lib/libpsl.a", p)[1]
    return { libraries = { psl = lib }, headers = p .. "/include" }
end
