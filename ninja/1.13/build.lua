-- configure.py --bootstrap compiles ninja with the slice's C++ compiler (cl from Visual Studio's environment on Windows)
-- and leaves it in the working directory.
local function windows(slice)
    return slice.triple:find("windows") ~= nil
end

function build(slice, options, deps)
    local env = {}
    if not windows(slice) then env.CXX = slice.toolchain.cxx end
    -- the bootstrap runs ninja.bootstrap.exe by name from the working directory, which Windows does not search with this
    if windows(slice) then env.NoDefaultCurrentDirectoryInExePath = false end
    otok.run({ slice.toolchains.python, "configure.py", "--bootstrap" }, { cwd = slice.source, env = env })
    local name = windows(slice) and "ninja.exe" or "ninja"
    local program = slice.prefix .. "/bin/" .. name
    otok.copy(slice.source .. "/" .. name, program)
    return { programs = { ninja = program } }
end
