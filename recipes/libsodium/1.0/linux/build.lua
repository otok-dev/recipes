-- libsodium's own configure and make, the library only. What it installs: libsodium.a, or libsodium.so with its links.
function build(slice, options, deps)
    -- --disable-pie: position-independent executables are for libsodium's tests, not the library
    otok.autotools{ args = { "--disable-pie" } }
    local p = slice.prefix
    local lib = p .. (slice.linkage == "static" and "/lib/libsodium.a" or "/lib/libsodium.so")
    return { libraries = { sodium = lib }, headers = p .. "/include" }
end
