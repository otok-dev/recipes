# otok recipes

Recipes for [otok](https://git.e-poison.com/sasha/otok) for libraries that have no other home: their
authors keep no recipe in their own repository, or the library is no longer maintained and needs fixes.
A recipe says where the source comes from, pinned by its hash or commit, which patches it needs, and how
it is built (`build.lua`), or, for a Swift package, that SwiftPM builds it.

Each library has a directory, and each line of it that is maintained a directory inside it:

```text
<library>/
└── <line>/
    ├── recipe.toml
    ├── build.lua    # not for Swift packages
    └── patches/
```

All the lines of a library are versions of one recipe of the index (`apotocki/openssl` for every
`openssl/<line>/`); the line directories only let `main` hold the recipe of each line that still gets
fixes.

- The line is the version without its last part: `boost/1.92` for 1.92.0, `icu4c/79` for 79.1,
  `openssl/3.5` for 3.5.9. When the library releases its fixes otherwise, the line is named as the
  library names it.
- A new version or revision of a line updates its directory; a new line is a new directory. A line's
  name does not change once chosen.
- A line no longer maintained is removed from `main`.

A published version is reached through the otok index, whose entry pins the commit and the directory
of this repository it was published from, so older recipes stay available after their directory
changes or goes.

## Using a recipe before it is in the index

```toml
[deps.updates]
recipe = { git = "https://github.com/otok-dev/recipes", rev = "<commit>", path = "updates/2.0" }
```

## MSYS2 packages

The make recipe brings, on Windows, an MSYS2 tree of pinned packages: make and the shell and tools its rules
and configure scripts run. They are resources of the recipe, written by `tools/msys2-packages.py` (Python 3.14)
from the packages the recipe names and what they depend on, as the database of the MSYS2 repository gives them:

```sh
python tools/msys2-packages.py make/4.4/recipe.toml
```

It rewrites the lines between `# BEGIN MSYS2 packages: <packages>` and `# END MSYS2 packages` with today's
packages, checked against the SHA-256 of the database. The repository keeps older packages for a while, not
forever: a recipe whose packages are gone is pinned anew, with a new revision.

## License

The recipes and build scripts of this repository are dedicated to the public domain under [CC0 1.0](LICENSE).
A patch is under the license of the library it changes, as are the libraries the recipes build.
