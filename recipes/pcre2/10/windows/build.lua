-- PCRE2's CMake project, the libraries only (no pcre2grep, pcre2test or tests, so none of their optional libraries). The
-- 8-bit library and the POSIX wrapper are built together; the 16-bit and 32-bit ones as the options ask. What it installs:
-- pcre2-<width>-static.lib and pcre2-posix-static.lib with MSVC (and clang-cl), or pcre2-<width>.lib and pcre2-posix.lib
-- with bin/pcre2-<width>.dll and bin/pcre2-posix.dll; with the suffix d in debug.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    otok.cmake{ defines = {
        BUILD_SHARED_LIBS = not static, BUILD_STATIC_LIBS = static,
        PCRE2_BUILD_PCRE2_8 = true, PCRE2_BUILD_PCRE2_16 = options["pcre2-16"], PCRE2_BUILD_PCRE2_32 = options["pcre2-32"],
        PCRE2_SUPPORT_JIT = options.jit, PCRE2_SUPPORT_UNICODE = true,
        PCRE2_BUILD_PCRE2GREP = false, PCRE2_BUILD_TESTS = false, PCRE2_SHOW_REPORT = false,
        PCRE2_SUPPORT_LIBBZ2 = false, PCRE2_SUPPORT_LIBZ = false, PCRE2_SUPPORT_LIBEDIT = false, PCRE2_SUPPORT_LIBREADLINE = false,
    } }
    local p = slice.prefix
    local d = slice.configuration == "debug" and "d" or ""
    local function lib(name)
        if static then
            local file = p .. "/lib/" .. name .. "-static" .. d .. ".lib"
            assert(otok.exists(file), "PCRE2 installed no " .. file)
            return file
        end
        local link, dll = p .. "/lib/" .. name .. d .. ".lib", p .. "/bin/" .. name .. d .. ".dll"
        assert(otok.exists(link) and otok.exists(dll), "PCRE2 installed no " .. link .. " with " .. dll)
        return { link = link, runtime = dll }
    end
    local libraries = { ["pcre2-8"] = lib("pcre2-8") }
    if options["pcre2-16"] then libraries["pcre2-16"] = lib("pcre2-16") end
    if options["pcre2-32"] then libraries["pcre2-32"] = lib("pcre2-32") end
    if options.posix then libraries["pcre2-posix"] = lib("pcre2-posix") end
    return { libraries = libraries, headers = p .. "/include" }
end
