# otok recipes

Recipes for [otok](https://github.com/otok-dev/otok) for libraries that have no other home: their
authors keep no recipe in their own repository, or the library is no longer maintained and needs fixes.
A recipe says where the source comes from, pinned by its hash or commit, which patches it needs, and how
it is built (`build.lua`), or, for a Swift package, that SwiftPM builds it.

Each library has a directory in `recipes/`, each line of it that is maintained a directory inside it, and each variant
of the line a directory inside that:

```text
recipes/
└── <library>/
    └── <line>/
        └── <variant>/
            ├── recipe.toml
            ├── build.lua    # not for Swift packages
            └── patches/
```

All the lines of a library are versions of one recipe of the index (`apotocki/openssl` for every
`recipes/openssl/<line>/`); the line directories only let `main` hold the recipe of each line that still gets
fixes.

- The line is the version without its last part: `recipes/boost/1.92` for 1.92.0, `recipes/icu4c/79` for 79.1,
  `recipes/openssl/3.5` for 3.5.9. When the library releases its fixes otherwise, the line is named as the library
  names it.
- A new version or revision of a line updates its directory; a new line is a new directory. A line's
  name does not change once chosen.
- A line no longer maintained is removed from `main`.
- A variant is the recipe for one target of otok and the build environments it names (`[platforms] supported` and
  `build-on`): `apple`, `android`, `linux`, `windows`, or, where one target is built in two ways, a name of its own
  (`recipes/boost/1.92/windows-msvc` with b2 and MSVC, `recipes/boost/1.92/windows-clang-cl` with Boost's CMake and
  clang-cl across from Linux). A recipe that builds in two ways needs no two variants when only its toolchains differ:
  `when = { environment }` of its `[toolchains]` (`recipes/openssl/4.1/windows`). Each variant directory is a whole recipe: a
  published recipe is exported alone, so variants share no file.
- Every recipe for Windows builds on Windows (`windows/msvc` or `windows/clang-cl`); building across from Linux
  (`linux/clang-cl`) is a second way, never the only one.
- The variants of a tool (cmake, ninja, perl, python, …) are those of the build machines: `apple` (macOS), `linux`,
  `windows`.
- Every toolchain a recipe names has its recipe here, given as its `default-recipe`
  (`cmake = { version = ">= 3.20", default-recipe = "apotocki/cmake" }`), so that no build needs a tool installed by hand.

A published version is reached through the otok index, whose entry pins the commit and the directory
of this repository it was published from, so older recipes stay available after their directory
changes or goes.

## Using a recipe before it is in the index

```toml
[deps.updates]
recipe = { git = "https://github.com/otok-dev/recipes", rev = "<commit>", path = "recipes/updates/2.0/apple" }
```

## MSYS2 packages

The make recipe brings, on Windows, an MSYS2 tree of pinned packages: make and the shell and tools its rules
and configure scripts run. They are resources of the recipe, written by `tools/msys2-packages.py` (Python 3.14)
from the packages the recipe names and what they depend on, as the database of the MSYS2 repository gives them:

```sh
python tools/msys2-packages.py recipes/make/4.4/windows/recipe.toml
```

It rewrites the lines between `# BEGIN MSYS2 packages: <packages>` and `# END MSYS2 packages` with today's
packages, checked against the SHA-256 of the database. The repository keeps older packages for a while, not
forever: a recipe whose packages are gone is pinned anew, with a new revision.

## License

What is written for these recipes (`recipe.toml`, `build.lua`, the build files and wrappers of a recipe, privacy
manifests, `tools/`) is dedicated to the public domain under [CC0 1.0](LICENSE). Not covered, and under their own
terms:

- patches (`patches/`): changes to a library's code, under the license of the library they change;
- texts of libraries' licenses kept beside their recipes (`recipes/lua/*/*/LICENSE`, `recipes/zxing-cpp/*/*/LICENSE-*`);
- files adapted from a library's own, each naming its origin and license in its header (`SPDX-License-Identifier`):
  - `recipes/zxing-cpp/3.1/android/android/CMakeLists.txt`, after zxing-cpp's Android wrapper: Apache-2.0;
  - `recipes/openssl/*/*/Configurations/60-otok.conf` and `recipes/openssl/4.1/windows/Configurations/platform/Windows/otok.pm`,
    extensions of OpenSSL's Configurations: Apache-2.0;
  - `recipes/boost/1.92/windows-clang-cl/cmake/CMakeLists.txt`, partly after Boost's superproject file: BSL-1.0.

A file taken or adapted from a library's sources gets that library's license identifier and a note of where it comes
from in its header. The libraries the recipes build are under their own licenses (`license` in `recipe.toml`).
