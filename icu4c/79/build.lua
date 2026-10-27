-- ICU's own autotools build. build_tools builds ICU for the build machine once; its tools (icupkg,
-- pkgdata, genccode, …) package the data of every slice (--with-cross-build), which therefore builds
-- no tools of its own.

local function configure(slice)
    if slice.triple:find("windows") then
        error("ICU builds on Windows with its MSBuild solution, which this recipe does not support yet")
    end
    -- the prebuilt data instead of the data sources, which the release archive leaves out
    otok.copy(slice.resources.data .. "/icudt79l.dat", slice.source .. "/source/data/in/icudt79l.dat")
    return slice.source .. "/source/configure"
end

local common = { "--disable-extras", "--disable-tests", "--disable-samples", "--disable-dyload" }

function build_tools(slice, options, deps)
    otok.autotools{ configure = configure(slice), args = common, cwd = slice.build, targets = { "all" } }
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
    local args = { "--with-cross-build=" .. slice.tools.prefix, "--disable-tools",
        "--with-data-packaging=" .. (dynamic and "library" or "static") }
    for _, a in ipairs(common) do args[#args + 1] = a end
    if options["no-renaming"] then args[#args + 1] = "--disable-renaming" end
    otok.autotools{ configure = configure(slice), args = args, cwd = slice.build }
    -- without tools ICU builds the data only when cross-compiling, which a slice for the build machine
    -- is not: it would install the stub; the data's Makefile takes the tools of --with-cross-build
    otok.make{ "install", cwd = slice.build .. "/data" }

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
    for _, h in ipairs{ "uversion", "utypes", "uchar", "ustring", "uloc", "ucol", "ubrk", "unorm2", "ucnv", "ucasemap",
            "utrans", "udat", "unum", "ucal", "uregex", "uidna", "uspoof", "ustdio" } do
        module[#module + 1] = '    header "../unicode/' .. h .. '.h"'
    end
    module[#module + 1] = "    export *\n}\n"
    otok.write(p .. "/module.modulemap", table.concat(module, "\n"))
    return { libraries = libraries, headers = p .. "/include", module_map = p .. "/module.modulemap" }
end
