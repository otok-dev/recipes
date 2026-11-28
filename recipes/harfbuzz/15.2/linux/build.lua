-- HarfBuzz's meson build, libharfbuzz, libharfbuzz-subset and libharfbuzz-raster as the option raster asks: its own
-- Unicode data and OpenType font functions, FreeType's as the option freetype asks, none of GLib, ICU, Cairo, Graphite2
-- or the vector and GPU libraries, no utilities, tests or documentation. What it installs: libharfbuzz.a and
-- libharfbuzz-subset.a, or the .so with their links, and the same of harfbuzz-raster; the headers in include/harfbuzz/,
-- which consumers include as <hb.h>.
function build(slice, options, deps)
    otok.meson{ options = {
        auto_features = "disabled",
        freetype = options.freetype and "enabled" or "disabled",
        subset = "enabled", raster = options.raster and "enabled" or "disabled", vector = "disabled", gpu = "disabled",
        tests = "disabled", utilities = "disabled", docs = "disabled", introspection = "disabled", benchmark = "disabled",
    } }
    local p = slice.prefix
    local ext = slice.linkage == "static" and ".a" or ".so"
    local libraries = { harfbuzz = p .. "/lib/libharfbuzz" .. ext, ["harfbuzz-subset"] = p .. "/lib/libharfbuzz-subset" .. ext }
    if options.raster then libraries["harfbuzz-raster"] = p .. "/lib/libharfbuzz-raster" .. ext end
    return {
        libraries = libraries,
        headers = p .. "/include/harfbuzz",
    }
end
