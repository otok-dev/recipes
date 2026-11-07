-- Boost's CMake with clang-cl, its libraries named as b2's --layout=system names them: a program built with MSVC
-- defines BOOST_AUTO_LINK_SYSTEM for auto-linking to ask for these names (or BOOST_ALL_NO_LIB to link them itself),
-- since no toolset tag of b2 (vc145) can be the consumer's. The release archive has every library's CMakeLists.txt and
-- tools/cmake, not the superproject's CMakeLists.txt (cmake/CMakeLists.txt of this recipe) nor libs/*/include: the
-- headers are in boost/ of the root, which every compile is given. The libraries go to the stage directory, the prefix;
-- nothing is installed.

-- stacktrace backends b2 builds only where it finds what they need, which no product offers: every slice returns the
-- same libraries
local unoffered = { stacktrace_addr2line = true, stacktrace_dump = true, stacktrace_from_exception = true }

function build(slice, options, deps)
    local selected = options.libraries
    if #selected > 0 then
        if deps.icu4c then error("ICU for Boost is not built with clang-cl yet") end
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
            -- Boost.Context assembled by clang-cl, in GNU syntax: its armclang sources for ARM64; for x86_64 its gas
            -- sources, which cmake/CMakeLists.txt turns into clang's (LLVM has no armasm64, and llvm-ml makes absolute
            -- addresses of what ml64 addresses relative to RIP, which MSVC's linker refuses)
            BOOST_CONTEXT_ASSEMBLER = slice.arch == "arm64" and "armclang" or "gas",
            BOOST_CONTEXT_ASM_SUFFIX = slice.arch == "arm64" and ".S" or nil,
        } }
    end
    -- the headers
    otok.copy(slice.source .. "/boost", slice.prefix .. "/include/boost")

    -- boost_json.lib with boost_json.dll, or libboost_json.lib
    local libraries = {}
    for _, file in ipairs(otok.glob("lib/*boost_*.lib", slice.prefix)) do
        local base = file:match("/(l?i?b?boost_[%w_]+)%.lib$")
        if base then
            local dll = otok.glob("bin/" .. base .. ".dll", slice.prefix)[1]
            libraries[base:match("boost_([%w_]+)$")] = dll and { link = file, runtime = dll } or file
        end
    end
    for name in pairs(unoffered) do libraries[name] = nil end
    return { libraries = libraries, headers = slice.prefix .. "/include" }
end
