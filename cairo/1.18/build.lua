-- Cairo's meson build (of the source, or of the resource d2d), the library only, with the Windows backends: Win32
-- surface and font, DirectWrite, FreeType, PNG, PDF, PS, SVG, script, tee.
-- What it installs with MSVC: libcairo.a (static) or cairo.lib with cairo-2.dll; the headers in include/cairo/.
local function windows(slice)
    return slice.triple:find("windows") ~= nil
end

function build(slice, options, deps)
    if not windows(slice) then
        error("this recipe builds Cairo for Windows only")
    end
    local meson_options = {
        dwrite = "enabled", freetype = "enabled", fontconfig = "disabled", png = "enabled", zlib = "enabled",
        tee = "enabled", quartz = "disabled", xcb = "disabled", xlib = "disabled", tests = "disabled", lzo = "disabled",
        ["gtk2-utils"] = "disabled", glib = "disabled", spectre = "disabled", ["symbol-lookup"] = "disabled",
        gtk_doc = false,
    }
    -- the option d2d exists only in the fork's meson build
    if options.d2d then
        meson_options.d2d = "enabled"
    end
    otok.meson{
        source = options.d2d and slice.resources.d2d or slice.source,
        options = meson_options,
    }
    local p = slice.prefix
    local dll = otok.glob("bin/cairo*.dll", p)[1]
    if dll then
        return { libraries = { cairo = { link = otok.glob("lib/cairo.lib", p)[1], runtime = dll } }, headers = p .. "/include/cairo" }
    end
    local lib = otok.glob("lib/libcairo.a", p)[1] or otok.glob("lib/cairo.lib", p)[1]
    return { libraries = { cairo = lib }, headers = p .. "/include/cairo" }
end
