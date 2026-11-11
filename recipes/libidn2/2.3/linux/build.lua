-- libidn2's own configure and make, the library only: with the parts of libunistring built in, without gettext, documentation
-- and the idn2 program. What it installs: libidn2.a, or libidn2.so with its links.
function build(slice, options, deps)
    otok.autotools{ args = { "--with-included-libunistring", "--disable-nls", "--disable-doc", "--disable-gtk-doc", "--disable-rpath", "--without-libiconv-prefix" } }
    local p = slice.prefix
    local lib = otok.glob(slice.linkage == "static" and "lib/libidn2.a" or "lib/libidn2.so", p)[1]
    return { libraries = { idn2 = lib }, headers = p .. "/include" }
end
