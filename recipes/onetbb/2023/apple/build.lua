-- oneTBB's CMake project, the libraries tbb and tbbmalloc only: no tbbmalloc_proxy (which replaces the program's malloc),
-- no tbbbind (hwloc), no Thread Composability Manager, tests or examples. What it installs: libtbb.a and
-- libtbbmalloc.a, or libtbb.12.dylib and libtbbmalloc.2.dylib with their links; the headers in include/oneapi/tbb and
-- include/tbb.
-- oneTBB calls a static library unsupported but builds one: it then loads nothing at run time (tbbmalloc, tbbbind), and
-- nothing waits for its worker threads at exit, which may then race the C runtime's own cleanup: programs finalize the
-- scheduler first (oneapi::tbb::task_scheduler_handle and oneapi::tbb::finalize).
-- No IPO: static libraries would hold the compiler's intermediate code.
-- Debug builds without TBB_USE_DEBUG, which oneTBB's own CMake targets give their consumers: the headers take it from
-- _DEBUG alone, which nothing defines here, and a library built with it beside a program built without it breaks (an
-- assertion in its intrusive lists).
function build(slice, options, deps)
    local static = slice.linkage == "static"
    for _, dir in ipairs{ "tbb", "tbbmalloc" } do
        local file = slice.source .. "/src/" .. dir .. "/CMakeLists.txt"
        local text, n = otok.read(file):gsub("%$<%$<CONFIG:DEBUG>:TBB_USE_DEBUG>", "")
        if n ~= 1 then error("nothing to patch in " .. file) end
        otok.write(file, text)
    end
    otok.cmake{ defines = {
        BUILD_SHARED_LIBS = not static, TBB_TEST = false, TBB_EXAMPLES = false, TBB_STRICT = false,
        TBB_BUILD = true, TBBMALLOC_BUILD = true, TBBMALLOC_PROXY_BUILD = false, TCM_BUILD = false,
        TBB_DISABLE_HWLOC_AUTOMATIC_SEARCH = true, TBB_ENABLE_IPO = false, TBB4PY_BUILD = false,
        TBB_INSTALL = true, CMAKE_INSTALL_LIBDIR = "lib",
    } }
    local p = slice.prefix
    local libraries = {}
    for _, name in ipairs{ "tbb", "tbbmalloc" } do
        local file = "lib/lib" .. name .. "%s." .. (static and "a" or "dylib")
        libraries[name] = otok.glob(file:format(""), p)[1] or otok.glob(file:format("_debug"), p)[1]
    end
    return { libraries = libraries, headers = p .. "/include" }
end
