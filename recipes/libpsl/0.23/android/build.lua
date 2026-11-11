-- libpsl's meson build, the library only (no tests, no documentation), with the built-in list and no IDNA library. What it
-- installs: libpsl.a, or libpsl.so with its links.
function build(slice, options, deps)
    otok.meson{ options = { runtime = "no", builtin = true, tests = false, docs = false } }
    local p = slice.prefix
    return { libraries = { psl = otok.glob(slice.linkage == "static" and "lib/libpsl.a" or "lib/libpsl.so", p)[1] }, headers = p .. "/include" }
end
