-- FFmpeg's own configure (not autoconf: no --host, its own --cc, --arch, --target-os) and make, out of the tree in
-- slice.build. Nothing is detected on the machine: --disable-autodetect turns off every library configure would find
-- there, the threads too, and what the recipe wants is enabled by name.

local libraries = { "avutil", "avcodec", "avformat", "avfilter", "swscale", "swresample" }

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
    -- the dependencies: zlib by its headers and library (configure checks -lz), dav1d through pkg-config
    local include, lib = {}, {}
    for name, d in pairs(deps) do
        if name ~= "tools" then
            include[#include + 1] = "-I" .. d.include
            for _, dir in ipairs(d.lib_dirs) do lib[#lib + 1] = "-L" .. dir end
        end
    end
    local args = {
        "sh", slice.source .. "/configure",
        "--prefix=" .. slice.prefix,
        "--libdir=" .. slice.prefix .. "/lib",
        "--incdir=" .. slice.prefix .. "/include",
        dynamic and "--enable-shared" or "--disable-shared",
        dynamic and "--disable-static" or "--enable-static",
        "--enable-pic",
        "--disable-programs", "--disable-doc", "--disable-avdevice", "--disable-stripping",
        "--disable-autodetect", "--enable-pthreads", "--enable-zlib",
        -- otok's flags choose the configuration: FFmpeg's -O3 follows them in release, none in debug
        debug and "--disable-optimizations" or "--enable-optimizations",
        debug and "--enable-debug" or "--disable-debug",
        "--cc=" .. t.cc, "--cxx=" .. t.cxx, "--ar=" .. t.ar, "--ranlib=" .. t.ranlib, "--nm=" .. t.nm,
        "--strip=" .. t.strip,
        "--pkg-config=" .. slice.toolchains["pkg-config"],
        "--extra-cflags=" .. joined(t.cflags, include),
        "--extra-cxxflags=" .. joined(t.cxxflags, include),
        "--extra-ldflags=" .. joined(t.ldflags, lib),
    }
    if slice.c_standard then args[#args + 1] = "--stdc=c" .. slice.c_standard end
    if slice.toolchains.nasm then
        args[#args + 1] = "--x86asmexe=" .. slice.toolchains.nasm
    else
        args[#args + 1] = "--disable-x86asm"
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
    -- the libraries find each other beside themselves; written into config.mak, since configure evaluates its
    -- arguments: $$$$ is make's $, as library.mak expands the link's arguments twice, and the backslash keeps it from
    -- the shell of the rule
    if t.rpath ~= "" then
        local mak = slice.build .. "/ffbuild/config.mak"
        local rules, m = otok.read(mak):gsub("\nLDSOFLAGS=", function()
            return "\nLDSOFLAGS=-Wl,-rpath," .. t.rpath:gsub("%$", "\\$$$$") .. " "
        end)
        assert(m == 1, "config.mak has no LDSOFLAGS")
        otok.write(mak, rules)
    end
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
