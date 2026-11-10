-- libsodium's own configure and make, the library only. What it installs: libsodium.a, or libsodium.so.
function build(slice, options, deps)
    local t = slice.toolchain
    -- the target in CC itself: libtool passes no --target of the flags to the link of a shared object, which clang
    -- would then link for the build machine, without Android's libc
    local env = { CC = t.cc .. " --target=" .. slice.triple, CXX = t.cxx .. " --target=" .. slice.triple }
    -- --disable-pie: position-independent executables are for libsodium's tests, not the library
    otok.autotools{ args = { "--disable-pie" }, env = env }
    local p = slice.prefix
    local lib = p .. (slice.linkage == "static" and "/lib/libsodium.a" or "/lib/libsodium.so")
    return { libraries = { sodium = lib }, headers = p .. "/include" }
end
