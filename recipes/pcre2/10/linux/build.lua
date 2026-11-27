-- PCRE2's CMake project, the libraries only (no pcre2grep, pcre2test or tests, so none of their optional libraries). The
-- 8-bit library and the POSIX wrapper are built together; the 16-bit and 32-bit ones as the options ask. What it installs:
-- libpcre2-<width>.a and libpcre2-posix.a, or the .so with their links.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    otok.cmake{ defines = {
        BUILD_SHARED_LIBS = not static, BUILD_STATIC_LIBS = static, PCRE2_STATIC_PIC = static,
        PCRE2_BUILD_PCRE2_8 = true, PCRE2_BUILD_PCRE2_16 = options["pcre2-16"], PCRE2_BUILD_PCRE2_32 = options["pcre2-32"],
        PCRE2_SUPPORT_JIT = options.jit, PCRE2_SUPPORT_UNICODE = true,
        PCRE2_BUILD_PCRE2GREP = false, PCRE2_BUILD_TESTS = false, PCRE2_SHOW_REPORT = false,
        PCRE2_SUPPORT_LIBBZ2 = false, PCRE2_SUPPORT_LIBZ = false, PCRE2_SUPPORT_LIBEDIT = false, PCRE2_SUPPORT_LIBREADLINE = false,
    } }
    local p = slice.prefix
    local function lib(name) return otok.glob(static and ("lib/lib" .. name .. ".a") or ("lib/lib" .. name .. ".so"), p)[1] end
    local libraries = { ["pcre2-8"] = lib("pcre2-8") }
    if options["pcre2-16"] then libraries["pcre2-16"] = lib("pcre2-16") end
    if options["pcre2-32"] then libraries["pcre2-32"] = lib("pcre2-32") end
    if options.posix then libraries["pcre2-posix"] = lib("pcre2-posix") end
    return { libraries = libraries, headers = p .. "/include" }
end
