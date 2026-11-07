-- perl's own Configure, then make in the source tree, where Configure works.
function build(slice, options, deps)
    local p = slice.prefix
    local make = slice.toolchains.make
    -- no questions (-des); @INC relative to the program, which runs from the cache, not from where it was built; no
    -- manuals; none of the machine's database libraries, and no crypt(): libcrypt is libxcrypt's, not glibc's, so the
    -- libraries are glibc's alone
    otok.run({ "sh", "Configure", "-des", "-Dprefix=" .. p, "-Duserelocatableinc", "-Dman1dir=none", "-Dman3dir=none",
        "-Dcc=" .. slice.toolchain.cc, "-Dmake=" .. make, "-Ui_db", "-Ui_gdbm", "-Ui_ndbm", "-Ui_dbm", "-Ui_crypt", "-Ud_crypt",
        "-Ud_crypt_r", "-Dlibs=-lpthread -ldl -lm" }, { cwd = slice.source })
    otok.run({ make, "-j" .. slice.jobs }, { cwd = slice.source })
    otok.run({ make, "install" }, { cwd = slice.source })
    return { programs = { perl = p .. "/bin/perl" } }
end
