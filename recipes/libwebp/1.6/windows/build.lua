-- libwebp's CMake project, the libraries only (no tools, no extras). What it installs: libwebp.lib, libwebpdemux.lib, libwebpmux.lib and
-- libsharpyuv.lib, static libraries or import libraries with their DLLs (MSVC's names carry the prefix lib).
local names = { "webpmux", "webpdemux", "webp", "sharpyuv" }

function build(slice, options, deps)
    local static = slice.linkage == "static"
    otok.cmake{ defines = {
        BUILD_SHARED_LIBS = not static, WEBP_LINK_STATIC = static, WEBP_BUILD_ANIM_UTILS = false, WEBP_BUILD_CWEBP = false,
        WEBP_BUILD_DWEBP = false, WEBP_BUILD_GIF2WEBP = false, WEBP_BUILD_IMG2WEBP = false, WEBP_BUILD_VWEBP = false,
        WEBP_BUILD_WEBPINFO = false, WEBP_BUILD_WEBPMUX = false, WEBP_BUILD_EXTRAS = false, WEBP_BUILD_LIBWEBPMUX = true,
    } }
    local p = slice.prefix
    local libraries = {}
    for _, name in ipairs(names) do
        local link = otok.glob("lib/lib" .. name .. ".lib", p)[1]
        if static then
            libraries[name] = link
        else
            libraries[name] = { link = link, runtime = otok.glob("bin/lib" .. name .. ".dll", p)[1] }
        end
    end
    return { libraries = libraries, headers = p .. "/include" }
end
