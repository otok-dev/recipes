-- Configure with OpenSSL's own target for the architecture and the slice's compiler and flags, then the libraries and the
-- development files only. The directory OpenSSL looks for certificates in is /etc/ssl, where the distributions keep theirs.
function build(slice, options, deps)
    local t = slice.toolchain
    local shared = slice.linkage == "dynamic"
    local target = slice.arch == "x86_64" and "linux-x86_64" or "linux-aarch64"
    local configure = { slice.toolchains.perl, slice.source .. "/Configure", target, shared and "shared" or "no-shared",
        "no-tests", "--prefix=" .. slice.prefix, "--openssldir=/etc/ssl", "--libdir=lib",
        "CC=" .. t.cc, "CFLAGS=" .. table.concat(t.cflags, " "), "AR=" .. t.ar, "RANLIB=" .. t.ranlib }
    -- libssl finds libcrypto beside itself; $$ is make's $, and the quotes keep the shell from expanding it
    if shared and t.rpath ~= "" then
        table.insert(configure, "LDFLAGS=-Wl,-rpath,'" .. (t.rpath:gsub("%$", "$$")) .. "'")
    end
    if options["no-deprecated"] then table.insert(configure, "no-deprecated") end
    otok.run(configure, { cwd = slice.build })
    otok.make{ "build_libs", cwd = slice.build }
    local install = { "install_dev", cwd = slice.build }
    if shared then table.insert(install, 2, "install_runtime_libs") end
    otok.make(install)

    local p = slice.prefix
    local ext = shared and ".so" or ".a"
    return {
        libraries = { ssl = otok.glob("lib/libssl" .. ext, p)[1], crypto = otok.glob("lib/libcrypto" .. ext, p)[1] },
        headers = p .. "/include",
    }
end
