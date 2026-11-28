-- flex built by its configure and make under the MSYS2 of the make recipe, with MSVC: cl compiles through the compile
-- script of the release (automake's), the headers of POSIX that MSVC lacks come from compat/ of the recipe, regcomp and
-- regexec from PCRE2's wrapper. The program alone (src/flex.exe): the documentation needs help2man. The build runs the
-- flex it builds first (stage1flex), and so the patch, to make flex's own scanner. The program runs m4 as %M4% or,
-- without it, the m4.exe copied into libexec/flex/ (the patch).

-- A path as the programs of MSYS2 name it: C:/x is /c/x.
local function msys(path)
    return (path:gsub("^(%a):/", function(drive) return "/" .. drive:lower() .. "/" end))
end

-- MSVC's options with '-': MSYS2 takes /O2 for a path and turns it into C:/…/O2 for native programs
local function joined(flags, extra)
    local all = {}
    for _, f in ipairs(flags) do all[#all + 1] = (f:gsub("^/", "-")) end
    for _, f in ipairs(extra or {}) do all[#all + 1] = f end
    return table.concat(all, " ")
end

function build(slice, options, deps)
    local p = slice.prefix
    local cl = msys(slice.source) .. "/build-aux/compile cl -nologo"
    local m4 = deps.tools.m4.bin .. "/m4.exe"
    local pcre2 = deps.tools.pcre2
    local cppflags = { "-I" .. slice.recipe .. "/compat", "-I" .. pcre2.include }
    for _, define in ipairs(pcre2.defines) do cppflags[#cppflags + 1] = "-D" .. define end
    local args = {
        -- native Windows as gnulib and libtool know it, the build machine the same: configure runs its test programs
        "--build=x86_64-w64-mingw32", "--host=x86_64-w64-mingw32",
        -- cl for C and for C++, which configure checks though flex has none, and for the programs of the build machine
        "CC=" .. cl, "CXX=" .. cl, "CC_FOR_BUILD=" .. cl,
        "CFLAGS=" .. joined(slice.toolchain.cflags), "CXXFLAGS=" .. joined(slice.toolchain.cxxflags, { "-EHsc" }),
        "CPPFLAGS=" .. table.concat(cppflags, " "),
        "LIBS=" .. pcre2.libraries["pcre2-posix"] .. " " .. pcre2.libraries["pcre2-8"],
        -- what configure cannot find out with cl: memset is an intrinsic, which its test cannot declare; strcasecmp is _stricmp (compat/strings.h) and regcomp a macro of
        -- PCRE2's header for pcre2_regcomp, neither a function of that name to link; the m4 that prints m4_divnum's 0
        -- as text, CR LF, which configure's test of -P takes for another answer
        "ac_cv_func_memset=yes", "ac_cv_func_strcasecmp=yes", "ac_cv_func_regcomp=yes", "ac_cv_path_M4=" .. m4,
        -- without NLS and libfl: the program alone, which needs no library of the machine
        "--disable-nls", "--disable-libfl", "--disable-shared", "--disable-dependency-tracking",
        -- the manual is in the release; nothing remakes it
        "MAKEINFO=true",
    }
    -- configure by a relative path, as cl cannot open the /c/… of $srcdir
    otok.autotools{
        configure = "../" .. slice.source:match("([^/]+)$") .. "/configure", args = args, cwd = slice.build,
        targets = { "-C", "src", "flex.exe" }, env = { CC = false, CXX = false, CFLAGS = false, CXXFLAGS = false, CPPFLAGS = false, LDFLAGS = false, M4 = m4 },
    }
    otok.copy(slice.build .. "/src/flex.exe", p .. "/bin/flex.exe")
    otok.copy(m4, p .. "/libexec/flex/m4.exe")
    -- the header of C++ scanners (%option c++), which they include
    otok.copy(slice.source .. "/src/FlexLexer.h", p .. "/include/FlexLexer.h")
    return { programs = { flex = p .. "/bin/flex.exe" } }
end
