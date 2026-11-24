-- GMP's configure and make under the MSYS2 of the make recipe, with MSVC: cl compiles the C and the C++ through the
-- compile script of the release (automake's, which gives cl -o and -l as it takes them), m4 of the tree expands GMP's
-- assembly and GNU as of the tree assembles it (gas.sh of the recipe: as GMP builds it with MinGW, for Windows' calling
-- convention), GNU ar and nm of the tree make and read the archives. The option assembly: --enable-fat (the code of
-- the CPU the program runs on, chosen when it first calls GMP), the host x86_64 (GMP's k8) or a CPU's, or
-- --disable-assembly.

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
    -- ar and nm of the tree, beside make
    local bin = msys(slice.toolchains.make):match("^(.*)/[^/]*$")
    local assembly = options.assembly
    local cl = msys(slice.source) .. "/compile cl -nologo"
    local args = {
        -- the build machine and the host as GMP knows Windows on x86_64 (its assembly for Windows' calling convention and
        -- 64-bit limbs, long being 32 bits): x86_64 is GMP's k8, the code every x86_64 CPU runs; a CPU's name its code
        "--build=x86_64-pc-mingw64",
        "--host=" .. ((assembly == "fat" or assembly == "generic" or assembly == "none") and "x86_64" or assembly)
            .. "-pc-mingw64",
        "--enable-alloca=" .. options.alloca,
        options.cxx and "--enable-cxx" or "--disable-cxx",
        "CC=" .. cl, "CXX=" .. cl,
        "CFLAGS=" .. joined(t.cflags),
        "CXXFLAGS=" .. joined(t.cxxflags, { "-EHsc" }),
        "AR=" .. bin .. "/ar", "NM=" .. bin .. "/nm",
        -- what configure cannot find out with cl: memset is an intrinsic, the assembler's word directive is .word, no
        -- libm; and `restrict`, which its C test would define for the C++ of gmpxx too, breaking the UCRT's headers
        "ac_cv_func_memset=yes", "gmp_cv_asm_w32=.word", "gmp_cv_check_libm_for_build=no", "ac_cv_c_restrict=no",
        -- the manual is in the release; nothing remakes it
        "MAKEINFO=true",
    }
    if assembly == "fat" then
        args[#args + 1] = "--enable-fat"
    elseif assembly == "none" then
        args[#args + 1] = "--disable-assembly"
    end
    if assembly ~= "none" then
        args[#args + 1] = "CCAS=sh " .. msys(slice.recipe) .. "/gas.sh " .. msys(slice.toolchains.as)
        args[#args + 1] = "M4=" .. msys(slice.toolchains.m4)
    end
    -- configure by a relative path: GMP's tests include "$srcdir/gmp-h.in", which cl cannot open as /c/…
    otok.autotools{
        configure = "../" .. slice.source:match("([^/]+)$") .. "/configure", args = args, cwd = slice.build,
        env = { CC = false, CXX = false, CFLAGS = false, CXXFLAGS = false, CPPFLAGS = false, LDFLAGS = false },
    }

    -- gmp.lib and gmpxx.lib, static; gmp.dll.lib and gmpxx.dll.lib, the import libraries of bin/gmp-10.dll and
    -- bin/gmpxx-4.dll; gmpxx only with the option cxx
    local p = slice.prefix
    local libraries = {}
    for _, name in ipairs(options.cxx and { "gmp", "gmpxx" } or { "gmp" }) do
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
