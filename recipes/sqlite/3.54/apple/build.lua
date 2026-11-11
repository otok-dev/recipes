-- SQLite through the recipe's CMakeLists.txt, the library of the amalgamation only. What it installs: libsqlite3.a, or libsqlite3.dylib with its links.
function build(slice, options, deps)
    otok.copy(slice.recipe .. "/CMakeLists.txt", slice.source .. "/CMakeLists.txt")
    local defines = { "SQLITE_THREADSAFE=1" }
    local function add(name, on) if on then defines[#defines + 1] = name end end
    add("SQLITE_ENABLE_FTS5", options.fts5)
    add("SQLITE_ENABLE_RTREE", options.rtree)
    add("SQLITE_ENABLE_GEOPOLY", options.rtree)
    add("SQLITE_ENABLE_MATH_FUNCTIONS", options.math)
    add("SQLITE_ENABLE_COLUMN_METADATA", options["column-metadata"])
    add("SQLITE_OMIT_LOAD_EXTENSION", not options.extensions)
    otok.cmake{ defines = { SQLITE_DEFINES = table.concat(defines, ";") } }
    local p = slice.prefix
    return { libraries = { sqlite3 = otok.glob(slice.linkage == "static" and "lib/libsqlite3.a" or "lib/libsqlite3.dylib", p)[1] }, headers = p .. "/include" }
end
