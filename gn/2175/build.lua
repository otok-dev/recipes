-- build/gen.py writes out/build.ninja for the slice's compiler (cl and link from Visual Studio's environment on Windows),
-- ninja builds gn. The source has no .git, so gen.py cannot ask git for the commit position: the recipe writes it.
local position, commit = "2175", "b2afae122eeb"

local function windows(slice)
    return slice.triple:find("windows") ~= nil
end

function build(slice, options, deps)
    local out = slice.build .. "/out"
    local env = {}
    if not windows(slice) then
        env.CXX = slice.toolchain.cxx
        env.AR = slice.toolchain.ar
    end
    otok.run({ slice.toolchains.python, "build/gen.py", "--no-last-commit-position", "--out-path", out, "--allow-warnings" },
        { cwd = slice.source, env = env })
    otok.write(out .. "/last_commit_position.h", "// Written by the otok recipe of GN, as build/gen.py would from git.\n\n"
        .. "#ifndef OUT_LAST_COMMIT_POSITION_H_\n#define OUT_LAST_COMMIT_POSITION_H_\n\n"
        .. "#define LAST_COMMIT_POSITION_NUM " .. position .. "\n"
        .. "#define LAST_COMMIT_POSITION \"" .. position .. " (" .. commit .. ")\"\n\n"
        .. "#endif  // OUT_LAST_COMMIT_POSITION_H_\n")
    local name = windows(slice) and "gn.exe" or "gn"
    otok.run({ slice.toolchains.ninja, "-C", out, name }, { cwd = slice.source })
    local program = slice.prefix .. "/bin/" .. name
    otok.copy(out .. "/" .. name, program)
    return { programs = { gn = program } }
end
