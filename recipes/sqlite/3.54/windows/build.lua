-- SQLite through the recipe's CMakeLists.txt, the library of the amalgamation only. What it installs: sqlite3.lib (static), or sqlite3.lib, the import library, with sqlite3.dll.
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
    local lib = otok.glob("lib/sqlite3.lib", p)[1]
    local dll = otok.glob("bin/sqlite3.dll", p)[1]
    return { libraries = { sqlite3 = dll and { link = lib, runtime = dll } or lib }, headers = p .. "/include" }
end
