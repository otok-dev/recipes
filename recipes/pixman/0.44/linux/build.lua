-- Pixman's meson build, the library only. What it installs: libpixman-1.a, or libpixman-1.so with its
-- links; the header in include/pixman-1/.
function build(slice, options, deps)
    otok.meson{ options = { tests = "disabled", demos = "disabled", gtk = "disabled", libpng = "disabled", openmp = "disabled" } }
    local p = slice.prefix
    local lib = otok.glob(slice.linkage == "static" and "lib/libpixman-1.a" or "lib/libpixman-1.so", p)[1]
    return { libraries = { ["pixman-1"] = lib }, headers = p .. "/include" }
end
