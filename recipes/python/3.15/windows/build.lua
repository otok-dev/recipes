-- The interpreter of the build machine: the embeddable package (python.exe beside its python314.zip and DLLs) copied
-- into bin/ and made an installation: its python314._pth would make it ignore PYTHONPATH, which builds use (ICU's
-- configure: PYTHONPATH=… python -m icutools…), and without that file it would take the paths of an installed Python of
-- its version from the registry, finding no Lib\os.py(c) beside it. So its standard library is unpacked into Lib/, by
-- the interpreter itself while its ._pth still holds, and the ._pth removed.
function build(slice, options, deps)
    local r = slice.resources
    local embeddable = r.windows_x86_64 or r.windows_arm64
    if not embeddable then error("no embeddable Python for this build machine") end
    local bin = slice.prefix .. "/bin"
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
