-- Pixman's meson build, the library only. What it installs: libpixman-1.a, libpixman-1.so with its links,
-- libpixman-1.dylib, or with MSVC libpixman-1.a (static) or pixman-1.lib with pixman-1-0.dll; the header in
-- include/pixman-1/.
function build(slice, options, deps)
    otok.meson{ options = { tests = "disabled", demos = "disabled", gtk = "disabled", libpng = "disabled", openmp = "disabled" } }
    local p = slice.prefix
    local dll = otok.glob("bin/*pixman-1*.dll", p)[1]
    if dll then
        return { libraries = { ["pixman-1"] = { link = otok.glob("lib/pixman-1.lib", p)[1], runtime = dll } }, headers = p .. "/include" }
    end
    local lib = otok.glob("lib/libpixman-1.so", p)[1] or otok.glob("lib/libpixman-1.dylib", p)[1] or otok.glob("lib/libpixman-1.a", p)[1]
        or otok.glob("lib/pixman-1.lib", p)[1]
    return { libraries = { ["pixman-1"] = lib }, headers = p .. "/include" }
end
