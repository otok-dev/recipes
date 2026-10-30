-- meson.py beside the mesonbuild package, as the release archive has them: meson.py imports mesonbuild from its own
-- directory. Nothing is compiled.
function build(slice, options, deps)
    local p = slice.prefix
    otok.copy(slice.source .. "/meson.py", p .. "/meson.py")
    otok.copy(slice.source .. "/mesonbuild", p .. "/mesonbuild")
    return { programs = { meson = { script = p .. "/meson.py", interpreter = "python" } } }
end
