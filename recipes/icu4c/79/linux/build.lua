-- ICU's own autotools build. build_tools builds ICU for the build machine once; its tools (icupkg,
-- pkgdata, genccode, …) package the data of every slice (--with-cross-build), which therefore builds
-- no tools of its own.

-- The source tree for configure, whose path it returns. `dat`: the data, icudt79l.dat, as data/in/ of ICU's build has
-- it; without it the data sources, which the release archive leaves out, built by ICU's Python build tool as the
-- project's filter says.
local function configure(slice, dat)
    if dat then
        otok.copy(dat, slice.source .. "/source/data/in/icudt79l.dat")
    else
        otok.remove(slice.source .. "/source/data")
        otok.copy(slice.resources.data_sources, slice.source .. "/source/data")
    end
    return slice.source .. "/source/configure"
end

-- The data every slice packages: the prebuilt data, or with a filter the data build_tools built from its sources once
-- (in a slice, `slice.tools.prefix`; in build_tools, nothing: it builds it).
local function data_of(slice, filter, tools)
    if not filter then return slice.resources.data .. "/icudt79l.dat" end
    return tools and tools .. "/data/icudt79l.dat" or nil
end

local common = { "--disable-extras", "--disable-tests", "--disable-samples", "--disable-dyload" }

-- the Python configure runs; with a filter, ICU's Python build tool builds the data as it says (build_tools only)
local function data_env(slice, filter)
    if not filter then return { PYTHON = slice.toolchains.python } end
    return { ICU_DATA_FILTER_FILE = filter, PYTHON = slice.toolchains.python }
end

function build_tools(slice, options, deps)
    -- the tools, built with the data the slices have: the prebuilt data is not fetched with a filter
    local filter = options["data-filter"]
    local args = { table.unpack(common) }
    local env = data_env(slice, filter)
    otok.autotools{ configure = configure(slice, data_of(slice, filter)), args = args, cwd = slice.build, targets = { "all" }, env = env }
    -- what a cross build reads from the build tree it is given: the tools and their settings
    otok.copy(slice.build .. "/bin", slice.prefix .. "/bin")
    for _, f in ipairs{ "icucross.mk", "icucross.inc" } do
        otok.copy(slice.build .. "/config/" .. f, slice.prefix .. "/config/" .. f)
    end
    -- the data built from its sources, once: the slices package it as they package the prebuilt data
    if filter then otok.copy(slice.build .. "/data/out/tmp/icudt79l.dat", slice.prefix .. "/data/icudt79l.dat") end
end

function build(slice, options, deps)
    local dynamic = slice.linkage == "dynamic"
    local filter = options["data-filter"]
    if filter and options.data == "none" then
        error("data-filter needs data = \"static\" or \"file\": with \"none\" there is no data to filter")
    end
    -- static and library: the data in libicudata; archive: icudt79l.dat, and the stub libicudata
    local packaging = options.data ~= "static" and "archive" or dynamic and "library" or "static"
    local args = { "--with-cross-build=" .. slice.tools.prefix, "--disable-tools", "--with-data-packaging=" .. packaging }
    for _, a in ipairs(common) do args[#args + 1] = a end
    if options["no-renaming"] then args[#args + 1] = "--disable-renaming" end
    local env = data_env(slice, nil)
    otok.autotools{ configure = configure(slice, data_of(slice, filter, slice.tools.prefix)), args = args, cwd = slice.build, env = env }
    -- without tools ICU builds the data only when cross-compiling, which a slice for the build machine
    -- is not: it would install the stub; the data's Makefile takes the tools of --with-cross-build
    otok.make{ "install", cwd = slice.build .. "/data", env = env }

    local p = slice.prefix
    local libraries = {}
    for _, name in ipairs{ "uc", "i18n", "io", "data" } do
        local base = p .. "/lib/libicu" .. name
        libraries[name] = otok.exists(base .. ".so") and base .. ".so" or base .. ".a"
    end
    local data = nil
    if options.data == "file" then
        data = { ["icudt79l.dat"] = p .. "/share/icu/79.1/icudt79l.dat" }
    end
    return { libraries = libraries, headers = p .. "/include", data = data }
end
