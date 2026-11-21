-- oneTBB's CMake project, the libraries tbb and tbbmalloc only: no tbbmalloc_proxy (which replaces the program's malloc),
-- no tbbbind (hwloc), no Thread Composability Manager, tests or examples. What it installs: tbb12.lib and tbbmalloc.lib,
-- static or the import libraries of tbb12.dll and tbbmalloc.dll (tbb12_debug and tbbmalloc_debug in debug builds); the
-- headers in include/oneapi/tbb and include/tbb. The headers ask for tbb12.lib (or tbb12_debug.lib with _DEBUG) through
-- #pragma comment(lib), the name built here; they are the same for both linkages (oneTBB exports through .def files).
-- oneTBB calls a static library unsupported but builds one: it then loads nothing at run time (tbbmalloc, tbbbind), and
-- nothing waits for its worker threads at exit (no DllMain), which may then race the C runtime's own cleanup (a debug
-- program lost its buffered stdout): programs finalize the scheduler first (oneapi::tbb::task_scheduler_handle and
-- oneapi::tbb::finalize).
-- No IPO: static libraries would hold the compiler's intermediate code.
function build(slice, options, deps)
    local static = slice.linkage == "static"
    otok.cmake{ defines = {
        BUILD_SHARED_LIBS = not static, TBB_TEST = false, TBB_EXAMPLES = false, TBB_STRICT = false,
        TBB_BUILD = true, TBBMALLOC_BUILD = true, TBBMALLOC_PROXY_BUILD = false, TCM_BUILD = false,
        TBB_DISABLE_HWLOC_AUTOMATIC_SEARCH = true, TBB_ENABLE_IPO = false, TBB4PY_BUILD = false,
        TBB_VERIFY_DEPENDENCY_SIGNATURE = false, TBB_INSTALL = true, CMAKE_INSTALL_LIBDIR = "lib",
    } }
    local p = slice.prefix
    local libraries = {}
    for name, pattern in pairs{ tbb = "tbb12", tbbmalloc = "tbbmalloc" } do
        local link = otok.glob("lib/" .. pattern .. ".lib", p)[1] or otok.glob("lib/" .. pattern .. "_debug.lib", p)[1]
        libraries[name] = static and link or { link = link,
            runtime = otok.glob("bin/" .. pattern .. ".dll", p)[1] or otok.glob("bin/" .. pattern .. "_debug.dll", p)[1] }
    end
    return { libraries = libraries, headers = p .. "/include" }
end
