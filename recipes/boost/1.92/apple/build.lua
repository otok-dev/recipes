-- Boost's own b2 build. build_tools builds b2 for the build machine once; every slice runs it with
-- the slice's toolchain (otok.b2), for the libraries the project selects.

function build_tools(slice, options, deps)
    -- bootstrap finds the build machine's compiler
    otok.run{"./bootstrap.sh"}
    otok.copy(slice.source .. "/b2", slice.prefix .. "/bin/b2")
end

-- Apple's platforms but macOS have no fork, exec or the process information Boost.Process uses; tvOS and
-- watchOS no sigaltstack, which Boost.Test's execution monitor uses unless told not to
local no_processes = { ios = true, iossim = true, catalyst = true, tvos = true, tvossim = true, watchos = true, watchossim = true, xros = true, xrossim = true }
local no_alt_stack = { tvos = true, tvossim = true, watchos = true, watchossim = true }

-- stacktrace backends b2 builds only where it finds what they need (addr2line on macOS alone), which no
-- product offers: every slice returns the same libraries
local unoffered = { stacktrace_addr2line = true, stacktrace_dump = true, stacktrace_from_exception = true }

function build(slice, options, deps)
    local selected = options.libraries
    if #selected > 0 then
        -- the project's C++ standard, else 20
        local args = { "cxxstd=" .. (slice.cxx_standard or 20), "--layout=system" }
        for _, l in ipairs(selected) do
            if l == "process" and no_processes[slice.platform] then
                error("Boost.Process needs fork and exec, which " .. slice.platform .. " does not have: select it only for macosx")
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
        otok.b2{ b2 = slice.tools.prefix .. "/bin/b2", args = args, targets = { "stage" } }
    end
    -- the headers, without b2 install copying 16000 files one by one
    otok.copy(slice.source .. "/boost", slice.prefix .. "/include/boost")

    local libraries = {}
    for _, file in ipairs(otok.glob("lib/libboost_*.a", slice.prefix)) do
        libraries[file:match("/libboost_([%w_]+)%.a$")] = file
    end
    for name in pairs(unoffered) do libraries[name] = nil end
    return { libraries = libraries, headers = slice.prefix .. "/include" }
end
