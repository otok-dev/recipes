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

function build_tools(slice, options, deps)
    -- the tools, built with the data the slices have: the prebuilt data is not fetched with a filter
    local filter = options["data-filter"]
    local args = { table.unpack(common) }
    if windows(slice) then
        -- MSVC through MSYS2 (runConfigureICU MSYS/MSVC): ICU knows it as a mingw host with a compiler other than gcc
        args[#args + 1] = "--build=x86_64-pc-mingw64"
        args[#args + 1] = "--host=x86_64-pc-mingw64"
    end
    local env = data_env(slice, filter)
    if windows(slice) then
        -- by name, from the PATH of Visual Studio's environment: autoconf cannot run a compiler whose path has spaces
        env.CC = "cl"
        env.CXX = "cl"
        env.AR = false
        env.RANLIB = false
        -- MSVC's options with '-': MSYS2 takes /O2 for a path and turns it into C:/…/O2 for native programs
        for _, name in ipairs{ "CFLAGS", "CXXFLAGS" } do
            local flags = {}
            for _, f in ipairs(name == "CFLAGS" and slice.toolchain.cflags or slice.toolchain.cxxflags) do flags[#flags + 1] = (f:gsub("^/", "-")) end
            env[name] = table.concat(flags, " ")
        end
        -- ICU needs C++17, which it asks for gcc and clang only
        env.CXXFLAGS = env.CXXFLAGS .. " -std:c++20"
    end
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
    if windows(slice) then
        -- its tools build here (build_tools), for the slices of other targets
        error("ICU builds no libraries for Windows yet: on Windows this recipe builds only its tools, for Android")
    end
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
    otok.autotools{ configure = configure(slice, filter), args = args, cwd = slice.build, env = env }
    -- without tools ICU builds the data only when cross-compiling, which a slice for the build machine
    -- is not: it would install the stub; the data's Makefile takes the tools of --with-cross-build
    otok.make{ "install", cwd = slice.build .. "/data", env = env }

    local p = slice.prefix
    local libraries = {}
    for _, name in ipairs{ "uc", "i18n", "io", "data" } do
        local base = p .. "/lib/libicu" .. name
        libraries[name] = otok.exists(base .. ".so") and base .. ".so" or otok.exists(base .. ".dylib") and base .. ".dylib" or base .. ".a"
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
        data = { ["icudt79l.dat"] = p .. "/share/icu/79.1/icudt79l.dat" }
    end
    return { libraries = libraries, headers = p .. "/include", module_map = p .. "/module.modulemap", data = data }
end
