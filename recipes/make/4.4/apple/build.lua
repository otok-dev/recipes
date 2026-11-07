-- make built by build.sh after configure.
function build(slice, options, deps)
    local p = slice.prefix
    -- without Guile and NLS: make alone, which needs no library of the machine
    local args = { "sh", slice.source .. "/configure", "--prefix=" .. p, "--without-guile", "--disable-nls" }
    otok.run(args, { cwd = slice.build, env = { CC = slice.toolchain.cc } })
    otok.run({ "sh", slice.source .. "/build.sh" }, { cwd = slice.build })
    otok.copy(slice.build .. "/make", p .. "/bin/make")
    return { programs = { make = p .. "/bin/make" } }
end
