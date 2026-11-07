-- nasm built by its configure and make; the generated sources are in the archive, so no perl is needed.
function build(slice, options, deps)
    local p = slice.prefix
    local env = { CC = slice.toolchain.cc, CFLAGS = table.concat(slice.toolchain.cflags, " ") }
    otok.run({ "sh", slice.source .. "/configure", "--prefix=" .. p }, { cwd = slice.build, env = env })
    otok.run({ slice.toolchains.make, "-j" .. slice.jobs, "nasm" }, { cwd = slice.build })
    otok.copy(slice.build .. "/nasm", p .. "/bin/nasm")
    return { programs = { nasm = p .. "/bin/nasm" } }
end
