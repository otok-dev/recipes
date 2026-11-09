-- FFmpeg's own configure (not autoconf: no --host, its own --cc, --arch, --target-os) and make, out of the tree in
-- slice.build, cross-compiling every slice. Nothing is detected on the machine: --disable-autodetect turns off every
-- library configure would find, the threads too, and what the recipe wants is enabled by name.

local libraries = { "avutil", "avcodec", "avformat", "avfilter", "swscale", "swresample" }

-- the installed headers of the acceleration of other platforms
local foreign_headers = {
    "libavcodec/d3d11va.h", "libavcodec/dxva2.h", "libavcodec/jni.h", "libavcodec/mediacodec.h", "libavcodec/qsv.h",
    "libavcodec/vdpau.h",
    "libavutil/hwcontext_amf.h", "libavutil/hwcontext_cuda.h", "libavutil/hwcontext_d3d11va.h",
    "libavutil/hwcontext_d3d12va.h", "libavutil/hwcontext_drm.h", "libavutil/hwcontext_dxva2.h",
    "libavutil/hwcontext_mediacodec.h", "libavutil/hwcontext_oh.h", "libavutil/hwcontext_opencl.h",
    "libavutil/hwcontext_qsv.h", "libavutil/hwcontext_vaapi.h", "libavutil/hwcontext_vdpau.h",
    "libavutil/hwcontext_vulkan.h",
}

-- FFmpeg's names of the architectures
local arch = { arm64 = "aarch64", arm64e = "aarch64", x86_64 = "x86_64" }

-- the flags as one argument of configure
local function joined(flags, extra)
    local all = {}
    for _, f in ipairs(flags) do all[#all + 1] = f end
    for _, f in ipairs(extra or {}) do all[#all + 1] = f end
    return table.concat(all, " ")
end

-- What av*_configuration() tell: the arguments of configure without the paths of this build, which would make the
-- libraries differ from one build to the next and carry the machine's directories
local function configuration(args)
    local shown = {}
    for i = 3, #args do
        if not args[i]:find("[/\\]") then shown[#shown + 1] = args[i] end
    end
    return table.concat(shown, " ")
end

function build(slice, options, deps)
    local t = slice.toolchain
    local dynamic = slice.linkage == "dynamic"
    local debug = slice.configuration == "debug"
    -- VERSION, as the release archive has it (without it, and without .git, version.sh takes RELEASE)
    otok.write(slice.source .. "/VERSION", otok.read(slice.source .. "/RELEASE"))
    -- the macOS SDK of the Xcode of the slice's SDK
    local macos_sdk = slice.apple.sdk_path:gsub("/Platforms/[^/]+%.platform/Developer/SDKs/[^/]+$",
        "/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk")
    local args = {
        "sh", slice.source .. "/configure",
        "--prefix=" .. slice.prefix,
        "--libdir=" .. slice.prefix .. "/lib",
        "--incdir=" .. slice.prefix .. "/include",
        dynamic and "--enable-shared" or "--disable-shared",
        dynamic and "--disable-static" or "--enable-static",
        -- the dynamic libraries as the consumer's executable finds them
        "--install-name-dir=@rpath",
        "--enable-cross-compile", "--target-os=darwin", "--arch=" .. assert(arch[slice.arch], slice.arch),
        "--sysroot=" .. slice.apple.sdk_path,
        "--disable-programs", "--disable-doc", "--disable-avdevice", "--disable-stripping",
        "--disable-autodetect", "--enable-pthreads", "--enable-zlib",
        "--enable-videotoolbox", "--enable-audiotoolbox",
        -- otok's flags choose the configuration: FFmpeg's -O3 follows them in release, none in debug
        debug and "--disable-optimizations" or "--enable-optimizations",
        debug and "--enable-debug" or "--disable-debug",
        "--cc=" .. t.cc, "--cxx=" .. t.cxx, "--objcc=" .. t.cc, "--dep-cc=" .. t.cc,
        "--ar=" .. t.ar, "--ranlib=" .. t.ranlib, "--nm=" .. t.nm, "--strip=" .. t.strip,
        "--pkg-config=" .. slice.toolchains["pkg-config"],
        "--extra-cflags=" .. joined(t.cflags),
        "--extra-objcflags=" .. joined(t.cflags),
        "--extra-cxxflags=" .. joined(t.cxxflags),
        "--extra-ldflags=" .. joined(t.ldflags),
        -- the programs the build runs (libswscale's ops_asmgen) are the Mac's: Xcode's clang with the macOS SDK, whose
        -- version flag wins over the deployment variables of the slice's environment
        "--host-cc=" .. t.cc,
        "--host-cflags=-isysroot " .. macos_sdk .. " -mmacosx-version-min=11.0",
        "--host-ldflags=-isysroot " .. macos_sdk .. " -mmacosx-version-min=11.0",
    }
    if slice.c_standard then args[#args + 1] = "--stdc=c" .. slice.c_standard end
    if slice.toolchains.nasm then args[#args + 1] = "--x86asmexe=" .. slice.toolchains.nasm end
    if options.dav1d then args[#args + 1] = "--enable-libdav1d" end
    -- dav1d's pkg-config file, of the dependency's prefix
    local pc = {}
    for name, d in pairs(deps) do
        if name ~= "tools" then pc[#pc + 1] = d.prefix .. "/lib/pkgconfig" end
    end
    otok.run(args, { cwd = slice.build, env = {
        PKG_CONFIG_PATH = table.concat(pc, ":"),
        CFLAGS = false, CXXFLAGS = false, CPPFLAGS = false, LDFLAGS = false,
    } })
    local config = slice.build .. "/config.h"
    local text, n = otok.read(config):gsub('#define FFMPEG_CONFIGURATION "[^\n]*"',
        function() return '#define FFMPEG_CONFIGURATION "' .. configuration(args) .. '"' end)
    assert(n == 1, "config.h has no FFMPEG_CONFIGURATION")
    otok.write(config, text)
    otok.make{ "install", cwd = slice.build }

    local p = slice.prefix
    -- FFmpeg installs the headers of every platform's acceleration; those of others than Apple's include what the
    -- SDKs do not have (d3d11.h, va/va.h), and the Clang module of the product takes every header
    for _, header in ipairs(foreign_headers) do otok.remove(p .. "/include/" .. header) end
    local result = {}
    for _, name in ipairs(libraries) do
        local file = otok.glob("lib/lib" .. name .. (dynamic and ".dylib" or ".a"), p)[1]
        assert(file, "FFmpeg installed no lib" .. name)
        result[name] = file
    end
    return { libraries = result, headers = p .. "/include" }
end
