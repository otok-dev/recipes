-- configure.py --bootstrap compiles ninja with the slice's C++ compiler and leaves it in the working directory.
function build(slice, options, deps)
    otok.run({ slice.toolchains.python, "configure.py", "--bootstrap" }, { cwd = slice.source, env = { CXX = slice.toolchain.cxx } })
    local program = slice.prefix .. "/bin/ninja"
    otok.copy(slice.source .. "/ninja", program)
    return { programs = { ninja = program } }
end
