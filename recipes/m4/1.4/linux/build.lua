-- m4 built by its configure and make: its library of gnulib and the program, not the documentation and tests.
function build(slice, options, deps)
    local p = slice.prefix
    local env = { CC = slice.toolchain.cc, CFLAGS = table.concat(slice.toolchain.cflags, " ") }
    -- without NLS: m4 alone, which needs no library of the machine
    local args = { "sh", slice.source .. "/configure", "--prefix=" .. p, "--disable-nls", "--disable-dependency-tracking" }
    otok.run(args, { cwd = slice.build, env = env })
    otok.run({ slice.toolchains.make, "-j" .. slice.jobs, "-C", "lib" }, { cwd = slice.build })
    otok.run({ slice.toolchains.make, "-j" .. slice.jobs, "-C", "src" }, { cwd = slice.build })
    otok.copy(slice.build .. "/src/m4", p .. "/bin/m4")
    return { programs = { m4 = p .. "/bin/m4" } }
end
