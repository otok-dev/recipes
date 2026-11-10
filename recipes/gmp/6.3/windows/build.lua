-- GMP's configure and make under the MSYS2 of the make recipe, with MSVC: cl compiles the C and the C++ through the
-- compile script of the release (automake's, which gives cl -o and -l as it takes them), m4 of the tree expands GMP's
-- assembly and GNU as of the tree assembles it (gas.sh of the recipe: as GMP builds it with MinGW, for Windows' calling
-- convention), GNU ar and nm of the tree make and read the archives. One library for every x86_64 CPU: --enable-fat
-- chooses the code of the CPU the program runs on when it first calls GMP.

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
    local t = slice.toolchain
    local bin = msys(slice.toolchains.as):match("^(.*)/[^/]*$")
    local cl = msys(slice.source) .. "/compile cl -nologo"
    local args = {
        -- the build machine and the host as GMP knows Windows on x86_64: its assembly for Windows' calling convention
        "--build=x86_64-pc-mingw64", "--host=x86_64-pc-mingw64",
        "--enable-fat", "--enable-cxx",
        "CC=" .. cl, "CXX=" .. cl,
        "CFLAGS=" .. joined(t.cflags),
        "CXXFLAGS=" .. joined(t.cxxflags, { "-EHsc" }),
        "CCAS=sh " .. msys(slice.recipe) .. "/gas.sh " .. msys(slice.toolchains.as),
        "M4=" .. msys(slice.toolchains.m4), "AR=" .. bin .. "/ar", "NM=" .. bin .. "/nm",
        -- what configure cannot find out with cl: memset is an intrinsic, the assembler's word directive is .word, no
        -- libm; and `restrict`, which its C test would define for the C++ of gmpxx too, breaking the UCRT's headers
        "ac_cv_func_memset=yes", "gmp_cv_asm_w32=.word", "gmp_cv_check_libm_for_build=no", "ac_cv_c_restrict=no",
        -- the manual is in the release; nothing remakes it
        "MAKEINFO=true",
    }
    -- configure by a relative path: GMP's tests include "$srcdir/gmp-h.in", which cl cannot open as /c/…
    otok.autotools{
        configure = "../" .. slice.source:match("([^/]+)$") .. "/configure", args = args, cwd = slice.build,
        env = { CC = false, CXX = false, CFLAGS = false, CXXFLAGS = false, CPPFLAGS = false, LDFLAGS = false },
    }

    -- gmp.lib and gmpxx.lib, static; gmp.dll.lib and gmpxx.dll.lib, the import libraries of bin/gmp-10.dll and
    -- bin/gmpxx-4.dll
    local p = slice.prefix
    local libraries = {}
    for _, name in ipairs{ "gmp", "gmpxx" } do
        if slice.linkage == "dynamic" then
            local dll = otok.glob("bin/" .. name .. "-*.dll", p)[1]
            assert(dll, "GMP installed no " .. name .. "-*.dll")
            libraries[name] = { link = p .. "/lib/" .. name .. ".dll.lib", runtime = dll }
        else
            libraries[name] = p .. "/lib/" .. name .. ".lib"
        end
    end
    return { libraries = libraries, headers = p .. "/include" }
end
