-- Windows: the MSYS2 packages unpacked into one tree in the prefix, as pacman would install them without their install
-- scripts, which nothing here needs. MSYS2 finds its root from msys-2.0.dll in usr/bin and reads etc/fstab there:
-- drives without a prefix (/c/…, as otok.autotools writes paths) and /tmp in the TEMP of the build, since the tree is
-- in the cache and read-only to the builds that run it. Elsewhere: make built by build.sh after configure.
local function windows(slice)
    return slice.triple:find("windows") ~= nil
end

local fstab = [[
none / cygdrive binary,posix=0,noacl,user 0 0
none /tmp usertemp binary,posix=0,noacl 0 0
]]

function build(slice, options, deps)
    local p = slice.prefix
    if windows(slice) then
        for name, package in pairs(slice.resources) do
            if name:find("^msys2_") then otok.copy(package .. "/usr", p .. "/usr") end
        end
        -- half the tree, and no build reads it: builds run with LANG=C
        for _, dir in ipairs{ "doc", "info", "locale", "man" } do
            otok.remove(p .. "/usr/share/" .. dir)
        end
        otok.write(p .. "/etc/fstab", fstab)
        return { programs = { make = p .. "/usr/bin/make.exe" } }
    end
    -- without Guile and NLS: make alone, which needs no library of the machine
    local args = { "sh", slice.source .. "/configure", "--prefix=" .. p, "--without-guile", "--disable-nls" }
    otok.run(args, { cwd = slice.build, env = { CC = slice.toolchain.cc } })
    otok.run({ "sh", slice.source .. "/build.sh" }, { cwd = slice.build })
    otok.copy(slice.build .. "/make", p .. "/bin/make")
    return { programs = { make = p .. "/bin/make" } }
end
