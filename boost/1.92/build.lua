-- Boost's own b2 build. build_tools builds b2 for the build machine once; every slice runs it with
-- the slice's toolchain (otok.b2), for the libraries the project selects.

local function windows(slice)
    return slice.triple:find("windows") ~= nil
end

function build_tools(slice, options, deps)
    -- bootstrap finds the build machine's compiler
    if windows(slice) then
        -- by its full path, and with cmd finding the scripts it calls in the current directory, which
        -- NoDefaultCurrentDirectoryInExePath turns off
        local script = (slice.source .. "/bootstrap.bat"):gsub("/", "\\")
        otok.run({ "cmd.exe", "/c", script }, { env = { NoDefaultCurrentDirectoryInExePath = false } })
        otok.copy(slice.source .. "/b2.exe", slice.prefix .. "/bin/b2.exe")
    else
        otok.run{"./bootstrap.sh"}
        otok.copy(slice.source .. "/b2", slice.prefix .. "/bin/b2")
    end
end

-- Apple's platforms but macOS have no fork, exec or the process information Boost.Process uses; tvOS and
-- watchOS no sigaltstack, which Boost.Test's execution monitor uses unless told not to
local no_processes = { ios = true, iossim = true, catalyst = true, tvos = true, tvossim = true, watchos = true, watchossim = true, xros = true, xrossim = true }
local no_alt_stack = { tvos = true, tvossim = true, watchos = true, watchossim = true }

-- stacktrace backends b2 builds only where it finds what they need (addr2line on macOS alone), which no
-- product offers: every slice returns the same libraries
local unoffered = { stacktrace_addr2line = true, stacktrace_dump = true, stacktrace_from_exception = true }

-- b2 names macOS dynamic libraries, and their references to each other, by their file names: @rpath/
-- instead, so the consumer's executable chooses where they are
local function fix_install_names(slice)
    local libs = {}
    for _, path in ipairs(otok.glob("lib/libboost_*.dylib", slice.prefix)) do
        libs[#libs + 1] = path:match("/(libboost_[%w_]+%.dylib)$")
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
    local selected = options.libraries
    if #selected > 0 then
        local args = { "cxxstd=20" }
        for _, l in ipairs(selected) do
            if l == "process" and no_processes[slice.platform] then
                error("Boost.Process needs fork and exec, which " .. slice.platform .. " does not have: select it only for macosx and native")
            end
            args[#args + 1] = "--with-" .. l
        end
        if no_alt_stack[slice.platform] then args[#args + 1] = "define=BOOST_TEST_DISABLE_ALT_STACK" end
        -- ICU only when asked for: b2 would take any ICU it finds (has_icu), so it is turned off otherwise
        if deps.icu4c then
            args[#args + 1] = "-sICU_PATH=" .. deps.icu4c.prefix
            args[#args + 1] = "boost.locale.icu=on"
        else
            args[#args + 1] = "boost.locale.icu=off"
            args[#args + 1] = "--disable-icu"
        end
        otok.b2{ b2 = slice.tools.prefix .. "/bin/b2", args = args, targets = { "stage" }, env = { NoDefaultCurrentDirectoryInExePath = false } }
    end
    -- the headers, without b2 install copying 16000 files one by one
    otok.copy(slice.source .. "/boost", slice.prefix .. "/include/boost")

    local libraries = {}
    if windows(slice) then
        -- the names auto-linking asks for: libboost_json-vc145-mt-x64-1_92.lib, boost_json-vc145-mt-x64-1_92.lib
        -- with its DLL
        for _, file in ipairs(otok.glob("lib/*.lib", slice.prefix)) do
            local name = file:match("/l?i?b?boost_([%w_]+)%-vc[^/]*%.lib$")
            if name then
                local dll = file:gsub("%.lib$", ".dll")
                libraries[name] = otok.exists(dll) and { link = file, runtime = dll } or file
            end
        end
    else
        local suffix = slice.linkage == "static" and "a" or slice.triple:find("darwin") and "dylib" or "so"
        if suffix == "dylib" then fix_install_names(slice) end
        for _, file in ipairs(otok.glob("lib/libboost_*." .. suffix, slice.prefix)) do
            libraries[file:match("/libboost_([%w_]+)%." .. suffix .. "$")] = file
        end
    end
    for name in pairs(unoffered) do libraries[name] = nil end
    return { libraries = libraries, headers = slice.prefix .. "/include" }
end
