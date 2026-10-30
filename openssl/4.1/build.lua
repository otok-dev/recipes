-- Windows: Configure with otok-windows-<arch> of Configurations/60-otok.conf, the libraries with GNU
-- make, and the public headers of the source and the build copied as install_dev copies them.
local function build_windows(slice, options)
    local t = slice.toolchain
    otok.copy(slice.recipe .. "/Configurations/60-otok.conf", slice.source .. "/Configurations/60-otok.conf")
    otok.copy(slice.recipe .. "/Configurations/platform/Windows/otok.pm", slice.source .. "/Configurations/platform/Windows/otok.pm")
    local shared = slice.linkage == "dynamic"
    -- llvm-ar beside llvm-lib: the makefile adds the objects to an archive in groups, which llvm-lib cannot
    local ar = (t.ar:gsub("llvm%-lib([^/]*)$", "llvm-ar%1"))

    local configure = { slice.toolchains.perl, slice.source .. "/Configure", "otok-windows-" .. slice.arch,
        shared and "shared" or "no-shared", "no-tests", "no-makedepend", "--prefix=" .. slice.prefix, "--libdir=lib",
        "CC=" .. t.cc, "CFLAGS=" .. table.concat(t.cflags, " "), "AR=" .. ar }
    if options["no-deprecated"] then table.insert(configure, "no-deprecated") end
    -- without --debug Configure defines NDEBUG; with it DEBUG and _DEBUG, as its VC- targets do (the flags stay otok's)
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
    -- the directories built into libcrypto: those of OpenSSL's own Windows builds, not the prefix of the slice
    local engines = makefile:match("\nENGINESDIR=%$%(libdir%)/(engines%-[^\n]*)\n") or "engines"
    otok.make{ "build_libs", "OPENSSLDIR=C:/Program Files/Common Files/SSL", "ENGINESDIR=C:/Program Files/OpenSSL/lib/" .. engines,
        "MODULESDIR=C:/Program Files/OpenSSL/lib/ossl-modules", cwd = slice.build }

    for _, dir in ipairs{ slice.source, slice.build } do
        for _, header in ipairs(otok.glob("include/openssl/*.h", dir)) do
            otok.copy(header, slice.prefix .. "/include/openssl/" .. header:match("[^/]*$"))
        end
    end
    local libraries = {}
    for _, name in ipairs{ "ssl", "crypto" } do
        local lib = slice.build .. "/lib" .. name .. ".lib"
        otok.copy(lib, slice.prefix .. "/lib/lib" .. name .. ".lib")
        libraries[name] = slice.prefix .. "/lib/lib" .. name .. ".lib"
        if shared then
            local dll = otok.glob("lib" .. name .. "-*.dll", slice.build)[1]
            local runtime = slice.prefix .. "/bin/" .. dll:match("[^/]*$")
            otok.copy(dll, runtime)
            libraries[name] = { link = libraries[name], runtime = runtime }
        end
    end
    return { libraries = libraries, headers = slice.prefix .. "/include" }
end

-- Configure with a target of Configurations/60-otok.conf and the slice's toolchain, then the
-- libraries and the development files only.
function build(slice, options, deps)
    if slice.platform == "windows" then return build_windows(slice, options) end
    local t = slice.toolchain
    otok.copy(slice.recipe .. "/Configurations/60-otok.conf", slice.source .. "/Configurations/60-otok.conf")

    local configure = { slice.toolchains.perl, slice.source .. "/Configure", "otok-" .. slice.vars.openssl_os .. "-" .. slice.arch, "no-shared",
        "no-tests", "--prefix=" .. slice.prefix, "--openssldir=/etc/ssl", "--libdir=lib",
        "CC=" .. t.cc, "CFLAGS=" .. table.concat(t.cflags, " ") .. " -Wall", "AR=" .. t.ar, "RANLIB=" .. t.ranlib }
    if options["no-deprecated"] then table.insert(configure, "no-deprecated") end
    otok.run(configure, { cwd = slice.build })

    if slice.vars.no_fork then
        local makefile = otok.read(slice.build .. "/Makefile")
        makefile = makefile:gsub("apps/lib/libapps%-lib%-http_server%.o \\\n", ""):gsub("apps/lib/libapps%-lib%-http_server%.o ", "")
        otok.write(slice.build .. "/Makefile", makefile)
    end
    otok.make{ "build_libs", cwd = slice.build }
    otok.make{ "install_dev", cwd = slice.build }

    -- the headers Swift and Objective-C use; the others come along through their includes
    local module = { "module COpenSSL {" }
    for _, h in ipairs{ "ssl", "err", "evp", "rand", "sha", "hmac", "kdf", "x509v3", "pem", "pkcs12", "core_names", "provider" } do
        table.insert(module, '    header "../openssl/' .. h .. '.h"')
    end
    table.insert(module, "    export *\n}\n")
    otok.write(slice.prefix .. "/module.modulemap", table.concat(module, "\n"))
    return {
        libraries = {
            ssl = slice.prefix .. "/lib/libssl.a",
            crypto = slice.prefix .. "/lib/libcrypto.a",
        },
        headers = slice.prefix .. "/include",
        module_map = slice.prefix .. "/module.modulemap",
    }
end
