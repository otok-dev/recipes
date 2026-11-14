-- The acl package's own configure and make, libacl only: the library, its two headers (sys/acl.h, acl/libacl.h) and
-- libacl.pc, without gettext and the getfacl, setfacl and chacl programs. attr/error_context.h comes from the attr
-- resource. What it installs: libacl.a, or libacl.so with its links.
function build(slice, options, deps)
    local attr_include = slice.source .. "/otok-attr-include"
    otok.copy(slice.resources.attr .. "/include/error_context.h", attr_include .. "/attr/error_context.h")
    otok.autotools{
        args = { "--disable-nls", "--disable-rpath", "CPPFLAGS=-I" .. attr_include },
        targets = { "libacl.la", "install-libLTLIBRARIES", "install-data-local", "install-pkgconfDATA" },
    }
    local p = slice.prefix
    local lib = otok.glob(slice.linkage == "static" and "lib/libacl.a" or "lib/libacl.so", p)[1]
    return { libraries = { acl = lib }, headers = p .. "/include" }
end
