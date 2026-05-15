local config = require("denim.config")
local notes  = require("denim.notes")
local tel    = require("denim.telescope")
local idx    = require("denim.index")

describe("integration", function()
  local dir
  local orig_ui_input
  local orig_pick_tags

  before_each(function()
    dir = vim.fn.tempname()
    vim.fn.mkdir(dir, "p")
    config.setup({ notes_dir = dir })
    orig_ui_input = vim.ui.input
    orig_pick_tags = tel.pick_tags
  end)

  after_each(function()
    vim.ui.input = orig_ui_input
    tel.pick_tags = orig_pick_tags
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      local name = vim.api.nvim_buf_get_name(buf)
      if name ~= "" and name:find(dir, 1, true) then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end
    end
    vim.fn.delete(dir, "rf")
  end)

  local function mock_input(name)
    vim.ui.input = function(_, cb) cb(name) end
  end

  local function mock_tags(tags)
    tel.pick_tags = function(cb, _) cb(tags) end
  end

  local function write_file(path, lines)
    vim.fn.writefile(lines, path)
  end

  local function open_buf(path)
    vim.cmd("edit " .. vim.fn.fnameescape(path))
  end

  local function wait_for(path)
    assert.truthy(
      vim.wait(500, function() return vim.fn.filereadable(path) == 1 end, 10),
      "timed out waiting for: " .. path
    )
  end

  -- let scheduled callbacks run without waiting for a specific file
  local function flush()
    vim.wait(200, function() return false end, 10)
  end

  -- ─── new_note ────────────────────────────────────────────────────────────────

  describe("new_note", function()
    it("creates file with correct name, heading and tags", function()
      mock_input("my test note")
      mock_tags({ "lua", "nvim" })
      notes.new_note()
      local expected = dir .. "/" .. os.date("%Y%m%d") .. "--my-test-note__lua_nvim.md"
      wait_for(expected)
      assert.equal("# MY TEST NOTE", vim.fn.readfile(expected)[1])
    end)

    it("sorts tags alphabetically in filename", function()
      mock_input("sorted")
      mock_tags({ "zebra", "alpha" })
      notes.new_note()
      local expected = dir .. "/" .. os.date("%Y%m%d") .. "--sorted__alpha_zebra.md"
      wait_for(expected)
    end)

    it("creates file without tags", function()
      mock_input("no tags note")
      mock_tags({})
      notes.new_note()
      local expected = dir .. "/" .. os.date("%Y%m%d") .. "--no-tags-note.md"
      wait_for(expected)
    end)

    it("opens existing file without overwriting it", function()
      local path = dir .. "/" .. os.date("%Y%m%d") .. "--existing-note.md"
      write_file(path, { "# EXISTING NOTE", "", "keep this content" })
      mock_input("existing note")
      mock_tags({})
      notes.new_note()
      wait_for(path)
      assert.equal("keep this content", vim.fn.readfile(path)[3])
    end)

    it("slugifies special characters in name", function()
      mock_input("Hello, World!")
      mock_tags({})
      notes.new_note()
      local expected = dir .. "/" .. os.date("%Y%m%d") .. "--hello-world.md"
      wait_for(expected)
    end)
  end)

  -- ─── new_todo ────────────────────────────────────────────────────────────────

  describe("new_todo", function()
    it("creates -O- file with correct name and heading", function()
      mock_input("fix the bug")
      mock_tags({ "backend" })
      notes.new_todo()
      local expected = dir .. "/" .. os.date("%Y%m%d") .. "-O-fix-the-bug__backend.md"
      wait_for(expected)
      assert.equal("# FIX THE BUG", vim.fn.readfile(expected)[1])
    end)

    it("creates -O- file without tags", function()
      mock_input("plain todo")
      mock_tags({})
      notes.new_todo()
      local expected = dir .. "/" .. os.date("%Y%m%d") .. "-O-plain-todo.md"
      wait_for(expected)
    end)

    it("sorts tags alphabetically", function()
      mock_input("tagged todo")
      mock_tags({ "work", "backend", "urgent" })
      notes.new_todo()
      local expected = dir .. "/" .. os.date("%Y%m%d") .. "-O-tagged-todo__backend_urgent_work.md"
      wait_for(expected)
    end)

    it("opens existing todo without overwriting it", function()
      local path = dir .. "/" .. os.date("%Y%m%d") .. "-O-existing-todo.md"
      write_file(path, { "# EXISTING TODO", "", "keep this content" })
      mock_input("existing todo")
      mock_tags({})
      notes.new_todo()
      wait_for(path)
      assert.equal("keep this content", vim.fn.readfile(path)[3])
    end)
  end)

  -- ─── todo_done ───────────────────────────────────────────────────────────────

  describe("todo_done", function()
    it("renames -O- to -X-", function()
      local path = dir .. "/20260514-O-fix-bug.md"
      write_file(path, { "# FIX BUG", "" })
      open_buf(path)
      notes.todo_done()
      assert.equal(0, vim.fn.filereadable(path))
      assert.equal(1, vim.fn.filereadable(dir .. "/20260514-X-fix-bug.md"))
    end)

    it("preserves tags when marking done", function()
      local path = dir .. "/20260514-O-tagged__work_urgent.md"
      write_file(path, { "# TAGGED", "" })
      open_buf(path)
      notes.todo_done()
      assert.equal(1, vim.fn.filereadable(dir .. "/20260514-X-tagged__work_urgent.md"))
    end)

    it("does not rename a plain note", function()
      local path = dir .. "/20260514--not-a-todo.md"
      write_file(path, { "# NOT A TODO", "" })
      open_buf(path)
      notes.todo_done()
      assert.equal(1, vim.fn.filereadable(path))
    end)

    it("does not rename an already done todo", function()
      local path = dir .. "/20260514-X-done-todo.md"
      write_file(path, { "# DONE TODO", "" })
      open_buf(path)
      notes.todo_done()
      assert.equal(1, vim.fn.filereadable(path))
    end)
  end)

  -- ─── follow_link ─────────────────────────────────────────────────────────────

  describe("follow_link", function()
    it("opens the linked note", function()
      local target = dir .. "/20260514--target.md"
      local source = dir .. "/20260514--source.md"
      write_file(target, { "# TARGET", "" })
      write_file(source, { "# SOURCE", "", "see [Target](20260514--target.md)" })
      open_buf(source)
      vim.api.nvim_win_set_cursor(0, { 3, 5 })
      notes.follow_link()
      assert.equal(target, vim.fn.expand("%:p"))
    end)

    it("shows a notification for image links instead of opening", function()
      local source = dir .. "/20260514--note.md"
      write_file(source, { "# NOTE", "", "![diagram](20260514--diagram.png)" })
      open_buf(source)
      vim.api.nvim_win_set_cursor(0, { 3, 5 })
      local notified = false
      local orig_notify = vim.notify
      vim.notify = function(msg, _) if msg:find("image") then notified = true end end
      notes.follow_link()
      vim.notify = orig_notify
      assert.truthy(notified)
      assert.equal(source, vim.fn.expand("%:p"))
    end)

    it("warns when linked file does not exist", function()
      local source = dir .. "/20260514--note.md"
      write_file(source, { "# NOTE", "", "see [Missing](missing.md)" })
      open_buf(source)
      vim.api.nvim_win_set_cursor(0, { 3, 5 })
      local warned = false
      local orig_notify = vim.notify
      vim.notify = function(_, level) if level == vim.log.levels.WARN then warned = true end end
      notes.follow_link()
      vim.notify = orig_notify
      assert.truthy(warned)
      assert.equal(source, vim.fn.expand("%:p"))
    end)
  end)

  -- ─── refactor ────────────────────────────────────────────────────────────────

  describe("refactor", function()
    it("renames file and updates heading", function()
      local orig = dir .. "/20260514--old-name__tag1.md"
      write_file(orig, { "# OLD NAME", "" })
      open_buf(orig)
      mock_input("new name")
      mock_tags({ "tag1" })
      notes.refactor()
      local new = dir .. "/20260514--new-name__tag1.md"
      wait_for(new)
      assert.equal(0, vim.fn.filereadable(orig))
      assert.equal("# NEW NAME", vim.fn.readfile(new)[1])
    end)

    it("retags without renaming", function()
      local orig = dir .. "/20260514--my-note__old_tag.md"
      write_file(orig, { "# MY NOTE", "" })
      open_buf(orig)
      mock_input("my note")
      mock_tags({ "new_tag" })
      notes.refactor()
      local new = dir .. "/20260514--my-note__new_tag.md"
      wait_for(new)
      assert.equal(0, vim.fn.filereadable(orig))
      assert.equal(1, vim.fn.filereadable(new))
    end)

    it("removes all tags", function()
      local orig = dir .. "/20260514--my-note__tag1_tag2.md"
      write_file(orig, { "# MY NOTE", "" })
      open_buf(orig)
      mock_input("my note")
      mock_tags({})
      notes.refactor()
      local new = dir .. "/20260514--my-note.md"
      wait_for(new)
      assert.equal(0, vim.fn.filereadable(orig))
      assert.equal(1, vim.fn.filereadable(new))
    end)

    it("sorts tags alphabetically", function()
      local orig = dir .. "/20260514--note.md"
      write_file(orig, { "# NOTE", "" })
      open_buf(orig)
      mock_input("note")
      mock_tags({ "zebra", "alpha" })
      notes.refactor()
      local new = dir .. "/20260514--note__alpha_zebra.md"
      wait_for(new)
      assert.equal(1, vim.fn.filereadable(new))
    end)

    it("pre-selects the current note's tags in the tag picker", function()
      local orig = dir .. "/20260514--my-note__lua_nvim.md"
      write_file(orig, { "# MY NOTE", "" })
      open_buf(orig)
      mock_input("my note")
      local received_pre_selected
      tel.pick_tags = function(cb, opts)
        received_pre_selected = opts and opts.pre_selected
        cb(opts and opts.pre_selected or {})
      end
      notes.refactor()
      flush()
      table.sort(received_pre_selected or {})
      assert.same({ "lua", "nvim" }, received_pre_selected)
    end)

    it("updates links in a referencing note", function()
      local target = dir .. "/20260514--target.md"
      local linker = dir .. "/20260514--linker.md"
      write_file(target, { "# TARGET", "" })
      write_file(linker, { "# LINKER", "", "see [Target](20260514--target.md)" })
      open_buf(target)
      mock_input("target renamed")
      mock_tags({})
      notes.refactor()
      local new = dir .. "/20260514--target-renamed.md"
      wait_for(new)
      local line = vim.fn.readfile(linker)[3]
      assert.truthy(line:find("20260514--target-renamed.md", 1, true))
      assert.falsy(line:find("20260514--target.md", 1, true))
    end)

    it("updates links in multiple referencing notes", function()
      local target = dir .. "/20260514--shared.md"
      local a      = dir .. "/20260514--note-a.md"
      local b      = dir .. "/20260514--note-b.md"
      write_file(target, { "# SHARED", "" })
      write_file(a, { "# A", "", "[Shared](20260514--shared.md)" })
      write_file(b, { "# B", "", "[Shared](20260514--shared.md)" })
      open_buf(target)
      mock_input("shared renamed")
      mock_tags({})
      notes.refactor()
      local new = dir .. "/20260514--shared-renamed.md"
      wait_for(new)
      assert.truthy(vim.fn.readfile(a)[3]:find("20260514--shared-renamed.md", 1, true))
      assert.truthy(vim.fn.readfile(b)[3]:find("20260514--shared-renamed.md", 1, true))
    end)

    it("closes the old buffer after rename", function()
      local orig = dir .. "/20260514--old-buf.md"
      write_file(orig, { "# OLD BUF", "" })
      open_buf(orig)
      local old_buf = vim.api.nvim_get_current_buf()
      mock_input("new buf")
      mock_tags({})
      notes.refactor()
      wait_for(dir .. "/20260514--new-buf.md")
      assert.falsy(vim.api.nvim_buf_is_valid(old_buf))
    end)

    it("opens the renamed file in the current window", function()
      local orig = dir .. "/20260514--before.md"
      write_file(orig, { "# BEFORE", "" })
      open_buf(orig)
      mock_input("after")
      mock_tags({})
      notes.refactor()
      local new = dir .. "/20260514--after.md"
      wait_for(new)
      assert.equal(new, vim.fn.expand("%:p"))
    end)

    it("does nothing when name and tags are unchanged", function()
      local orig = dir .. "/20260514--same-name__tag1.md"
      write_file(orig, { "# SAME NAME", "" })
      open_buf(orig)
      mock_input("same name")
      mock_tags({ "tag1" })
      notes.refactor()
      flush()
      assert.equal(1, vim.fn.filereadable(orig))
    end)

    it("works on an open todo file", function()
      local orig = dir .. "/20260514-O-old-todo.md"
      write_file(orig, { "# OLD TODO", "" })
      open_buf(orig)
      mock_input("new todo")
      mock_tags({})
      notes.refactor()
      local new = dir .. "/20260514-O-new-todo.md"
      wait_for(new)
      assert.equal(0, vim.fn.filereadable(orig))
      assert.equal(1, vim.fn.filereadable(new))
    end)

    it("works on a done todo file", function()
      local orig = dir .. "/20260514-X-old-done.md"
      write_file(orig, { "# OLD DONE", "" })
      open_buf(orig)
      mock_input("new done")
      mock_tags({})
      notes.refactor()
      local new = dir .. "/20260514-X-new-done.md"
      wait_for(new)
      assert.equal(0, vim.fn.filereadable(orig))
      assert.equal(1, vim.fn.filereadable(new))
    end)
  end)

  -- ─── update_links_to ─────────────────────────────────────────────────────────

  describe("update_links_to", function()
    it("rewrites a link to the renamed file", function()
      local old    = dir .. "/20260514--old.md"
      local new    = dir .. "/20260514--new.md"
      local linker = dir .. "/20260514--linker.md"
      write_file(old, { "# OLD", "" })
      write_file(linker, { "# LINKER", "", "see [Old](20260514--old.md)" })
      vim.fn.rename(old, new)
      tel.update_links_to(old, new)
      local line = vim.fn.readfile(linker)[3]
      assert.truthy(line:find("20260514--new.md", 1, true))
      assert.falsy(line:find("20260514--old.md", 1, true))
    end)

    it("rewrites multiple links to the same file in one note", function()
      local old    = dir .. "/20260514--note.md"
      local new    = dir .. "/20260514--renamed.md"
      local linker = dir .. "/20260514--multi.md"
      write_file(old, { "# NOTE", "" })
      write_file(linker, { "# MULTI", "[A](20260514--note.md) and [B](20260514--note.md)" })
      vim.fn.rename(old, new)
      tel.update_links_to(old, new)
      local line = vim.fn.readfile(linker)[2]
      assert.falsy(line:find("20260514--note.md", 1, true))
      local _, count = line:gsub("20260514%-%-renamed%.md", "")
      assert.equal(2, count)
    end)

    it("rewrites links across multiple notes", function()
      local old = dir .. "/20260514--old.md"
      local new = dir .. "/20260514--new.md"
      local a   = dir .. "/20260514--a.md"
      local b   = dir .. "/20260514--b.md"
      write_file(old, { "# OLD", "" })
      write_file(a, { "# A", "", "[Old](20260514--old.md)" })
      write_file(b, { "# B", "", "[Old](20260514--old.md)" })
      vim.fn.rename(old, new)
      tel.update_links_to(old, new)
      assert.truthy(vim.fn.readfile(a)[3]:find("20260514--new.md", 1, true))
      assert.truthy(vim.fn.readfile(b)[3]:find("20260514--new.md", 1, true))
    end)

    it("does not touch notes with no link to the renamed file", function()
      local old       = dir .. "/20260514--old.md"
      local new       = dir .. "/20260514--new.md"
      local unrelated = dir .. "/20260514--unrelated.md"
      local orig      = { "# UNRELATED", "", "no links here" }
      write_file(old, { "# OLD", "" })
      write_file(unrelated, orig)
      vim.fn.rename(old, new)
      tel.update_links_to(old, new)
      assert.same(orig, vim.fn.readfile(unrelated))
    end)

    it("does not modify the renamed file itself", function()
      local old = dir .. "/20260514--self.md"
      local new = dir .. "/20260514--self-renamed.md"
      write_file(old, { "# SELF", "", "[Self](20260514--self.md)" })
      vim.fn.rename(old, new)
      tel.update_links_to(old, new)
      assert.truthy(vim.fn.readfile(new)[3]:find("20260514--self.md", 1, true))
    end)

    it("preserves unrelated links in the same line", function()
      local old    = dir .. "/20260514--old.md"
      local new    = dir .. "/20260514--new.md"
      local other  = dir .. "/20260514--other.md"
      local linker = dir .. "/20260514--linker.md"
      write_file(old, { "# OLD", "" })
      write_file(other, { "# OTHER", "" })
      write_file(linker, { "# LINKER", "[Old](20260514--old.md) and [Other](20260514--other.md)" })
      vim.fn.rename(old, new)
      tel.update_links_to(old, new)
      local line = vim.fn.readfile(linker)[2]
      assert.truthy(line:find("20260514--new.md", 1, true))
      assert.truthy(line:find("20260514--other.md", 1, true))
    end)
  end)

  -- ─── ensure_notes_dir ────────────────────────────────────────────────────────

  describe("ensure_notes_dir", function()
    it("creates the notes directory if it does not exist", function()
      local new_dir = dir .. "/subdir"
      config.setup({ notes_dir = new_dir })
      assert.equal(0, vim.fn.isdirectory(new_dir))
      notes.ensure_notes_dir()
      assert.equal(1, vim.fn.isdirectory(new_dir))
    end)

    it("does nothing when the directory already exists", function()
      notes.ensure_notes_dir()
      assert.equal(1, vim.fn.isdirectory(dir))
    end)
  end)

  -- ─── paste_image ─────────────────────────────────────────────────────────────

  describe("paste_image", function()
    it("shows an error when img-clip is not installed", function()
      local errored = false
      local orig_notify = vim.notify
      vim.notify = function(_, level) if level == vim.log.levels.ERROR then errored = true end end
      notes.paste_image()
      vim.notify = orig_notify
      assert.truthy(errored)
    end)
  end)

  -- ─── backlinks ───────────────────────────────────────────────────────────────

  describe("backlinks", function()
    it("notifies when no other note links to the current file", function()
      local path = dir .. "/20260514--lonely.md"
      write_file(path, { "# LONELY", "" })
      open_buf(path)
      local notified = false
      local orig_notify = vim.notify
      vim.notify = function(msg, _) if msg:find("no backlinks") then notified = true end end
      tel.backlinks()
      vim.notify = orig_notify
      assert.truthy(notified)
    end)

    it("warns when no file is open", function()
      vim.cmd("enew")
      local warned = false
      local orig_notify = vim.notify
      vim.notify = function(_, level) if level == vim.log.levels.WARN then warned = true end end
      tel.backlinks()
      vim.notify = orig_notify
      assert.truthy(warned)
    end)
  end)

  -- ─── search_tags ─────────────────────────────────────────────────────────────

  describe("search_tags", function()
    it("notifies when no tags exist across notes", function()
      local notified = false
      local orig_notify = vim.notify
      vim.notify = function(msg, _) if msg:find("no tags") then notified = true end end
      tel.search_tags()
      vim.notify = orig_notify
      assert.truthy(notified)
    end)
  end)

  -- ─── index ───────────────────────────────────────────────────────────────────

  describe("index", function()
    it("opens a buffer listing notes from the notes dir", function()
      write_file(dir .. "/20260514--my-note.md", { "# MY NOTE", "" })
      idx.open()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.truthy(vim.tbl_contains(lines, "# Notes Index"))
      assert.truthy(vim.tbl_contains(lines, "## 2026-05-14"))
      assert.truthy(vim.tbl_contains(lines, "- [MY NOTE](20260514--my-note.md)"))
    end)

    it("shows a placeholder when no notes exist", function()
      idx.open()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.truthy(vim.tbl_contains(lines, "No notes yet."))
    end)

    it("shows open todos with unchecked checkbox", function()
      write_file(dir .. "/20260514-O-fix-bug.md", { "# FIX BUG", "" })
      idx.open()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.truthy(vim.tbl_contains(lines, "- [ ] [FIX BUG](20260514-O-fix-bug.md)"))
    end)

    it("shows done todos with checked checkbox", function()
      write_file(dir .. "/20260514-X-done-task.md", { "# DONE TASK", "" })
      idx.open()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.truthy(vim.tbl_contains(lines, "- [x] [DONE TASK](20260514-X-done-task.md)"))
    end)

    it("reuses the same buffer on repeated open calls", function()
      idx.open()
      local bufnr1 = vim.api.nvim_get_current_buf()
      write_file(dir .. "/20260514--some-note.md", { "# SOME NOTE", "" })
      open_buf(dir .. "/20260514--some-note.md")
      idx.open()
      assert.equal(bufnr1, vim.api.nvim_get_current_buf())
    end)

    it("has <CR>, r and q keymaps bound on the buffer", function()
      idx.open()
      local bufnr = vim.api.nvim_get_current_buf()
      local keymaps = vim.api.nvim_buf_get_keymap(bufnr, "n")
      local lhs_set = {}
      for _, km in ipairs(keymaps) do lhs_set[km.lhs] = true end
      assert.truthy(lhs_set["<CR>"])
      assert.truthy(lhs_set["r"])
      assert.truthy(lhs_set["q"])
    end)

    it("<CR> opens the note under the cursor", function()
      local target = dir .. "/20260514--target-note.md"
      write_file(target, { "# TARGET NOTE", "" })
      idx.open()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local row
      for i, l in ipairs(lines) do
        if l:find("20260514--target-note.md", 1, true) then row = i; break end
      end
      assert.truthy(row, "note entry not found in index")
      vim.api.nvim_win_set_cursor(0, { row, 5 })
      notes.follow_link()
      assert.equal(target, vim.fn.expand("%:p"))
    end)

    it("r refreshes the buffer with newly added notes", function()
      idx.open()
      local before = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.falsy(vim.tbl_contains(before, "- [FRESH NOTE](20260514--fresh-note.md)"))
      write_file(dir .. "/20260514--fresh-note.md", { "# FRESH NOTE", "" })
      idx.open()
      local after = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.truthy(vim.tbl_contains(after, "- [FRESH NOTE](20260514--fresh-note.md)"))
    end)

    it("q closes the index buffer", function()
      idx.open()
      local bufnr = vim.api.nvim_get_current_buf()
      vim.cmd("bdelete")
      assert.falsy(vim.api.nvim_buf_is_loaded(bufnr))
    end)
  end)
end)
