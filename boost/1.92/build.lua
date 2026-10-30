-- Boost's own b2 build. build_tools builds b2 for the build machine once; every slice runs it with
-- the slice's toolchain (otok.b2), for the libraries the project selects. The windows target (clang-cl on another
-- machine) builds with Boost's CMake instead, its libraries named as b2's --layout=system names them: a program built
-- with MSVC defines BOOST_AUTO_LINK_SYSTEM for auto-linking to ask for these names (or BOOST_ALL_NO_LIB to link them
-- itself), since no toolset tag of b2 (vc145) can be the consumer's.

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

-- The windows target: b2's clang-win runs the actions of msvc.jam, which are cmd's. The release archive has every
-- library's CMakeLists.txt and tools/cmake, not the superproject's CMakeLists.txt (cmake/CMakeLists.txt of this recipe)
-- nor libs/*/include: the headers are in boost/ of the root, which every compile is given. The libraries go to the
-- stage directory, the prefix; nothing is installed.
local function build_with_cmake(slice, deps, selected)
    if deps.icu4c then error("ICU for Boost is not built for the windows target yet") end
    otok.copy(slice.recipe .. "/cmake/CMakeLists.txt", slice.source .. "/CMakeLists.txt")
    otok.cmake{ defines = {
        BOOST_INCLUDE_LIBRARIES = table.concat(selected, ";"),
        BOOST_STAGEDIR = slice.prefix,
        BOOST_SKIP_INSTALL_RULES = true,
        BOOST_INSTALL_LAYOUT = "system",  -- the names of b2's --layout=system, not -clangw21-mt-x64-1_92
        CMAKE_C_STANDARD_INCLUDE_DIRECTORIES = slice.source,
        CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES = slice.source,
        BOOST_LOCALE_ENABLE_ICU = false,
        BOOST_MATH_BUILD_WITH_LEGACY_FUNCTIONS = true,  -- the C99 and TR1 libraries, which b2 builds
        BUILD_TESTING = false,
        -- Boost.Context assembled by clang-cl, in GNU syntax: its armclang sources for ARM64; for x86_64 its gas sources,
        -- which cmake/CMakeLists.txt turns into clang's (LLVM has no armasm64, and llvm-ml makes absolute addresses
        -- of what ml64 addresses relative to RIP, which MSVC's linker refuses)
        BOOST_CONTEXT_ASSEMBLER = slice.arch == "arm64" and "armclang" or "gas",
        BOOST_CONTEXT_ASM_SUFFIX = slice.arch == "arm64" and ".S" or nil,
    } }
end

function build(slice, options, deps)
    local selected = options.libraries
    if #selected > 0 and slice.os == "windows" then
        build_with_cmake(slice, deps, selected)
    elseif #selected > 0 then
        -- the project's C++ standard, else 20
        local args = { "cxxstd=" .. (slice.cxx_standard or 20) }
        -- b2 names libraries by toolset and version on a Windows build machine (--layout=versioned), whatever the
        -- target: the plain names (libboost_json.a) for every target but Windows, whose auto-linking asks for the others
        if not windows(slice) then args[#args + 1] = "--layout=system" end
        for _, l in ipairs(selected) do
            if l == "process" and no_processes[slice.platform] then
                error("Boost.Process needs fork and exec, which " .. slice.platform .. " does not have: select it only for macosx and native")
            end
            args[#args + 1] = "--with-" .. l
        end
        if no_alt_stack[slice.platform] then args[#args + 1] = "define=BOOST_TEST_DISABLE_ALT_STACK" end
        -- where WinDbg is, b2 builds stacktrace_windbg instead of stacktrace_basic: the product BoostStacktraceBasic holds it
        -- on every target, as Boost's CMake builds it
        if windows(slice) then args[#args + 1] = "boost.stacktrace.basic=on" end
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
    if slice.os == "windows" then
        -- boost_json.lib with boost_json.dll, or libboost_json.lib
        for _, file in ipairs(otok.glob("lib/*boost_*.lib", slice.prefix)) do
            local base = file:match("/(l?i?b?boost_[%w_]+)%.lib$")
            if base then
                local dll = otok.glob("bin/" .. base .. ".dll", slice.prefix)[1]
                libraries[base:match("boost_([%w_]+)$")] = dll and { link = file, runtime = dll } or file
            end
        end
    elseif windows(slice) then
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
