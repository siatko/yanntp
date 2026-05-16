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
- **`utils.lua`** - pure Lua helpers with no Neovim API dependency, fully unit-testable: `slugify_title`, `slugify_tag`, `tags_from_filename`, `relative_path`, `rename_tag_in_filename`, `resolve_slug`, `find_link_path`
- **`notes.lua`** - filesystem operations: `new_note`, `new_todo`, `new_note_from_template`, `new_todo_from_template`, `new_template`, `follow_link`, `todo_done`, `todo_undone`, `refactor` (rename + retag + update backlinks), `paste_image`
- **`telescope.lua`** - all Telescope pickers: `search_notes`, `search_content`, `search_tags`, `search_untagged`, `search_templates`, `insert_link`, `backlinks`, `pick_tags`, `pick_template`, `list_open_todos`, `list_done_todos`, `rename_tag`, `update_links_to` (called by notes.lua after any rename to rewrite backlinks)
- **`index.lua`** - virtual `nofile` buffer listing all notes grouped by date; `_build_lines` is exported for testing
- **`stats.lua`** - virtual `nofile` buffer with note/todo counts, tag usage, and monthly activity

**`plugin/denim.lua`** is intentionally empty - setup is user-driven via `require("denim").setup()`.

## Filename format

All logic branches on the filename pattern, so it's central to understand:

- Notes: `YYYYMMDD--slug__tag1_tag2.md`
- Open todos: `YYYYMMDD-O-slug__tag1_tag2.md`
- Done todos: `YYYYMMDD-X-slug__tag1_tag2.md`
- Attachments: `YYYYMMDD--name.ext`

Tags live after `__`, separated by `_`. The `tags_from_filename` utility extracts them; `slugify_tag` normalises them (spaces/hyphens become underscores).

## Testing

- **`tests/utils_spec.lua`** - unit tests for all pure helpers in `utils.lua`
- **`tests/index_spec.lua`** - unit tests for `index._build_lines`
- **`tests/stats_spec.lua`** - unit tests for stats computation helpers
- **`tests/integration_spec.lua`** - integration tests for all user-facing operations in `notes.lua` and `telescope.lua`; each test creates a real temp directory, exercises the function, and asserts on filesystem state and buffer state

New pure helpers belong in `utils.lua` and should get unit specs in `tests/utils_spec.lua`. New user-facing operations in `notes.lua` should get integration specs in `tests/integration_spec.lua`. For every bug fixed, add a regression test that would have caught it.
