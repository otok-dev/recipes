-- libwebp's CMake project, the libraries only (no tools, no extras). What it installs: libwebp, libwebpdemux, libwebpmux and
-- libsharpyuv, .a or .so with their links.
local names = { "webpmux", "webpdemux", "webp", "sharpyuv" }

function build(slice, options, deps)
    local static = slice.linkage == "static"
    otok.cmake{ defines = {
        BUILD_SHARED_LIBS = not static, WEBP_LINK_STATIC = static, WEBP_BUILD_ANIM_UTILS = false, WEBP_BUILD_CWEBP = false,
        WEBP_BUILD_DWEBP = false, WEBP_BUILD_GIF2WEBP = false, WEBP_BUILD_IMG2WEBP = false, WEBP_BUILD_VWEBP = false,
        WEBP_BUILD_WEBPINFO = false, WEBP_BUILD_WEBPMUX = false, WEBP_BUILD_EXTRAS = false, WEBP_BUILD_LIBWEBPMUX = true,
        ANDROID_NDK = slice.android.ndk,
    } }
    local p = slice.prefix
    local libraries = {}
    for _, name in ipairs(names) do
        libraries[name] = otok.glob(static and "lib/lib" .. name .. ".a" or "lib/lib" .. name .. ".so", p)[1]
    end
    libraries["cpufeatures-webp"] = otok.glob("lib/libcpufeatures-webp.a", p)[1]
    return { libraries = libraries, headers = p .. "/include" }
end
