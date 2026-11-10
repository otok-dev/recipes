-- The MSYS2 packages unpacked into one tree in the prefix, as pacman would install them without their install scripts,
-- which nothing here needs. MSYS2 finds its root from msys-2.0.dll in usr/bin and reads etc/fstab there: drives without
-- a prefix (/c/…, as otok.autotools writes paths) and /tmp in the TEMP of the build, since the tree is in the cache and
-- read-only to the builds that run it.
local fstab = [[
none / cygdrive binary,posix=0,noacl,user 0 0
none /tmp usertemp binary,posix=0,noacl 0 0
]]

-- Sets IMAGE_DLLCHARACTERISTICS_DYNAMIC_BASE in the PE header of a program or DLL that has its relocations (MSYS2's
-- images all have them, few have the flag). Windows forces ASLR on the processes of an AppContainer, otok's sandbox
-- (otok's docs/PLAN.md decision 103): an image without the flag is moved to another address in each process, which
-- breaks the fork of the Cygwin runtime; one with it lands at the same address in every process.
local function set_dynamic_base(path)
    local image = otok.read(path)
    if #image < 0x40 or image:sub(1, 2) ~= "MZ" then return end
    local pe = string.unpack("<I4", image, 0x3C + 1)
    if #image < pe + 0x100 or image:sub(pe + 1, pe + 4) ~= "PE\0\0" then return end
    if string.unpack("<I2", image, pe + 22 + 1) & 0x0001 ~= 0 then return end  -- IMAGE_FILE_RELOCS_STRIPPED
    local optional = pe + 24
    local pe32_plus = string.unpack("<I2", image, optional + 1) == 0x20b
    local directories = optional + (pe32_plus and 112 or 96)
    local count = string.unpack("<I4", image, directories - 4 + 1)
    if count <= 5 or string.unpack("<I4", image, directories + 5 * 8 + 4 + 1) == 0 then return end  -- no .reloc
    local at = optional + 70  -- DllCharacteristics
    local flags = string.unpack("<I2", image, at + 1)
    if flags & 0x0040 ~= 0 then return end
    otok.write(path, image:sub(1, at) .. string.pack("<I2", flags | 0x0040) .. image:sub(at + 3))
end

function build(slice, options, deps)
    local p = slice.prefix
    for name, package in pairs(slice.resources) do
        if name:find("^msys2_") then otok.copy(package .. "/usr", p .. "/usr") end
    end
    for _, pattern in ipairs{ "**/*.exe", "**/*.dll" } do
        for _, file in ipairs(otok.glob(pattern, p .. "/usr")) do set_dynamic_base(file) end
    end
    -- half the tree, and no build reads it: builds run with LANG=C
    for _, dir in ipairs{ "doc", "info", "locale", "man" } do
        otok.remove(p .. "/usr/share/" .. dir)
    end
    otok.write(p .. "/etc/fstab", fstab)
    local bin = p .. "/usr/bin/"
    return { programs = { make = bin .. "make.exe", m4 = bin .. "m4.exe", as = bin .. "as.exe" } }
end
