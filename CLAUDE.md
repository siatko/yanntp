# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

Run the test suite:

```
make test
```

This runs plenary.nvim's test runner headlessly. Tests require plenary.nvim installed at `~/.local/share/nvim/lazy/plenary.nvim`.

## Architecture

denim.nvim is a Neovim plugin with a flat module structure under `lua/denim/`:

- **`init.lua`** - entry point; `setup()` wires keymaps, autocmds, and user commands by delegating to the other modules
- **`config.lua`** - holds defaults and the merged `options` table; all other modules call `require("denim.config").options` to read settings at call time (not at load time)
- **`utils.lua`** - pure Lua helpers: `slugify_title`, `slugify_tag`, `tags_from_filename`, `relative_path`; no Neovim API, fully unit-testable
- **`notes.lua`** - filesystem operations: create note/todo, follow link, mark todo done, refactor (rename + retag + update backlinks), paste image
- **`telescope.lua`** - all Telescope pickers: file search, content grep, tag picker, insert link, backlinks, todo lists, `update_links_to` (called by refactor to rewrite links in other notes)
- **`index.lua`** - virtual `nofile` buffer listing all notes grouped by date; `_build_lines` is exported for testing

**`plugin/denim.lua`** is intentionally empty - setup is user-driven via `require("denim").setup()`.

## Filename format

All logic branches on the filename pattern, so it's central to understand:

- Notes: `YYYYMMDD--slug__tag1_tag2.md`
- Open todos: `YYYYMMDD-O-slug__tag1_tag2.md`
- Done todos: `YYYYMMDD-X-slug__tag1_tag2.md`
- Attachments: `YYYYMMDD--name.ext`

Tags live after `__`, separated by `_`. The `tags_from_filename` utility extracts them; `slugify_tag` normalises them (spaces/hyphens become underscores).

## Testing notes

Only pure functions in `utils.lua` and `index._build_lines` are unit-tested. Filesystem and UI operations are not tested. New pure helpers belong in `utils.lua` and should get specs in `tests/utils_spec.lua`.
