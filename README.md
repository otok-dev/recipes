# otok recipes

Recipes for [otok](https://git.e-poison.com/sasha/otok) for libraries that have no other home: their
authors keep no recipe in their own repository, or the library is no longer maintained and needs fixes.
A recipe says where the source comes from, pinned by its hash or commit, which patches it needs, and how
it is built (`build.lua`), or, for a Swift package, that SwiftPM builds it.

Each directory is one library:

```text
<library>/
├── recipe.toml
├── build.lua        # not for Swift packages
└── patches/
```

The `main` branch holds the current recipe of each library. A published version is reached through the
otok index, whose entry pins the commit of this repository it was published from, so older recipes stay
available.

## Using a recipe before it is in the index

```toml
[deps.updates]
recipe = { git = "https://github.com/otok-dev/recipes", rev = "<commit>", path = "updates" }
```
