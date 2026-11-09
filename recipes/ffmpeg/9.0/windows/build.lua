-- FFmpeg's own configure (not autoconf: no --host, its own --toolchain, --arch, --target-os) and make, out of the tree
-- in slice.build, with MSVC (--toolchain=msvc: cl.exe, lib.exe, link.exe through FFmpeg's mslink) under the MSYS2 of
-- the make recipe, whose sh runs configure. Nothing is detected on the machine: --disable-autodetect turns off every
-- library configure would find, the threads too, and what the recipe wants is enabled by name.

local libraries = { "avutil", "avcodec", "avformat", "avfilter", "swscale", "swresample" }

-- A path as the programs of MSYS2 name it: C:/x is /c/x.
local function msys(path)
    return (path:gsub("^(%a):/", function(drive) return "/" .. drive:lower() .. "/" end))
end

-- MSVC's options with '-': MSYS2 takes /O2 for a path and turns it into C:/…/O2 for native programs
local function joined(flags)
    local all = {}
    for _, f in ipairs(flags) do all[#all + 1] = (f:gsub("^/", "-")) end
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

-- PATH with MSYS2's programs after the toolchain's (Visual Studio's link.exe, not coreutils' link) and before Windows'
-- own (whose bash.exe is WSL's)
local function msys_path_variable(slice, msys_bin)
    local path = slice.toolchain.env.PATH or slice.toolchain.env.Path or ""
    local root = (slice.toolchain.env.SystemRoot or slice.toolchain.env.SYSTEMROOT or "C:\\Windows"):lower():gsub("\\", "/")
    local dirs, at = {}, nil
    for dir in path:gmatch("[^;]+") do
        local lower = dir:lower():gsub("\\", "/")
        if not at and (lower == root or lower:sub(1, #root + 1) == root .. "/") then
            at = #dirs + 1
            dirs[at] = msys_bin
        end
        dirs[#dirs + 1] = dir
    end
    if not at then dirs[#dirs + 1] = msys_bin end
    return table.concat(dirs, ";")
end

function build(slice, options, deps)
    local t = slice.toolchain
    local dynamic = slice.linkage == "dynamic"
    local debug = slice.configuration == "debug"
    -- VERSION, as the release archive has it (without it, and without .git, version.sh takes RELEASE)
    otok.write(slice.source .. "/VERSION", otok.read(slice.source .. "/RELEASE"))
    local make = slice.toolchains.make
    local msys_bin = make:match("^(.*)/[^/]*$")
    -- the dependencies under the names FFmpeg's flags for MSVC give them: -lz is zlib.lib, -ldav1d dav1d.lib (meson
    -- names a static dav1d libdav1d.a)
    local libs = slice.build .. "/otok-deps"
    local include = {}
    for name, d in pairs(deps) do
        if name ~= "tools" then include[#include + 1] = "-I" .. d.include end
    end
    otok.copy(deps.zlib.libraries.z, libs .. "/zlib.lib")
    if options.dav1d then otok.copy(deps.dav1d.libraries.dav1d, libs .. "/dav1d.lib") end
    local args = {
        (make:gsub("make%.exe$", "sh.exe")), msys(slice.source) .. "/configure",
        "--prefix=" .. msys(slice.prefix),
        "--libdir=" .. msys(slice.prefix) .. "/lib",
        "--incdir=" .. msys(slice.prefix) .. "/include",
        dynamic and "--enable-shared" or "--disable-shared",
        dynamic and "--disable-static" or "--enable-static",
        "--toolchain=msvc", "--target-os=win64", "--arch=x86_64",
        "--disable-programs", "--disable-doc", "--disable-avdevice", "--disable-stripping",
        "--disable-autodetect", "--enable-w32threads", "--enable-zlib",
        "--enable-d3d11va", "--enable-d3d12va", "--enable-dxva2",
        -- otok's flags choose the configuration: FFmpeg's -O2 follows them in release, none in debug
        debug and "--disable-optimizations" or "--enable-optimizations",
        debug and "--enable-debug" or "--disable-debug",
        "--pkg-config=" .. msys(slice.toolchains["pkg-config"]),
        "--x86asmexe=" .. msys(slice.toolchains.nasm),
        "--extra-cflags=" .. joined(t.cflags) .. " " .. table.concat(include, " "),
        "--extra-cxxflags=" .. joined(t.cxxflags) .. " " .. table.concat(include, " "),
        -- link.exe's options, which configure passes on as they are
        "--extra-ldflags=" .. joined(t.ldflags) .. " -libpath:" .. libs,
    }
    if slice.c_standard then args[#args + 1] = "--stdc=c" .. slice.c_standard end
    if options.dav1d then args[#args + 1] = "--enable-libdav1d" end
    -- dav1d's pkg-config file, of the dependency's prefix, for pkgconf, a Windows program
    local pc = {}
    for name, d in pairs(deps) do
        if name ~= "tools" then pc[#pc + 1] = d.prefix .. "/lib/pkgconfig" end
    end
    local env = {
        PATH = msys_path_variable(slice, msys_bin), Path = false,
        PKG_CONFIG_PATH = table.concat(pc, ";"),
        CC = false, CXX = false, CFLAGS = false, CXXFLAGS = false, CPPFLAGS = false, LDFLAGS = false,
    }
    otok.run(args, { cwd = slice.build, env = env })
    local config = slice.build .. "/config.h"
    local text, n = otok.read(config):gsub('#define FFMPEG_CONFIGURATION "[^\n]*"',
        function() return '#define FFMPEG_CONFIGURATION "' .. configuration(args) .. '"' end)
    assert(n == 1, "config.h has no FFMPEG_CONFIGURATION")
    otok.write(config, text)
    otok.make{ "install", cwd = slice.build, env = env }

    -- lib/avcodec.lib, static, or bin/avcodec.lib, the import library of bin/avcodec-63.dll beside it
    local p = slice.prefix
    local result = {}
    for _, name in ipairs(libraries) do
        local lib = otok.glob((dynamic and "bin/" or "lib/") .. name .. ".lib", p)[1]
        assert(lib, "FFmpeg installed no " .. name .. ".lib")
        if dynamic then
            local dll = otok.glob("bin/" .. name .. "-*.dll", p)[1]
            assert(dll, "FFmpeg installed no " .. name .. "-*.dll")
            result[name] = { link = lib, runtime = dll }
        else
            result[name] = lib
        end
    end
    return { libraries = result, headers = p .. "/include" }
end
