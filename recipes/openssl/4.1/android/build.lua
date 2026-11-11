-- Configure with a target of Configurations/60-otok.conf and the slice's compiler and flags (the NDK's clang for the ABI and
-- the API level), then the libraries and the development files only. The directory OpenSSL looks for certificates in is
-- /system/etc/ssl.
function build(slice, options, deps)
    local t = slice.toolchain
    local shared = slice.linkage == "dynamic"
    otok.copy(slice.recipe .. "/Configurations/60-otok.conf", slice.source .. "/Configurations/60-otok.conf")
    local configure = { slice.toolchains.perl, slice.source .. "/Configure", "otok-android-" .. slice.arch,
        shared and "shared" or "no-shared", "no-tests", "--prefix=" .. slice.prefix, "--openssldir=/system/etc/ssl", "--libdir=lib",
        "CC=" .. t.cc, "CFLAGS=" .. table.concat(t.cflags, " "), "AR=" .. t.ar, "RANLIB=" .. t.ranlib }
    if options["no-deprecated"] then table.insert(configure, "no-deprecated") end
    otok.run(configure, { cwd = slice.build })
    otok.make{ "build_libs", cwd = slice.build }
    local install = { "install_dev", cwd = slice.build }
    if shared then table.insert(install, 2, "install_runtime_libs") end
    otok.make(install)

    -- The Android target keeps one include/ for its ABIs, and configuration.h tells the size of BN_ULONG, which only the
    -- word size of the ABI changes: 64-bit ABIs have SIXTY_FOUR_BIT_LONG, 32-bit ones BN_LLONG with THIRTY_TWO_BIT
    local configuration = slice.prefix .. "/include/openssl/configuration.h"
    local text, count = otok.read(configuration):gsub("#if !defined%(OPENSSL_SYS_UEFI%)\r?\n.-\r?\n#endif\r?\n", function()
        return table.concat({
            "#if !defined(OPENSSL_SYS_UEFI)",
            "# ifdef __LP64__",
            "#  undef BN_LLONG",
            "#  define SIXTY_FOUR_BIT_LONG",
            "#  undef SIXTY_FOUR_BIT",
            "#  undef THIRTY_TWO_BIT",
            "# else",
            "#  define BN_LLONG",
            "#  undef SIXTY_FOUR_BIT_LONG",
            "#  undef SIXTY_FOUR_BIT",
            "#  define THIRTY_TWO_BIT",
            "# endif",
            "#endif",
            "",
        }, "\n")
    end, 1)
    if count ~= 1 then error("configuration.h has no word size block of the expected form") end
    otok.write(configuration, text)

    local p = slice.prefix
    local ext = shared and ".so" or ".a"
    return {
        libraries = { ssl = otok.glob("lib/libssl" .. ext, p)[1], crypto = otok.glob("lib/libcrypto" .. ext, p)[1] },
        headers = p .. "/include",
    }
end
