-- HarfBuzz's meson build, harfbuzz, harfbuzz-subset and harfbuzz-raster as the option raster asks: its own Unicode data
-- and OpenType font functions, FreeType's, DirectWrite and GDI with Uniscribe as the options ask, none of GLib, ICU,
-- Cairo, Graphite2 or the vector and GPU libraries, no utilities, tests or documentation. What it installs:
-- libharfbuzz.a and libharfbuzz-subset.a (meson's names of static libraries, with MSVC too), or harfbuzz.lib and
-- harfbuzz-subset.lib with their DLLs, and the same of harfbuzz-raster; the headers in include/harfbuzz/, which
-- consumers include as <hb.h>.

local function feature(on) return on and "enabled" or "disabled" end

-- a library of the prefix: the import library and the DLL (no version in its name with MSVC's ABI), or the static library
local function library(p, name)
    local dll = p .. "/bin/" .. name .. ".dll"
    if otok.exists(dll) then return { link = p .. "/lib/" .. name .. ".lib", runtime = dll } end
    return p .. "/lib/lib" .. name .. ".a"
end

function build(slice, options, deps)
    otok.meson{ options = {
        auto_features = "disabled",
        freetype = feature(options.freetype), directwrite = feature(options.directwrite), gdi = feature(options.gdi),
        subset = "enabled", raster = feature(options.raster), vector = "disabled", gpu = "disabled",
        tests = "disabled", utilities = "disabled", docs = "disabled", introspection = "disabled", benchmark = "disabled",
    } }
    local p = slice.prefix
    local libraries = { harfbuzz = library(p, "harfbuzz"), ["harfbuzz-subset"] = library(p, "harfbuzz-subset") }
    if options.raster then libraries["harfbuzz-raster"] = library(p, "harfbuzz-raster") end
    return {
        libraries = libraries,
        headers = p .. "/include/harfbuzz",
    }
end
