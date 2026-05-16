# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

Run the full test suite:

```
make test
```

Run a single spec file:

```
nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedFile tests/utils_spec.lua {minimal_init = 'tests/minimal_init.lua'}" 2>&1
```

Tests require plenary.nvim at `~/.local/share/nvim/lazy/plenary.nvim`.

## Architecture

denim.nvim is a Neovim plugin. All modules live under `lua/denim/`. `plugin/denim.lua` is intentionally empty - setup is user-driven via `require("denim").setup()`.

### Module responsibilities

**`config.lua`** - holds `M.defaults` and the merged `M.options` table. All other modules call `require("denim.config").options` at call time (never at module load time, because `setup()` hasn't run yet).

**`utils.lua`** - pure Lua, no Neovim API. All functions are unit-testable in isolation: `slugify_title`, `slugify_tag`, `tags_from_filename`, `relative_path`, `rename_tag_in_filename`, `resolve_slug`, `find_link_path`.

**`notes.lua`** - all filesystem operations that act on the current buffer or create new files: `new_note`, `new_todo`, `new_note_from_template`, `new_todo_from_template`, `new_template`, `follow_link`, `todo_done`, `todo_undone`, `refactor`, `paste_image`. After any rename, it calls `telescope.update_links_to` to rewrite backlinks across all notes.

**`telescope.lua`** - all Telescope pickers and the backlink rewriter: `search_notes`, `search_content`, `search_tags`, `search_untagged`, `search_templates`, `insert_link`, `backlinks`, `pick_tags`, `pick_template`, `list_open_todos`, `list_done_todos`, `rename_tag`, `update_links_to`. `pick_tags` is an iterative picker - it re-opens itself when the user types a new tag name, accumulating selections until an empty Enter confirms.

**`index.lua`** - virtual `nofile` buffer listing all notes grouped by date with todo status markers. `_build_lines(notes)` is exported for unit testing.

**`stats.lua`** - virtual `nofile` buffer with note/todo counts, tag frequency, and monthly activity. Reads filenames only (no file contents except for linked-note counting).

**`init.lua`** - wires all keymaps, the `BufEnter` autocmd that sets `<CR>` for link following, and all `Denim*` user commands.

### Filename format

The filename is the metadata - no frontmatter, no database. All logic branches on this pattern:

```
YYYYMMDDTHHMMSS--slug__tag1_tag2.md    (note)
YYYYMMDDTHHMMSS-O-slug__tag1_tag2.md   (open todo)
YYYYMMDDTHHMMSS-X-slug__tag1_tag2.md   (done todo)
YYYYMMDDTHHMMSS--name.ext              (attachment)
```

- `--` separates timestamp from slug; `-O-` / `-X-` carry todo status
- `__` separates slug from tags; tags are `_`-separated
- Templates live in `notes_dir/.templates/` and are excluded from all searches
- The timestamp uses `os.date("%Y%m%dT%H%M%S")` and is always the leading component

### Rename pattern

Every operation that renames a file follows the same three steps, always in this order:

1. `vim.fn.rename(old, new)` - rename on disk
2. `telescope.update_links_to(old, new)` - rewrite all `[text](old_filename)` links in every note
3. `vim.cmd("edit " .. new)` then `vim.api.nvim_buf_delete(old_buf, { force = true })` - redirect the buffer

## Testing

- **`utils_spec.lua`** - unit tests for every function in `utils.lua`
- **`index_spec.lua`** - unit tests for `index._build_lines`
- **`stats_spec.lua`** - unit tests for stats computation
- **`integration_spec.lua`** - integration tests for all user-facing operations; each test creates a real temp directory, runs the function, and asserts on filesystem state and buffer state

New pure helpers belong in `utils.lua` with unit specs in `utils_spec.lua`. New user-facing operations belong in `notes.lua` or `telescope.lua` with integration specs. For every bug fixed, add a regression test that would have caught it.
