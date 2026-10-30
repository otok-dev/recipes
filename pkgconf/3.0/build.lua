-- pkgconf's meson build: pkgconf with libpkgconf linked in (tool slices are static). Its default search path, built
-- in, is a directory of the prefix that holds no .pc file, so only the paths a build gives are searched.
function build(slice, options, deps)
    otok.meson{}
    local program = otok.glob("bin/pkgconf.exe", slice.prefix)[1] or otok.glob("bin/pkgconf", slice.prefix)[1]
    return { programs = { ["pkg-config"] = program } }
end
