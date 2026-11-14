-- flex built by its configure and make, the program alone (src/flex): the documentation needs help2man. It runs m4 as
-- $M4 or, without it, the m4 of PATH; bin/flex is a script giving it the m4 copied beside the program in libexec/flex/.
function build(slice, options, deps)
    local p = slice.prefix
    local m4 = deps.tools.m4.bin .. "/m4"
    -- _GNU_SOURCE: flex 2.6.4 calls reallocarray without declaring it otherwise, and a pointer returned as an int breaks
    -- it on 64-bit glibc
    local cflags = table.concat(slice.toolchain.cflags, " ") .. " -D_GNU_SOURCE"
    local env = { CC = slice.toolchain.cc, CFLAGS = cflags, M4 = m4 }
    -- without NLS and libfl: the program alone, which needs no library of the machine
    local args = { "sh", slice.source .. "/configure", "--prefix=" .. p, "--disable-nls", "--disable-libfl", "--disable-shared",
        "--disable-dependency-tracking" }
    otok.run(args, { cwd = slice.build, env = env })
    otok.run({ slice.toolchains.make, "-j" .. slice.jobs, "-C", "src", "flex" }, { cwd = slice.build })
    local libexec = p .. "/libexec/flex"
    otok.copy(slice.build .. "/src/flex", libexec .. "/flex")
    otok.copy(m4, libexec .. "/m4")
    -- the header of C++ scanners (%option c++), which they include
    otok.copy(slice.source .. "/src/FlexLexer.h", p .. "/include/FlexLexer.h")
    local program = p .. "/bin/flex"
    otok.write(program, [[
#!/bin/sh
# flex with the m4 beside it (the otok recipe apotocki/flex): flex runs $M4
# its directory without dirname or any program of PATH
case $0 in */*) bin=${0%/*} ;; *) bin=. ;; esac
here=$(CDPATH= cd -- "$bin/.." && pwd) || exit 1
M4="$here/libexec/flex/m4"
export M4
exec "$here/libexec/flex/flex" "$@"
]])
    otok.run({ "chmod", "755", program })
    return { programs = { flex = program } }
end
