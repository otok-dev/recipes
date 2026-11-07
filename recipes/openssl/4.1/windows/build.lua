-- Configure with a target of Configurations/60-otok.conf: in windows/msvc otok-windows-msvc-<arch> and its libraries with
-- nmake; in linux/clang-cl otok-windows-<arch> and its libraries with GNU make. Then the public headers of the source and
-- the build copied as install_dev copies them. The directories built into libcrypto are those of OpenSSL's own Windows
-- builds, not the prefix of the slice.

-- MSVC: the VC- targets, with NASM for x86_64, which Configure looks for in PATH; nmake takes no MAKEFLAGS of make (the
-- jobserver's)
local function msvc(slice, options, shared)
    local path = slice.toolchain.env.PATH
    if slice.toolchains.nasm then path = slice.toolchains.nasm:match("^(.*)[/\\][^/\\]*$") .. ";" .. path end
    local env = { PATH = path, MAKEFLAGS = false, MFLAGS = false }
    local configure = { slice.toolchains.perl, slice.source .. "/Configure", "otok-windows-msvc-" .. slice.arch,
        shared and "shared" or "no-shared", "no-tests", "no-makedepend",
        "--prefix=C:\\Program Files\\OpenSSL", "--openssldir=C:\\Program Files\\Common Files\\SSL",
        "CFLAGS=/nologo /W3 /wd4090 " .. table.concat(slice.toolchain.cflags, " ") }
    if options["no-deprecated"] then table.insert(configure, "no-deprecated") end
    -- without --debug Configure defines NDEBUG; with it DEBUG and _DEBUG, as its VC- targets do (the flags stay otok's)
    if slice.configuration == "debug" then table.insert(configure, "--debug") end
    otok.run(configure, { cwd = slice.build, env = env })
    otok.run({ "nmake", "-nologo", "build_libs" }, { cwd = slice.build, env = env })
end

-- clang-cl across from Linux: the Unix makefile template, platform/Windows/otok.pm for the MSVC names of the libraries
local function clang_cl(slice, options, shared)
    local t = slice.toolchain
    otok.copy(slice.recipe .. "/Configurations/platform/Windows/otok.pm", slice.source .. "/Configurations/platform/Windows/otok.pm")
    -- llvm-ar beside llvm-lib: the makefile adds the objects to an archive in groups, which llvm-lib cannot
    local ar = (t.ar:gsub("llvm%-lib([^/]*)$", "llvm-ar%1"))
    local configure = { slice.toolchains.perl, slice.source .. "/Configure", "otok-windows-" .. slice.arch,
        shared and "shared" or "no-shared", "no-tests", "no-makedepend", "--prefix=" .. slice.prefix, "--libdir=lib",
        "CC=" .. t.cc, "CFLAGS=" .. table.concat(t.cflags, " "), "AR=" .. ar }
    if options["no-deprecated"] then table.insert(configure, "no-deprecated") end
    if slice.configuration == "debug" then table.insert(configure, "--debug") end
    otok.run(configure, { cwd = slice.build })

    local makefile = otok.read(slice.build .. "/Makefile")
    if shared then
        -- libssl links libcrypto as the Unix template links a shared library, -L. -lcrypto, which clang-cl does
        -- not know: its import library instead
        local found
        makefile = makefile:gsub("(%s)%-L%.(%s)", "%1%2")
        makefile, found = makefile:gsub("(%s)%-lcrypto(%s)", "%1libcrypto.lib%2")
        if found == 0 then error("the Makefile does not link libssl with -lcrypto") end
    end
    -- the compiler OpenSSL_version(OPENSSL_CFLAGS) tells: clang-cl and the flags without the paths of this machine
    -- and of the work directory, which would make every build of the slice differ
    local flags = {}
    for _, flag in ipairs(t.cflags) do
        if not flag:find("prefix-map", 1, true) then table.insert(flags, flag) end
    end
    local count
    makefile, count = makefile:gsub('"%$%(CC%) %$%(LIB_CFLAGS%) %$%(CPPFLAGS_Q%)"', function()
        return '"clang-cl ' .. table.concat(flags, " ") .. ' $(CPPFLAGS_Q)"'
    end)
    if count == 0 then error("the Makefile has no rule for crypto/buildinf.h of the expected form") end
    otok.write(slice.build .. "/Makefile", makefile)
    local engines = makefile:match("\nENGINESDIR=%$%(libdir%)/(engines%-[^\n]*)\n") or "engines"
    otok.make{ "build_libs", "OPENSSLDIR=C:/Program Files/Common Files/SSL", "ENGINESDIR=C:/Program Files/OpenSSL/lib/" .. engines,
        "MODULESDIR=C:/Program Files/OpenSSL/lib/ossl-modules", cwd = slice.build }
end

function build(slice, options, deps)
    otok.copy(slice.recipe .. "/Configurations/60-otok.conf", slice.source .. "/Configurations/60-otok.conf")
    local shared = slice.linkage == "dynamic"
    local with_msvc = slice.environment == "windows/msvc"
    if with_msvc then msvc(slice, options, shared) else clang_cl(slice, options, shared) end

    for _, dir in ipairs{ slice.source, slice.build } do
        for _, header in ipairs(otok.glob("include/openssl/*.h", dir)) do
            otok.copy(header, slice.prefix .. "/include/openssl/" .. header:match("[^/]*$"))
        end
    end
    if with_msvc then
        -- arm64 is built without assembler (no-asm, as VC-WIN64-ARM), which configuration.h says with OPENSSL_NO_ASM; only
        -- OpenSSL's own sources test it, and the Windows target keeps one include/ for its architectures, so the copy for
        -- consumers leaves it out
        local configuration = slice.prefix .. "/include/openssl/configuration.h"
        local text, count = otok.read(configuration):gsub("# ifndef OPENSSL_NO_ASM\r?\n#  define OPENSSL_NO_ASM\r?\n# endif\r?\n", "")
        if slice.arch == "arm64" and count ~= 1 then error("configuration.h does not define OPENSSL_NO_ASM as expected") end
        otok.write(configuration, text)
    end
    local libraries = {}
    for _, name in ipairs{ "ssl", "crypto" } do
        local lib = slice.prefix .. "/lib/lib" .. name .. ".lib"
        otok.copy(slice.build .. "/lib" .. name .. ".lib", lib)
        libraries[name] = lib
        if shared then
            local dll = otok.glob("lib" .. name .. "-*.dll", slice.build)[1]
            local runtime = slice.prefix .. "/bin/" .. dll:match("[^/]*$")
            otok.copy(dll, runtime)
            libraries[name] = { link = lib, runtime = runtime }
        end
    end
    return { libraries = libraries, headers = slice.prefix .. "/include" }
end
