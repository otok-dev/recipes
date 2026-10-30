-- ICU's own autotools build. build_tools builds ICU for the build machine once; its tools (icupkg,
-- pkgdata, genccode, …) package the data of every slice (--with-cross-build), which therefore builds
-- no tools of its own.

local function windows(slice)
    return slice.triple:find("windows") ~= nil
end

-- `filtered`: the data built from its sources with the project's filter, else the prebuilt data
local function configure(slice, filtered)
    if filtered then
        -- the data sources, which the release archive leaves out; without data/in/icudt79l.dat
        -- configure has the data built by ICU's Python build tool
        otok.remove(slice.source .. "/source/data")
        otok.copy(slice.resources.data_sources, slice.source .. "/source/data")
    else
        otok.copy(slice.resources.data .. "/icudt79l.dat", slice.source .. "/source/data/in/icudt79l.dat")
    end
    return slice.source .. "/source/configure"
end

local common = { "--disable-extras", "--disable-tests", "--disable-samples", "--disable-dyload" }

-- with a filter: ICU's Python build tool builds the data as it says
local function data_env(slice, filter)
    if not filter then return {} end
    return { ICU_DATA_FILTER_FILE = filter, PYTHON = slice.toolchains.python }
end

-- MSVC through MSYS2 (runConfigureICU MSYS/MSVC): ICU knows it as a mingw host with a compiler other than gcc
local function msvc(slice, args, env)
    args[#args + 1] = "--build=x86_64-pc-mingw64"
    args[#args + 1] = "--host=x86_64-pc-mingw64"
    -- by name, from the PATH of Visual Studio's environment: autoconf cannot run a compiler whose path has spaces
    env.CC = "cl"
    env.CXX = "cl"
    env.AR = false
    env.RANLIB = false
    -- MSVC's options with '-': MSYS2 takes /O2 for a path and turns it into C:/…/O2 for native programs
    for _, name in ipairs{ "CFLAGS", "CXXFLAGS", "LDFLAGS" } do
        local flags = {}
        local from = name == "CFLAGS" and slice.toolchain.cflags or name == "CXXFLAGS" and slice.toolchain.cxxflags or slice.toolchain.ldflags
        for _, f in ipairs(from) do flags[#flags + 1] = (f:gsub("^/", "-")) end
        env[name] = table.concat(flags, " ")
    end
    -- ICU needs C++17, which it asks for gcc and clang only; a project's standard is in the flags already
    if not slice.cxx_standard then env.CXXFLAGS = env.CXXFLAGS .. " -std:c++20" end
end

function build_tools(slice, options, deps)
    -- the tools, built with the data the slices have: the prebuilt data is not fetched with a filter
    local filter = options["data-filter"]
    local args = { table.unpack(common) }
    local env = data_env(slice, filter)
    if windows(slice) then msvc(slice, args, env) end
    otok.autotools{ configure = configure(slice, filter), args = args, cwd = slice.build, targets = { "all" }, env = env }
    -- what a cross build reads from the build tree it is given: the tools and their settings
    otok.copy(slice.build .. "/bin", slice.prefix .. "/bin")
    for _, f in ipairs{ "icucross.mk", "icucross.inc" } do
        otok.copy(slice.build .. "/config/" .. f, slice.prefix .. "/config/" .. f)
    end
end

-- macOS dynamic libraries name themselves and each other by their file names: @rpath/ instead, so
-- the consumer's executable chooses where they are
local function fix_install_names(slice)
    local libs = {}
    for _, path in ipairs(otok.glob("lib/*.dylib", slice.prefix)) do
        local name = path:match("/(libicu%w+%.%d+%.dylib)$")
        if name then libs[#libs + 1] = name end
    end
    for _, name in ipairs(libs) do
        local argv = { "install_name_tool", "-id", "@rpath/" .. name }
        for _, other in ipairs(libs) do
            for _, old in ipairs{ other, slice.prefix .. "/lib/" .. other } do
                argv[#argv + 1] = "-change"
                argv[#argv + 1] = old
                argv[#argv + 1] = "@rpath/" .. other
            end
        end
        argv[#argv + 1] = slice.prefix .. "/lib/" .. name
        otok.run(argv)
    end
end

function build(slice, options, deps)
    local dynamic = slice.linkage == "dynamic"
    if dynamic and slice.os == "android" then
        -- its makefiles name shared objects with versions (libicuuc.so.79), which Android does not load
        error("ICU builds static libraries only for Android: its shared objects carry versions in their names, which Android does not load")
    end
    local filter = options["data-filter"]
    if filter and options.data == "none" then
        error("data-filter needs data = \"static\" or \"file\": with \"none\" there is no data to filter")
    end
    -- static and library: the data in libicudata; archive: icudt79l.dat, and the stub libicudata
    local packaging = options.data ~= "static" and "archive" or dynamic and "library" or "static"
    local args = { "--with-cross-build=" .. slice.tools.prefix, "--disable-tools", "--with-data-packaging=" .. packaging }
    for _, a in ipairs(common) do args[#args + 1] = a end
    if options["no-renaming"] then args[#args + 1] = "--disable-renaming" end
    local env = data_env(slice, filter)
    local debug = slice.configuration == "debug"
    if windows(slice) then
        msvc(slice, args, env)
        -- ICU's debug libraries: the suffix d (icuucd.lib, icuuc79d.dll) and its own assertions
        if debug then
            args[#args + 1] = "--enable-debug"
            args[#args + 1] = "--disable-release"
        end
    end
    otok.autotools{ configure = configure(slice, filter), args = args, cwd = slice.build, env = env }
    if windows(slice) and dynamic and not filter then
        -- the version resource of the data DLL waits for out/tmp/dirs.timestamp, which only the build of the data
        -- from its sources makes
        otok.write(slice.build .. "/data/out/tmp/dirs.timestamp", "")
    end
    -- without tools ICU builds the data only when cross-compiling, which a slice for the build machine
    -- is not: it would install the stub; the data's Makefile takes the tools of --with-cross-build
    otok.make{ "install", cwd = slice.build .. "/data", env = env }

    local p = slice.prefix
    local libraries = {}
    if windows(slice) then
        -- MSVC's names: icuuc.lib with icuuc79.dll (icuucd.lib with icuucd79.dll in debug), the static sicuuc.lib;
        -- i18n is in and the data dt. The DLLs are in lib/, also without the version, which nothing imports.
        local suffix = debug and "d" or ""
        for name, stub in pairs{ uc = "uc", i18n = "in", io = "io", data = "dt" } do
            if dynamic then
                local dll = p .. "/lib/icu" .. stub .. suffix .. "79.dll"
                assert(otok.exists(dll), "ICU installed no " .. dll)
                libraries[name] = { link = p .. "/lib/icu" .. stub .. suffix .. ".lib", runtime = dll }
            else
                libraries[name] = p .. "/lib/sicu" .. stub .. suffix .. ".lib"
            end
        end
    else
        for _, name in ipairs{ "uc", "i18n", "io", "data" } do
            local base = p .. "/lib/libicu" .. name
            libraries[name] = otok.exists(base .. ".so") and base .. ".so" or otok.exists(base .. ".dylib") and base .. ".dylib" or base .. ".a"
        end
    end
    if dynamic and slice.triple:find("darwin") then fix_install_names(slice) end

    -- the C API, which Swift and Objective-C use; the C++ API is for C++ code including the headers
    local module = { "module CICU {" }
    -- the defines of the product (recipe.toml), which otok writes beside the module map
    if options["no-renaming"] then module[#module + 1] = '    header "otok_defines.h"' end
    for _, h in ipairs{ "uversion", "utypes", "putil", "uclean", "uchar", "ustring", "uloc", "ucol", "ubrk", "unorm2", "ucnv", "ucasemap",
            "utrans", "udat", "unum", "ucal", "uregex", "uidna", "uspoof", "ustdio" } do
        module[#module + 1] = '    header "../unicode/' .. h .. '.h"'
    end
    module[#module + 1] = "    export *\n}\n"
    otok.write(p .. "/module.modulemap", table.concat(module, "\n"))
    local data = nil
    if options.data == "file" then
        -- share/icud/ for ICU's debug build
        data = { ["icudt79l.dat"] = p .. "/share/icu" .. (debug and windows(slice) and "d" or "") .. "/79.1/icudt79l.dat" }
    end
    return { libraries = libraries, headers = p .. "/include", module_map = p .. "/module.modulemap", data = data }
end
