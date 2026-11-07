-- Configure with a target of Configurations/60-otok.conf and the slice's toolchain, then the
-- libraries and the development files only.
function build(slice, options, deps)
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
