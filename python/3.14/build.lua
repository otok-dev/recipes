-- The interpreter of the build machine, copied whole into the prefix: the embeddable package (python.exe beside its
-- python314.zip and DLLs) into bin/; a python-build-standalone build as it is laid out, bin/python3 beside lib/python3.14.
-- The embeddable package is made an installation: its python314._pth would make it ignore PYTHONPATH, which builds
-- use (ICU's configure: PYTHONPATH=… python -m icutools…), and without that file it would take the paths of an
-- installed Python of its version from the registry, finding no Lib\os.py(c) beside it. So its standard library is
-- unpacked into Lib/, by the interpreter itself while its ._pth still holds, and the ._pth removed.
function build(slice, options, deps)
    local r = slice.resources
    local p = slice.prefix
    local embeddable = r.windows_x86_64 or r.windows_arm64
    if embeddable then
        local bin = p .. "/bin"
        otok.copy(embeddable, bin)
        local zip = otok.glob("python3*.zip", bin)[1]
        local pth = otok.glob("python3*._pth", bin)[1]
        if not zip or not pth then error("the embeddable package has no python3*.zip or python3*._pth") end
        otok.run({ bin .. "/python.exe", "-I", "-c", "import sys, zipfile; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])",
            zip, bin .. "/Lib" })
        otok.remove(zip)
        otok.remove(pth)
        return { programs = { python = bin .. "/python.exe" } }
    end
    local standalone = r.macos_arm64 or r.macos_x86_64 or r.linux_x86_64 or r.linux_arm64
    if not standalone then error("no prebuilt Python for this build machine") end
    for _, dir in ipairs{ "bin", "lib" } do
        otok.copy(standalone .. "/" .. dir, p .. "/" .. dir)
    end
    return { programs = { python = p .. "/bin/python3" } }
end
