-- libidn2's own configure and make, the library only: with the parts of libunistring built in, without gettext, documentation
-- and the idn2 program. What it installs: libidn2.a, or libidn2.so.
function build(slice, options, deps)
    local t = slice.toolchain
    -- the target in CC itself: libtool passes no --target of the flags to the link of a shared object, which clang
    -- would then link for the build machine, without Android's libc
    local env = { CC = t.cc .. " --target=" .. slice.triple, CXX = t.cxx .. " --target=" .. slice.triple }
    otok.autotools{ args = { "--with-included-libunistring", "--disable-nls", "--disable-doc", "--disable-gtk-doc", "--disable-rpath", "--without-libiconv-prefix" }, env = env }
    local p = slice.prefix
    local lib = otok.glob(slice.linkage == "static" and "lib/libidn2.a" or "lib/libidn2.so", p)[1]
    return { libraries = { idn2 = lib }, headers = p .. "/include" }
end
