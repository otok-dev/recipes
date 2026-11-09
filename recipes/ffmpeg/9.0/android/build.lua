-- FFmpeg's own configure (not autoconf: no --host, its own --cc, --arch, --target-os) and make, out of the tree in
-- slice.build, cross-compiling every slice. Nothing is detected on the machine: --disable-autodetect turns off every
-- library configure would find, the threads too, and what the recipe wants is enabled by name.

local libraries = { "avutil", "avcodec", "avformat", "avfilter", "swscale", "swresample" }

-- FFmpeg's names of the ABIs' architectures, and their CPUs
local arch = { ["arm64-v8a"] = "aarch64", ["armeabi-v7a"] = "arm", x86_64 = "x86_64", x86 = "x86" }
local cpu = { ["armeabi-v7a"] = "armv7-a" }

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
    local args = {
        "sh", slice.source .. "/configure",
        "--prefix=" .. slice.prefix,
        "--libdir=" .. slice.prefix .. "/lib",
        "--incdir=" .. slice.prefix .. "/include",
        dynamic and "--enable-shared" or "--disable-shared",
        dynamic and "--disable-static" or "--enable-static",
        "--enable-pic",
        "--enable-cross-compile", "--target-os=android", "--arch=" .. assert(arch[slice.arch], slice.arch),
        "--disable-programs", "--disable-doc", "--disable-avdevice", "--disable-stripping",
        "--disable-autodetect", "--enable-pthreads", "--enable-zlib", "--enable-jni", "--enable-mediacodec",
        -- otok's flags choose the configuration: FFmpeg's -O3 follows them in release, none in debug
        debug and "--disable-optimizations" or "--enable-optimizations",
        debug and "--enable-debug" or "--disable-debug",
        "--cc=" .. t.cc, "--cxx=" .. t.cxx, "--dep-cc=" .. t.cc,
        "--ar=" .. t.ar, "--ranlib=" .. t.ranlib, "--nm=" .. t.nm, "--strip=" .. t.strip,
        "--pkg-config=" .. slice.toolchains["pkg-config"],
        "--extra-cflags=" .. joined(t.cflags),
        "--extra-cxxflags=" .. joined(t.cxxflags),
        "--extra-ldflags=" .. joined(t.ldflags),
    }
    if cpu[slice.arch] then args[#args + 1] = "--cpu=" .. cpu[slice.arch] end
    if slice.c_standard then args[#args + 1] = "--stdc=c" .. slice.c_standard end
    if slice.toolchains.nasm then
        args[#args + 1] = "--x86asmexe=" .. slice.toolchains.nasm
    elseif slice.arch == "x86" then
        -- the assembly of 32-bit x86, NASM's and inline, is not position-independent (text relocations, which Android
        -- refuses), and the inline one needs more registers than the PIC code leaves; --disable-asm would also make the
        -- architecture "c" and leave out the unaligned accesses, so that avconfig.h would differ between the ABIs
        args[#args + 1] = "--disable-x86asm"
        args[#args + 1] = "--disable-inline-asm"
    end
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
    local result = {}
    for _, name in ipairs(libraries) do
        local file = otok.glob("lib/lib" .. name .. (dynamic and ".so" or ".a"), p)[1]
        assert(file, "FFmpeg installed no lib" .. name)
        result[name] = file
    end
    return { libraries = result, headers = p .. "/include" }
end
