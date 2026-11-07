-- configure.py --bootstrap compiles ninja with cl from Visual Studio's environment and leaves it in the working
-- directory.
function build(slice, options, deps)
    -- the bootstrap runs ninja.bootstrap.exe by name from the working directory, which Windows does not search with this
    otok.run({ slice.toolchains.python, "configure.py", "--bootstrap" },
        { cwd = slice.source, env = { NoDefaultCurrentDirectoryInExePath = false } })
    local program = slice.prefix .. "/bin/ninja.exe"
    otok.copy(slice.source .. "/ninja.exe", program)
    return { programs = { ninja = program } }
end
