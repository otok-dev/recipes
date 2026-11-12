-- Boost's own b2 build with MSVC. build_tools builds b2 for the build machine once; every slice runs it with the
-- slice's toolchain (otok.b2), for the libraries the project selects. The libraries have the names auto-linking asks
-- for (--layout=versioned, b2's default on Windows).

function build_tools(slice, options, deps)
    -- bootstrap finds the build machine's compiler: by its full path, and with cmd finding the scripts it calls in the
    -- current directory, which NoDefaultCurrentDirectoryInExePath turns off; without the slice's flags, which build.bat
    -- appends to its own: /MD over its /MT (D9025), /O2 and /DNDEBUG twice
    local script = (slice.source .. "/bootstrap.bat"):gsub("/", "\\")
    otok.run({ "cmd.exe", "/c", script },
        { env = { NoDefaultCurrentDirectoryInExePath = false, CFLAGS = false, CXXFLAGS = false, LDFLAGS = false } })
    otok.copy(slice.source .. "/b2.exe", slice.prefix .. "/bin/b2.exe")
end

-- stacktrace backends b2 builds only where it finds what they need (addr2line on macOS alone), which no
-- product offers: every slice returns the same libraries
local unoffered = { stacktrace_addr2line = true, stacktrace_dump = true, stacktrace_from_exception = true }

function build(slice, options, deps)
    local selected = options.libraries
    if #selected > 0 then
        -- the project's C++ standard, else 20
        local args = { "cxxstd=" .. (slice.cxx_standard or 20) }
        for _, l in ipairs(selected) do args[#args + 1] = "--with-" .. l end
        -- where WinDbg is, b2 builds stacktrace_windbg instead of stacktrace_basic: the product BoostStacktraceBasic
        -- holds it, as Boost's CMake builds it
        args[#args + 1] = "boost.stacktrace.basic=on"
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

    -- the names auto-linking asks for: libboost_json-vc145-mt-x64-1_92.lib, boost_json-vc145-mt-x64-1_92.lib with its
    -- DLL
    local libraries = {}
    for _, file in ipairs(otok.glob("lib/*.lib", slice.prefix)) do
        local name = file:match("/l?i?b?boost_([%w_]+)%-vc[^/]*%.lib$")
        if name then
            local dll = file:gsub("%.lib$", ".dll")
            libraries[name] = otok.exists(dll) and { link = file, runtime = dll } or file
        end
    end
    for name in pairs(unoffered) do libraries[name] = nil end
    return { libraries = libraries, headers = slice.prefix .. "/include" }
end
