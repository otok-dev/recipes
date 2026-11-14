-- Bison built by its configure and make (the documentation is in the archive, nothing needs help2man), not installed:
-- the program is copied into libexec/bison/ with the m4 it runs, the skeletons of data/ into share/bison/, and bin/bison
-- is a script giving it both ($M4 and $BISON_PKGDATADIR), wherever the prefix is.
function build(slice, options, deps)
    local p = slice.prefix
    local m4 = deps.tools.m4.bin .. "/m4"
    local env = { CC = slice.toolchain.cc, CFLAGS = table.concat(slice.toolchain.cflags, " "), M4 = m4 }
    -- without NLS and yacc: the program alone, which needs no library of the machine
    local args = { "sh", slice.source .. "/configure", "--prefix=" .. p, "--disable-nls", "--disable-yacc",
        "--disable-dependency-tracking" }
    otok.run(args, { cwd = slice.build, env = env })
    otok.run({ slice.toolchains.make, "-j" .. slice.jobs }, { cwd = slice.build })
    local libexec = p .. "/libexec/bison"
    otok.copy(slice.build .. "/src/bison", libexec .. "/bison")
    otok.copy(m4, libexec .. "/m4")
    local data = p .. "/share/bison"
    otok.copy(slice.source .. "/data", data)
    otok.remove(data .. "/local.mk")
    local program = p .. "/bin/bison"
    otok.write(program, [[
#!/bin/sh
# Bison with the m4 beside it and its skeletons (the otok recipe apotocki/bison): it runs $M4 and reads $BISON_PKGDATADIR
# its directory without dirname or any program of PATH
case $0 in */*) bin=${0%/*} ;; *) bin=. ;; esac
here=$(CDPATH= cd -- "$bin/.." && pwd) || exit 1
M4="$here/libexec/bison/m4"
BISON_PKGDATADIR="$here/share/bison"
export M4 BISON_PKGDATADIR
exec "$here/libexec/bison/bison" "$@"
]])
    otok.run({ "chmod", "755", program })
    return { programs = { bison = program } }
end
