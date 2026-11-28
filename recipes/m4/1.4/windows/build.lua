-- m4 built by its configure and make under the MSYS2 of the make recipe, with MSVC: cl compiles through the compile
-- script of the release (automake's, which gives cl -o and -l as it takes them), GNU ar of the tree makes the archive of
-- gnulib. Its library and the program, not the documentation and tests (gnulib's tests need windres).

-- A path as the programs of MSYS2 name it: C:/x is /c/x.
local function msys(path)
    return (path:gsub("^(%a):/", function(drive) return "/" .. drive:lower() .. "/" end))
end

-- MSVC's options with '-': MSYS2 takes /O2 for a path and turns it into C:/…/O2 for native programs
local function joined(flags)
    local all = {}
    for _, f in ipairs(flags) do all[#all + 1] = (f:gsub("^/", "-")) end
    return table.concat(all, " ")
end

function build(slice, options, deps)
    local bin = msys(slice.toolchains.make):match("^(.*)/[^/]*$")
    local args = {
        -- native Windows as gnulib knows it, the build machine the same: configure runs its test programs
        "--build=x86_64-w64-mingw32", "--host=x86_64-w64-mingw32",
        "CC=" .. msys(slice.source) .. "/build-aux/compile cl -nologo",
        "CFLAGS=" .. joined(slice.toolchain.cflags),
        "AR=" .. bin .. "/ar",
        -- syscmd and esyscmd through cmd /c, m4's own way on Windows; configure would take the sh of MSYS2 it runs in
        "--with-syscmd-shell=cmd",
        -- without NLS: m4 alone, which needs no library of the machine
        "--disable-nls", "--disable-dependency-tracking",
        -- the manual is in the release; nothing remakes it
        "MAKEINFO=true",
    }
    -- configure by a relative path, as cl cannot open the /c/… of $srcdir
    otok.autotools{
        configure = "../" .. slice.source:match("([^/]+)$") .. "/configure", args = args, cwd = slice.build,
        targets = { "-C", "lib" },
        env = { CC = false, CFLAGS = false, CPPFLAGS = false, LDFLAGS = false },
    }
    otok.make{ args = { "-C", "src" }, cwd = slice.build }
    local program = slice.prefix .. "/bin/m4.exe"
    otok.copy(slice.build .. "/src/m4.exe", program)
    return { programs = { m4 = program } }
end
