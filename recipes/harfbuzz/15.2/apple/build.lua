-- HarfBuzz's meson build, libharfbuzz and libharfbuzz-subset only: its own Unicode data and OpenType font functions,
-- CoreText's as the option coretext asks, none of FreeType, GLib, ICU, Cairo, Graphite2 or the raster, vector and GPU
-- libraries, no utilities, tests or documentation. What it installs: libharfbuzz.a and libharfbuzz-subset.a, or the
-- .dylib with their links; the headers in include/harfbuzz/, which consumers include as <hb.h>.
function build(slice, options, deps)
    otok.meson{ options = {
        auto_features = "disabled",
        coretext = options.coretext and "enabled" or "disabled",
        subset = "enabled", raster = "disabled", vector = "disabled", gpu = "disabled",
        tests = "disabled", utilities = "disabled", docs = "disabled", introspection = "disabled", benchmark = "disabled",
    } }
    local p = slice.prefix
    local ext = slice.linkage == "static" and ".a" or ".dylib"
    return {
        libraries = { harfbuzz = p .. "/lib/libharfbuzz" .. ext, ["harfbuzz-subset"] = p .. "/lib/libharfbuzz-subset" .. ext },
        headers = p .. "/include/harfbuzz",
    }
end
