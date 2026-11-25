-- Cairo's meson build (of the source, or of the resource d2d), the library only, with the Windows backends: Win32
-- surface and font, DirectWrite, FreeType, PNG, PDF, PS, SVG, script, tee.
-- What it installs: libcairo.a (static) or cairo.lib with cairo-2.dll; the headers in include/cairo/.

-- `from` in the file replaced by `to`, which must be there
local function replace(file, from, to)
    local text = otok.read(file)
    local at, last = text:find(from, 1, true)
    assert(at, file .. " no longer has: " .. from)
    otok.write(file, text:sub(1, at - 1) .. to .. text:sub(last + 1))
end

-- The tree to build. With clang-cl the script interpreter's C99 inline functions have no external definition, which
-- MSVC emits anyway: it is not built (it is not this recipe's library). (Cairo's meson build leaves clang-cl's
-- __uint128_t aside itself since 1.18.6: its division needs compiler-rt's __udivti3, which MSVC's runtime lacks.)
-- The resource d2d is read-only in the cache: a copy.
local function source_of(slice, options)
    local source = options.d2d and slice.resources.d2d or slice.source
    if not slice.toolchain.cc:find("clang%-cl") then return source end
    if options.d2d then
        otok.copy(source, slice.build .. "/d2d")
        source = slice.build .. "/d2d"
    end
    replace(source .. "/util/meson.build", "if conf.get('CAIRO_HAS_INTERPRETER', 0) == 1", "if false")
    return source
end

function build(slice, options, deps)
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
    local source = source_of(slice, options)
    otok.meson{
        source = source,
        -- beside the copy of d2d, not around it
        build = source:find(slice.build, 1, true) and slice.build .. "/build" or nil,
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
