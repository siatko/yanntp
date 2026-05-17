local config = require("denim.config")
local notes  = require("denim.notes")
local tel    = require("denim.telescope")
local idx    = require("denim.index")
local st     = require("denim.stats")

describe("integration", function()
  local dir
  local orig_ui_input
  local orig_pick_tags
  local orig_pick_template

  before_each(function()
    dir = vim.fn.tempname()
    vim.fn.mkdir(dir, "p")
    config.setup({ notes_dir = dir })
    orig_ui_input     = vim.ui.input
    orig_pick_tags    = tel.pick_tags
    orig_pick_template = tel.pick_template
  end)

  after_each(function()
    vim.ui.input      = orig_ui_input
    tel.pick_tags     = orig_pick_tags
    tel.pick_template = orig_pick_template
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

  local function mock_template(path)
    tel.pick_template = function(cb) cb(path) end
  end

  local function make_template(name, lines)
    vim.fn.mkdir(dir .. "/.templates", "p")
    write_file(dir .. "/.templates/" .. name .. ".md", lines)
    return dir .. "/.templates/" .. name .. ".md"
  end

  -- ─── config ──────────────────────────────────────────────────────────────────

  describe("config", function()
    it("resolves symlinks in notes_dir", function()
      local real = vim.fn.tempname()
      vim.fn.mkdir(real, "p")
      local link = vim.fn.tempname()
      vim.fn.system("ln -s " .. vim.fn.shellescape(real) .. " " .. vim.fn.shellescape(link))
      config.setup({ notes_dir = link })
      local resolved = vim.fn.resolve(link)
      assert.equal(resolved, config.options.notes_dir)
      vim.fn.delete(link)
      vim.fn.delete(real, "rf")
      config.setup({ notes_dir = dir })
    end)
  end)

  -- ─── new_note ────────────────────────────────────────────────────────────────

  describe("new_note", function()
    it("creates file with correct name and tags", function()
      mock_input("my test note")
      mock_tags({ "lua", "nvim" })
      notes.new_note()
      local expected = dir .. "/" .. os.date("%Y%m%dT%H%M%S") .. "--my-test-note__lua_nvim.md"
      wait_for(expected)
    end)

    it("sorts tags alphabetically in filename", function()
      mock_input("sorted")
      mock_tags({ "zebra", "alpha" })
      notes.new_note()
      local expected = dir .. "/" .. os.date("%Y%m%dT%H%M%S") .. "--sorted__alpha_zebra.md"
      wait_for(expected)
    end)

    it("creates file without tags", function()
      mock_input("no tags note")
      mock_tags({})
      notes.new_note()
      local expected = dir .. "/" .. os.date("%Y%m%dT%H%M%S") .. "--no-tags-note.md"
      wait_for(expected)
    end)

    it("opens existing file without overwriting it", function()
      local path = dir .. "/" .. os.date("%Y%m%dT%H%M%S") .. "--existing-note.md"
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
      local expected = dir .. "/" .. os.date("%Y%m%dT%H%M%S") .. "--hello-world.md"
      wait_for(expected)
    end)

    it("does nothing when name input is cancelled", function()
      mock_input(nil)
      notes.new_note()
      flush()
      assert.same({}, vim.fn.glob(dir .. "/*.md", false, true))
    end)

    it("does nothing when name input is empty string", function()
      mock_input("")
      notes.new_note()
      flush()
      assert.same({}, vim.fn.glob(dir .. "/*.md", false, true))
    end)
  end)

  -- ─── new_todo ────────────────────────────────────────────────────────────────

  describe("new_todo", function()
    it("creates -O- file with correct name", function()
      mock_input("fix the bug")
      mock_tags({ "backend" })
      notes.new_todo()
      local expected = dir .. "/" .. os.date("%Y%m%dT%H%M%S") .. "-O-fix-the-bug__backend.md"
      wait_for(expected)
    end)

    it("creates -O- file without tags", function()
      mock_input("plain todo")
      mock_tags({})
      notes.new_todo()
      local expected = dir .. "/" .. os.date("%Y%m%dT%H%M%S") .. "-O-plain-todo.md"
      wait_for(expected)
    end)

    it("sorts tags alphabetically", function()
      mock_input("tagged todo")
      mock_tags({ "work", "backend", "urgent" })
      notes.new_todo()
      local expected = dir .. "/" .. os.date("%Y%m%dT%H%M%S") .. "-O-tagged-todo__backend_urgent_work.md"
      wait_for(expected)
    end)

    it("opens existing todo without overwriting it", function()
      local path = dir .. "/" .. os.date("%Y%m%dT%H%M%S") .. "-O-existing-todo.md"
      write_file(path, { "# EXISTING TODO", "", "keep this content" })
      mock_input("existing todo")
      mock_tags({})
      notes.new_todo()
      wait_for(path)
      assert.equal("keep this content", vim.fn.readfile(path)[3])
    end)

    it("does nothing when name input is cancelled", function()
      mock_input(nil)
      notes.new_todo()
      flush()
      assert.same({}, vim.fn.glob(dir .. "/*.md", false, true))
    end)

    it("does nothing when name input is empty string", function()
      mock_input("")
      notes.new_todo()
      flush()
      assert.same({}, vim.fn.glob(dir .. "/*.md", false, true))
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

    it("warns when the current file is an already-done todo", function()
      local path = dir .. "/20260514-X-done-todo.md"
      write_file(path, { "# DONE TODO", "" })
      open_buf(path)
      local warned = false
      local orig_notify = vim.notify
      vim.notify = function(_, level) if level == vim.log.levels.WARN then warned = true end end
      notes.todo_done()
      vim.notify = orig_notify
      assert.truthy(warned)
    end)

    it("warns when the current file is outside the notes directory", function()
      local tmp = vim.fn.tempname() .. "-O-outside.md"
      write_file(tmp, { "# OUTSIDE TODO", "" })
      open_buf(tmp)
      local warned = false
      local orig_notify = vim.notify
      vim.notify = function(_, level) if level == vim.log.levels.WARN then warned = true end end
      notes.todo_done()
      vim.notify = orig_notify
      assert.truthy(warned)
      assert.equal(1, vim.fn.filereadable(tmp))
      vim.fn.delete(tmp)
    end)

    it("updates backlinks when marking done", function()
      local path   = dir .. "/20260514-O-fix-bug.md"
      local linker = dir .. "/20260514--linker.md"
      write_file(path,   { "# FIX BUG", "" })
      write_file(linker, { "# LINKER", "", "see [Fix Bug](20260514-O-fix-bug.md)" })
      open_buf(path)
      notes.todo_done()
      local line = vim.fn.readfile(linker)[3]
      assert.truthy(line:find("20260514-X-fix-bug.md", 1, true))
      assert.falsy(line:find("20260514-O-fix-bug.md", 1, true))
    end)

    it("closes the old buffer after marking done", function()
      local path = dir .. "/20260514-O-close-me.md"
      write_file(path, { "# CLOSE ME", "" })
      open_buf(path)
      local old_buf = vim.api.nvim_get_current_buf()
      notes.todo_done()
      assert.falsy(vim.api.nvim_buf_is_valid(old_buf))
    end)

    it("opens the done file in the current window", function()
      local path = dir .. "/20260514-O-open-done.md"
      write_file(path, { "# OPEN DONE", "" })
      open_buf(path)
      notes.todo_done()
      assert.equal(dir .. "/20260514-X-open-done.md", vim.fn.expand("%:p"))
    end)
  end)

  -- ─── todo_undone ─────────────────────────────────────────────────────────────

  describe("todo_undone", function()
    it("renames -X- to -O-", function()
      local path = dir .. "/20260514-X-fix-bug.md"
      write_file(path, { "# FIX BUG", "" })
      open_buf(path)
      notes.todo_undone()
      assert.equal(0, vim.fn.filereadable(path))
      assert.equal(1, vim.fn.filereadable(dir .. "/20260514-O-fix-bug.md"))
    end)

    it("preserves tags when reopening", function()
      local path = dir .. "/20260514-X-tagged__work_urgent.md"
      write_file(path, { "# TAGGED", "" })
      open_buf(path)
      notes.todo_undone()
      assert.equal(1, vim.fn.filereadable(dir .. "/20260514-O-tagged__work_urgent.md"))
    end)

    it("does not rename a plain note", function()
      local path = dir .. "/20260514--not-a-todo.md"
      write_file(path, { "# NOT A TODO", "" })
      open_buf(path)
      notes.todo_undone()
      assert.equal(1, vim.fn.filereadable(path))
    end)

    it("does not rename an open todo", function()
      local path = dir .. "/20260514-O-open-todo.md"
      write_file(path, { "# OPEN TODO", "" })
      open_buf(path)
      notes.todo_undone()
      assert.equal(1, vim.fn.filereadable(path))
    end)

    it("warns when the current file is outside the notes directory", function()
      local tmp = vim.fn.tempname() .. "-X-outside.md"
      write_file(tmp, { "# OUTSIDE TODO", "" })
      open_buf(tmp)
      local warned = false
      local orig_notify = vim.notify
      vim.notify = function(_, level) if level == vim.log.levels.WARN then warned = true end end
      notes.todo_undone()
      vim.notify = orig_notify
      assert.truthy(warned)
      assert.equal(1, vim.fn.filereadable(tmp))
      vim.fn.delete(tmp)
    end)

    it("updates backlinks when reopening", function()
      local path   = dir .. "/20260514-X-fix-bug.md"
      local linker = dir .. "/20260514--linker.md"
      write_file(path,   { "# FIX BUG", "" })
      write_file(linker, { "# LINKER", "", "see [Fix Bug](20260514-X-fix-bug.md)" })
      open_buf(path)
      notes.todo_undone()
      local line = vim.fn.readfile(linker)[3]
      assert.truthy(line:find("20260514-O-fix-bug.md", 1, true))
      assert.falsy(line:find("20260514-X-fix-bug.md", 1, true))
    end)

    it("closes the old buffer after reopening", function()
      local path = dir .. "/20260514-X-close-me.md"
      write_file(path, { "# CLOSE ME", "" })
      open_buf(path)
      local old_buf = vim.api.nvim_get_current_buf()
      notes.todo_undone()
      assert.falsy(vim.api.nvim_buf_is_valid(old_buf))
    end)

    it("opens the reopened file in the current window", function()
      local path = dir .. "/20260514-X-open-me.md"
      write_file(path, { "# OPEN ME", "" })
      open_buf(path)
      notes.todo_undone()
      assert.equal(dir .. "/20260514-O-open-me.md", vim.fn.expand("%:p"))
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

    it("does nothing when there is no link on the current line", function()
      local path = dir .. "/20260514--no-links.md"
      write_file(path, { "# NO LINKS", "", "just plain text here" })
      open_buf(path)
      vim.api.nvim_win_set_cursor(0, { 3, 5 })
      notes.follow_link()
      assert.equal(path, vim.fn.expand("%:p"))
    end)

    it("opens URLs in the browser without warning", function()
      local source = dir .. "/20260514--note.md"
      write_file(source, { "# NOTE", "", "watch [this](https://youtube.com/watch?v=dQw4w9WgXcQ)" })
      open_buf(source)
      vim.api.nvim_win_set_cursor(0, { 3, 8 })
      local warned = false
      local orig_notify = vim.notify
      vim.notify = function(_, level) if level == vim.log.levels.WARN then warned = true end end
      local launched = false
      local orig_jobstart = vim.fn.jobstart
      vim.fn.jobstart = function(cmd, _) if cmd[1] == "xdg-open" then launched = true end end
      notes.follow_link()
      vim.fn.jobstart = orig_jobstart
      vim.notify = orig_notify
      assert.truthy(launched)
      assert.is_false(warned)
      assert.equal(source, vim.fn.expand("%:p"))
    end)

    it("does nothing when the current file is outside the notes directory", function()
      local tmp = vim.fn.tempname() .. ".md"
      write_file(tmp, { "# OUTSIDE", "", "see [Target](some-note.md)" })
      open_buf(tmp)
      vim.api.nvim_win_set_cursor(0, { 3, 5 })
      notes.follow_link()
      assert.equal(tmp, vim.fn.expand("%:p"))
      vim.fn.delete(tmp)
    end)

    it("follows links when notes_dir was configured via a symlink path", function()
      local link = vim.fn.tempname()
      vim.fn.system("ln -s " .. vim.fn.shellescape(dir) .. " " .. vim.fn.shellescape(link))
      config.setup({ notes_dir = link })

      local target = dir .. "/20260514--target.md"
      local source = dir .. "/20260514--source.md"
      write_file(target, { "# TARGET", "" })
      write_file(source, { "# SOURCE", "", "see [Target](20260514--target.md)" })
      open_buf(source)
      vim.api.nvim_win_set_cursor(0, { 3, 5 })
      notes.follow_link()

      vim.fn.delete(link)
      assert.equal(target, vim.fn.expand("%:p"))
    end)
  end)

  -- ─── refactor ────────────────────────────────────────────────────────────────

  describe("refactor", function()
    it("renames file", function()
      local orig = dir .. "/20260514--old-name__tag1.md"
      write_file(orig, { "some content" })
      open_buf(orig)
      mock_input("new name")
      mock_tags({ "tag1" })
      notes.refactor()
      local new = dir .. "/20260514--new-name__tag1.md"
      wait_for(new)
      assert.equal(0, vim.fn.filereadable(orig))
      assert.equal("some content", vim.fn.readfile(new)[1])
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

    it("does nothing when name input is cancelled", function()
      local orig = dir .. "/20260514--my-note.md"
      write_file(orig, { "# MY NOTE", "" })
      open_buf(orig)
      mock_input(nil)
      notes.refactor()
      flush()
      assert.equal(1, vim.fn.filereadable(orig))
    end)

    it("preserves current slug when name input is empty", function()
      local orig = dir .. "/20260514--my-note__old.md"
      write_file(orig, { "# MY NOTE", "" })
      open_buf(orig)
      mock_input("")
      mock_tags({ "new" })
      notes.refactor()
      local new = dir .. "/20260514--my-note__new.md"
      wait_for(new)
      assert.equal(0, vim.fn.filereadable(orig))
      assert.equal(1, vim.fn.filereadable(new))
    end)

    it("preserves file content when renaming", function()
      local orig = dir .. "/20260514--no-heading.md"
      write_file(orig, { "some content", "second line" })
      open_buf(orig)
      mock_input("renamed")
      mock_tags({})
      notes.refactor()
      local new = dir .. "/20260514--renamed.md"
      wait_for(new)
      assert.equal(0, vim.fn.filereadable(orig))
      local content = vim.fn.readfile(new)
      assert.equal("some content", content[1])
      assert.equal("second line", content[2])
    end)

    it("warns when the current file is outside the notes directory", function()
      local tmp = vim.fn.tempname() .. ".md"
      write_file(tmp, { "# OUTSIDE", "" })
      open_buf(tmp)
      local warned = false
      local orig_notify = vim.notify
      vim.notify = function(_, level) if level == vim.log.levels.WARN then warned = true end end
      notes.refactor()
      vim.notify = orig_notify
      assert.truthy(warned)
      vim.fn.delete(tmp)
    end)

    it("warns when no file is open", function()
      vim.cmd("enew")
      local warned = false
      local orig_notify = vim.notify
      vim.notify = function(_, level) if level == vim.log.levels.WARN then warned = true end end
      notes.refactor()
      vim.notify = orig_notify
      assert.truthy(warned)
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

    it("warns when an image with the same base name already exists", function()
      package.loaded["img-clip"] = { paste_image = function() end }
      local date = os.date("%Y%m%dT%H%M%S")
      write_file(dir .. "/" .. date .. "--my-photo.png", {})
      mock_input("my photo")
      mock_tags({})
      local warned = false
      local orig_notify = vim.notify
      vim.notify = function(_, level) if level == vim.log.levels.WARN then warned = true end end
      notes.paste_image()
      flush()
      vim.notify = orig_notify
      package.loaded["img-clip"] = nil
      assert.truthy(warned)
    end)

    it("uses $FILE_NAME (not $FILE_PATH) in the img-clip template", function()
      local captured
      package.loaded["img-clip"] = {
        paste_image = function(opts) captured = opts end,
      }
      mock_input("my photo")
      mock_tags({})
      notes.paste_image()
      flush()
      package.loaded["img-clip"] = nil
      assert.truthy(captured, "img-clip.paste_image was not called")
      assert.truthy(captured.template:find("$FILE_NAME", 1, true),
        "template should contain $FILE_NAME")
      assert.falsy(captured.template:find("$FILE_PATH", 1, true),
        "template must not contain $FILE_PATH (would produce absolute path)")
    end)

    it("uses $FILE_NAME template when pasting image from a todo buffer", function()
      local todo_path = dir .. "/20260101T000000-O-my-todo.md"
      write_file(todo_path, {})
      open_buf(todo_path)
      local captured
      package.loaded["img-clip"] = {
        paste_image = function(opts) captured = opts end,
      }
      mock_input("my photo")
      mock_tags({})
      notes.paste_image()
      flush()
      package.loaded["img-clip"] = nil
      assert.truthy(captured, "img-clip.paste_image was not called")
      assert.truthy(captured.template:find("$FILE_NAME", 1, true),
        "template should contain $FILE_NAME")
      assert.falsy(captured.template:find("$FILE_PATH", 1, true),
        "template must not contain $FILE_PATH (would produce absolute path)")
    end)
  end)

  -- ─── paste_image: file URI path ──────────────────────────────────────────────

  describe("paste_image (file URI)", function()
    local function set_clipboard(path)
      vim.fn.setreg("+", "file://" .. path .. "\r\n")
    end

    it("copies a non-image file and inserts a plain markdown link", function()
      local src = vim.fn.tempname() .. ".json"
      write_file(src, { '{"key":"value"}' })
      set_clipboard(src)
      local note = dir .. "/20260101T000000--my-note.md"
      write_file(note, { "before " })
      open_buf(note)
      vim.api.nvim_win_set_cursor(0, { 1, 6 })
      mock_input("my doc")
      mock_tags({})
      notes.paste_image()
      flush()
      local files = vim.fn.glob(dir .. "/*.json", false, true)
      assert.equals(1, #files, "expected one .json file in notes_dir")
      local fname = vim.fn.fnamemodify(files[1], ":t")
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.truthy(lines[1]:find("[my doc](" .. fname .. ")", 1, true),
        "expected plain link in buffer, got: " .. lines[1])
      assert.falsy(lines[1]:find("![my doc]", 1, true), "should not be an image link")
      vim.fn.delete(src)
    end)

    it("copies an image file and inserts an image markdown link", function()
      local src = vim.fn.tempname() .. ".png"
      write_file(src, { "" })
      set_clipboard(src)
      local note = dir .. "/20260101T000000--my-note.md"
      write_file(note, { "before " })
      open_buf(note)
      vim.api.nvim_win_set_cursor(0, { 1, 6 })
      mock_input("my image")
      mock_tags({})
      notes.paste_image()
      flush()
      local files = vim.fn.glob(dir .. "/*.png", false, true)
      assert.equals(1, #files, "expected one .png file in notes_dir")
      local fname = vim.fn.fnamemodify(files[1], ":t")
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.truthy(lines[1]:find("![my image](" .. fname .. ")", 1, true),
        "expected image link in buffer, got: " .. lines[1])
      vim.fn.delete(src)
    end)

    it("warns when destination file already exists", function()
      local src = vim.fn.tempname() .. ".pdf"
      write_file(src, { "" })
      set_clipboard(src)
      mock_input("my doc")
      mock_tags({})
      -- pre-create a file that will collide (same second)
      local date = os.date("%Y%m%dT%H%M%S")
      write_file(dir .. "/" .. date .. "--my-doc.pdf", { "" })
      local warned = false
      local orig_notify = vim.notify
      vim.notify = function(_, level) if level == vim.log.levels.WARN then warned = true end end
      notes.paste_image()
      flush()
      vim.notify = orig_notify
      vim.fn.delete(src)
      assert.truthy(warned)
    end)

    it("warns and aborts when multiple files are in the clipboard", function()
      local src1 = vim.fn.tempname() .. ".pdf"
      local src2 = vim.fn.tempname() .. ".pdf"
      write_file(src1, { "" })
      write_file(src2, { "" })
      vim.fn.setreg("+", "file://" .. src1 .. "\r\nfile://" .. src2 .. "\r\n")
      local warned = false
      local input_shown = false
      local orig_notify = vim.notify
      vim.notify = function(_, level) if level == vim.log.levels.WARN then warned = true end end
      vim.ui.input = function(_, _) input_shown = true end
      notes.paste_image()
      vim.notify = orig_notify
      local files = vim.fn.glob(dir .. "/*.pdf", false, true)
      assert.equals(0, #files, "expected no files copied")
      assert.truthy(warned, "expected a warning notification")
      assert.falsy(input_shown, "title prompt must not appear after warning")
      vim.fn.delete(src1)
      vim.fn.delete(src2)
    end)

    it("errors when clipboard file URI is not readable", function()
      vim.fn.setreg("+", "file:///nonexistent/path/to/file.pdf\r\n")
      local errored = false
      local orig_notify = vim.notify
      vim.notify = function(_, level) if level == vim.log.levels.ERROR then errored = true end end
      notes.paste_image()
      vim.notify = orig_notify
      assert.truthy(errored)
    end)

    it("falls through to img-clip when clipboard has no file URI", function()
      vim.fn.setreg("+", "not a file uri")
      local img_clip_called = false
      package.loaded["img-clip"] = { paste_image = function() img_clip_called = true end }
      mock_input("my photo")
      mock_tags({})
      notes.paste_image()
      flush()
      package.loaded["img-clip"] = nil
      assert.truthy(img_clip_called)
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

    it("opens a picker when backlinks exist", function()
      local target = dir .. "/20260514--target.md"
      local linker = dir .. "/20260514--linker.md"
      write_file(target, { "# TARGET", "" })
      write_file(linker, { "# LINKER", "", "[target](20260514--target.md)" })
      open_buf(target)

      local mods = { "telescope.pickers", "telescope.finders", "telescope.config" }
      local saved = {}
      for _, m in ipairs(mods) do saved[m] = package.loaded[m] end

      local opened = false
      package.loaded["telescope.pickers"] = {
        new = function(_, _) return { find = function() opened = true end } end,
      }
      package.loaded["telescope.finders"] = { new_table = function() return {} end }
      package.loaded["telescope.config"] = {
        values = { generic_sorter = function() return {} end, file_previewer = function() return {} end },
      }

      tel.backlinks()

      for _, m in ipairs(mods) do package.loaded[m] = saved[m] end
      assert.truthy(opened, "picker should open when backlinks exist")
    end)
  end)

  -- ─── search_tags ─────────────────────────────────────────────────────────────

  local function save_telescope_mods()
    local mods = { "telescope.pickers", "telescope.finders", "telescope.config",
                   "telescope.actions", "telescope.actions.state" }
    local saved = {}
    for _, m in ipairs(mods) do saved[m] = package.loaded[m] end
    return mods, saved
  end

  local function restore_telescope_mods(mods, saved)
    for _, m in ipairs(mods) do package.loaded[m] = saved[m] end
  end

  describe("search_tags", function()
    it("notifies when no tags exist across notes", function()
      local notified = false
      local orig_notify = vim.notify
      vim.notify = function(msg, _) if msg:find("no tags") then notified = true end end
      tel.search_tags()
      vim.notify = orig_notify
      assert.truthy(notified)
    end)

    it("opens a picker with all tags when tags exist", function()
      write_file(dir .. "/20260514--n1__foo_bar.md", { "# N1" })
      local mods, saved = save_telescope_mods()
      local finder_results
      local enter_fn
      package.loaded["telescope.finders"] = {
        new_table = function(o) finder_results = o.results; return {} end,
      }
      package.loaded["telescope.config"] = { values = { generic_sorter = function() return {} end } }
      package.loaded["telescope.actions"] = {
        select_default = { replace = function(_, fn) enter_fn = fn end },
        close          = function() end,
      }
      package.loaded["telescope.actions.state"] = {
        get_current_picker = function()
          return { get_multi_selection = function() return {} end }
        end,
        get_selected_entry = function() return nil end,
      }
      package.loaded["telescope.pickers"] = {
        new = function(_, opts)
          return { find = function() opts.attach_mappings(1, function() end) end }
        end,
      }
      tel.search_tags()
      restore_telescope_mods(mods, saved)
      assert.truthy(enter_fn, "select_default handler should be registered")
      assert.same({ "bar", "foo" }, finder_results)
    end)

    it("filters notes to those matching all selected tags (AND logic)", function()
      write_file(dir .. "/20260514--n1__foo.md",     { "# N1" })
      write_file(dir .. "/20260514--n2__bar.md",     { "# N2" })
      write_file(dir .. "/20260514--n3__bar_foo.md", { "# N3" })
      local mods, saved = save_telescope_mods()
      local enter_fn
      local new_table_count = 0
      local result_files
      package.loaded["telescope.finders"] = {
        new_table = function(o)
          new_table_count = new_table_count + 1
          if new_table_count == 2 then result_files = o.results end
          return {}
        end,
      }
      package.loaded["telescope.config"] = {
        values = { generic_sorter = function() return {} end, file_previewer = function() return {} end },
      }
      package.loaded["telescope.actions"] = {
        select_default = { replace = function(_, fn) enter_fn = fn end },
        close          = function() end,
      }
      package.loaded["telescope.actions.state"] = {
        get_current_picker = function()
          return {
            get_multi_selection = function()
              return { { value = "bar" }, { value = "foo" } }
            end,
          }
        end,
      }
      package.loaded["telescope.pickers"] = {
        new = function(_, opts)
          return { find = function()
            if opts.attach_mappings then opts.attach_mappings(1, function() end) end
          end }
        end,
      }
      tel.search_tags()
      assert.truthy(enter_fn)
      enter_fn()
      flush()
      restore_telescope_mods(mods, saved)
      assert.truthy(result_files, "results picker should have opened")
      assert.equal(1, #result_files, "only the note with both foo and bar should match")
      assert.truthy(result_files[1]:find("n3"), "the matching file should be n3")
    end)

    it("notifies when no notes match the selected tag", function()
      write_file(dir .. "/20260514--n1__foo.md", { "# N1" })
      local mods, saved = save_telescope_mods()
      local enter_fn
      package.loaded["telescope.finders"] = { new_table = function() return {} end }
      package.loaded["telescope.config"] = { values = { generic_sorter = function() return {} end } }
      package.loaded["telescope.actions"] = {
        select_default = { replace = function(_, fn) enter_fn = fn end },
        close          = function() end,
      }
      package.loaded["telescope.actions.state"] = {
        get_current_picker = function()
          return { get_multi_selection = function() return {} end }
        end,
        get_selected_entry = function() return { value = "baz" } end,
      }
      package.loaded["telescope.pickers"] = {
        new = function(_, opts)
          return { find = function()
            if opts.attach_mappings then opts.attach_mappings(1, function() end) end
          end }
        end,
      }
      local notified = false
      local orig_notify = vim.notify
      vim.notify = function(msg, _) if msg:find("no notes") then notified = true end end
      tel.search_tags()
      assert.truthy(enter_fn)
      enter_fn()
      flush()
      vim.notify = orig_notify
      restore_telescope_mods(mods, saved)
      assert.truthy(notified, "should notify when no notes carry the selected tag")
    end)
  end)

  -- ─── search_notes / search_content / list_open_todos / list_done_todos ───────

  describe("search_notes", function()
    local saved_builtin, saved_sorters
    before_each(function()
      saved_builtin = package.loaded["telescope.builtin"]
      saved_sorters = package.loaded["telescope.sorters"]
      package.loaded["telescope.builtin"] = { find_files = function() end, live_grep = function() end }
      package.loaded["telescope.sorters"] = { new = function() return {} end }
    end)
    after_each(function()
      package.loaded["telescope.builtin"] = saved_builtin
      package.loaded["telescope.sorters"] = saved_sorters
    end)

    it("opens a file picker in the notes directory excluding templates", function()
      local called_with
      package.loaded["telescope.builtin"].find_files = function(opts) called_with = opts end
      tel.search_notes()
      assert.truthy(called_with, "find_files should be called")
      assert.equal("Notes", called_with.prompt_title)
      assert.equal(dir, called_with.cwd)
      local cmd = table.concat(called_with.find_command, " ")
      assert.truthy(cmd:find("templates"), "find_command should exclude .templates")
    end)
  end)

  describe("search_content", function()
    local saved_builtin, saved_sorters
    before_each(function()
      saved_builtin = package.loaded["telescope.builtin"]
      saved_sorters = package.loaded["telescope.sorters"]
      package.loaded["telescope.builtin"] = { find_files = function() end, live_grep = function() end }
      package.loaded["telescope.sorters"] = { new = function() return {} end }
    end)
    after_each(function()
      package.loaded["telescope.builtin"] = saved_builtin
      package.loaded["telescope.sorters"] = saved_sorters
    end)

    it("opens live grep in the notes directory excluding templates", function()
      local called_with
      package.loaded["telescope.builtin"].live_grep = function(opts) called_with = opts end
      tel.search_content()
      assert.truthy(called_with, "live_grep should be called")
      assert.equal("Notes Content", called_with.prompt_title)
      assert.equal(dir, called_with.cwd)
    end)
  end)

  describe("list_open_todos", function()
    local saved_builtin
    before_each(function()
      saved_builtin = package.loaded["telescope.builtin"]
      package.loaded["telescope.builtin"] = { find_files = function() end }
    end)
    after_each(function()
      package.loaded["telescope.builtin"] = saved_builtin
    end)

    it("opens a picker filtered to open todos", function()
      local called_with
      package.loaded["telescope.builtin"].find_files = function(opts) called_with = opts end
      tel.list_open_todos()
      assert.truthy(called_with, "find_files should be called")
      assert.equal("Open Todos", called_with.prompt_title)
      local cmd = table.concat(called_with.find_command, " ")
      assert.truthy(cmd:find("-O-"), "find_command should filter open todos")
    end)
  end)

  describe("list_done_todos", function()
    local saved_builtin
    before_each(function()
      saved_builtin = package.loaded["telescope.builtin"]
      package.loaded["telescope.builtin"] = { find_files = function() end }
    end)
    after_each(function()
      package.loaded["telescope.builtin"] = saved_builtin
    end)

    it("opens a picker filtered to done todos", function()
      local called_with
      package.loaded["telescope.builtin"].find_files = function(opts) called_with = opts end
      tel.list_done_todos()
      assert.truthy(called_with, "find_files should be called")
      assert.equal("Done Todos", called_with.prompt_title)
      local cmd = table.concat(called_with.find_command, " ")
      assert.truthy(cmd:find("-X-"), "find_command should filter done todos")
    end)
  end)

  -- ─── pick_template ───────────────────────────────────────────────────────────

  describe("pick_template", function()
    local saved = {}
    local telescope_modules = {
      "telescope.pickers", "telescope.finders",
      "telescope.config", "telescope.actions", "telescope.actions.state",
    }

    before_each(function()
      for _, mod in ipairs(telescope_modules) do saved[mod] = package.loaded[mod] end
    end)

    after_each(function()
      for _, mod in ipairs(telescope_modules) do package.loaded[mod] = saved[mod] end
    end)

    it("notifies when no templates exist", function()
      local notified = false
      local orig_notify = vim.notify
      vim.notify = function(msg, _) if msg:find("no templates") then notified = true end end
      tel.pick_template(function() end)
      vim.notify = orig_notify
      assert.truthy(notified)
    end)

    it("calls callback with the selected template path", function()
      local tmpl = make_template("meeting", { "## Attendees", "", "## Action Items" })
      local received
      package.loaded["telescope.actions"] = {
        select_default = { replace = function(_, fn)
          vim.schedule(fn)
        end },
        close = function() end,
      }
      package.loaded["telescope.actions.state"] = {
        get_selected_entry = function()
          return { value = { path = tmpl, name = "meeting" } }
        end,
      }
      package.loaded["telescope.pickers"] = {
        new = function(_, opts)
          return { find = function() opts.attach_mappings(1, function() end) end }
        end,
      }
      package.loaded["telescope.finders"] = { new_table = function() return {} end }
      package.loaded["telescope.config"]  = {
        values = { generic_sorter = function() return {} end, file_previewer = function() return {} end },
      }

      tel.pick_template(function(path) received = path end)
      vim.wait(200, function() return received ~= nil end, 10)
      assert.equal(tmpl, received)
    end)
  end)

  -- ─── new_note_from_template ───────────────────────────────────────────────────

  describe("new_note_from_template", function()
    it("notifies when no templates exist", function()
      local notified = false
      local orig_notify = vim.notify
      vim.notify = function(msg, _) if msg:find("no templates") then notified = true end end
      tel.pick_template(function() end)
      vim.notify = orig_notify
      assert.truthy(notified)
    end)

    it("creates file with template content", function()
      local tmpl = make_template("meeting", { "## Attendees", "", "## Action Items" })
      mock_template(tmpl)
      mock_input("team sync")
      mock_tags({})
      notes.new_note_from_template()
      local expected = dir .. "/" .. os.date("%Y%m%dT%H%M%S") .. "--team-sync.md"
      wait_for(expected)
      local lines = vim.fn.readfile(expected)
      assert.equal("## Attendees", lines[1])
      assert.equal("## Action Items", lines[3])
    end)

    it("uses template content as-is including any H1 heading", function()
      local tmpl = make_template("daily", { "# Daily Note", "", "## Log" })
      mock_template(tmpl)
      mock_input("monday")
      mock_tags({})
      notes.new_note_from_template()
      local expected = dir .. "/" .. os.date("%Y%m%dT%H%M%S") .. "--monday.md"
      wait_for(expected)
      local lines = vim.fn.readfile(expected)
      assert.equal("# Daily Note", lines[1])
      assert.equal("## Log", lines[3])
    end)

    it("applies tags to the filename", function()
      local tmpl = make_template("note", { "some content" })
      mock_template(tmpl)
      mock_input("my note")
      mock_tags({ "work", "alpha" })
      notes.new_note_from_template()
      local expected = dir .. "/" .. os.date("%Y%m%dT%H%M%S") .. "--my-note__alpha_work.md"
      wait_for(expected)
    end)

    it("does nothing when name input is cancelled", function()
      local tmpl = make_template("note", { "content" })
      mock_template(tmpl)
      mock_input(nil)
      notes.new_note_from_template()
      flush()
      assert.same({}, vim.fn.glob(dir .. "/*.md", false, true))
    end)

    it("opens existing file without overwriting when name collides", function()
      local existing = dir .. "/" .. os.date("%Y%m%dT%H%M%S") .. "--sync.md"
      write_file(existing, { "# SYNC", "", "original content" })
      local tmpl = make_template("meeting", { "## Attendees" })
      mock_template(tmpl)
      mock_input("sync")
      mock_tags({})
      notes.new_note_from_template()
      wait_for(existing)
      assert.equal("original content", vim.fn.readfile(existing)[3])
    end)
  end)

  -- ─── new_todo_from_template ───────────────────────────────────────────────────

  describe("new_todo_from_template", function()
    local saved = {}
    local telescope_modules = {
      "telescope.pickers", "telescope.finders",
      "telescope.config", "telescope.actions", "telescope.actions.state",
    }

    before_each(function()
      for _, mod in ipairs(telescope_modules) do saved[mod] = package.loaded[mod] end
    end)

    after_each(function()
      for _, mod in ipairs(telescope_modules) do package.loaded[mod] = saved[mod] end
    end)

    it("notifies when no templates exist", function()
      local notified = false
      local orig_notify = vim.notify
      vim.notify = function(msg, _) if msg:find("no templates") then notified = true end end
      tel.pick_template(function() end)
      vim.notify = orig_notify
      assert.truthy(notified)
    end)

    it("creates -O- file with template content", function()
      local tmpl = make_template("task", { "## Steps", "", "## Notes" })
      mock_template(tmpl)
      mock_input("my task")
      mock_tags({})
      notes.new_todo_from_template()
      local expected = dir .. "/" .. os.date("%Y%m%dT%H%M%S") .. "-O-my-task.md"
      wait_for(expected)
      local lines = vim.fn.readfile(expected)
      assert.equal("## Steps", lines[1])
      assert.equal("## Notes", lines[3])
    end)

    it("uses -O- marker in the filename", function()
      local tmpl = make_template("task", { "content" })
      mock_template(tmpl)
      mock_input("check marker")
      mock_tags({})
      notes.new_todo_from_template()
      local expected = dir .. "/" .. os.date("%Y%m%dT%H%M%S") .. "-O-check-marker.md"
      wait_for(expected)
      assert.equal(1, vim.fn.filereadable(expected))
    end)

    it("uses template content as-is including any H1 heading", function()
      local tmpl = make_template("task", { "# Task Template", "", "## Steps" })
      mock_template(tmpl)
      mock_input("my task")
      mock_tags({})
      notes.new_todo_from_template()
      local expected = dir .. "/" .. os.date("%Y%m%dT%H%M%S") .. "-O-my-task.md"
      wait_for(expected)
      local lines = vim.fn.readfile(expected)
      assert.equal("# Task Template", lines[1])
      assert.equal("## Steps", lines[3])
    end)

    it("applies tags to the filename", function()
      local tmpl = make_template("task", { "content" })
      mock_template(tmpl)
      mock_input("my task")
      mock_tags({ "work", "alpha" })
      notes.new_todo_from_template()
      local expected = dir .. "/" .. os.date("%Y%m%dT%H%M%S") .. "-O-my-task__alpha_work.md"
      wait_for(expected)
    end)

    it("sorts tags alphabetically in the filename", function()
      local tmpl = make_template("task", { "content" })
      mock_template(tmpl)
      mock_input("sorted")
      mock_tags({ "zebra", "alpha", "mango" })
      notes.new_todo_from_template()
      local expected = dir .. "/" .. os.date("%Y%m%dT%H%M%S") .. "-O-sorted__alpha_mango_zebra.md"
      wait_for(expected)
    end)

    it("does nothing when name input is cancelled", function()
      local tmpl = make_template("task", { "content" })
      mock_template(tmpl)
      mock_input(nil)
      notes.new_todo_from_template()
      flush()
      assert.same({}, vim.fn.glob(dir .. "/*.md", false, true))
    end)

    it("does nothing when name input is empty string", function()
      local tmpl = make_template("task", { "content" })
      mock_template(tmpl)
      mock_input("")
      notes.new_todo_from_template()
      flush()
      assert.same({}, vim.fn.glob(dir .. "/*.md", false, true))
    end)

    it("opens existing todo without overwriting when name collides", function()
      local existing = dir .. "/" .. os.date("%Y%m%dT%H%M%S") .. "-O-collision.md"
      write_file(existing, { "original content" })
      local tmpl = make_template("task", { "template content" })
      mock_template(tmpl)
      mock_input("collision")
      mock_tags({})
      notes.new_todo_from_template()
      wait_for(existing)
      assert.equal("original content", vim.fn.readfile(existing)[1])
    end)

    it("notifies when opening a colliding existing todo", function()
      local existing = dir .. "/" .. os.date("%Y%m%dT%H%M%S") .. "-O-collision.md"
      write_file(existing, { "original content" })
      local tmpl = make_template("task", { "template content" })
      mock_template(tmpl)
      mock_input("collision")
      mock_tags({})
      local notified = false
      local orig_notify = vim.notify
      vim.notify = function(msg, _) if msg:find("already exists") then notified = true end end
      notes.new_todo_from_template()
      flush()
      vim.notify = orig_notify
      assert.truthy(notified)
    end)

    it("places cursor at the first $ and removes it from the buffer", function()
      local tmpl = make_template("task", { "## Topic: $", "", "## Steps" })
      mock_template(tmpl)
      mock_input("my task")
      mock_tags({})
      notes.new_todo_from_template()
      local expected = dir .. "/" .. os.date("%Y%m%dT%H%M%S") .. "-O-my-task.md"
      wait_for(expected)
      flush()
      local cursor = vim.api.nvim_win_get_cursor(0)
      assert.equal(1, cursor[1])
      assert.equal(10, cursor[2])
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.equal("## Topic: ", lines[1])
    end)

    it("Tab advances cursor to the next stop", function()
      local tmpl = make_template("task", { "Name: $", "Due: $" })
      mock_template(tmpl)
      mock_input("advance")
      mock_tags({})
      notes.new_todo_from_template()
      local expected = dir .. "/" .. os.date("%Y%m%dT%H%M%S") .. "-O-advance.md"
      wait_for(expected)
      flush()
      local bufnr = vim.api.nvim_get_current_buf()
      local tab_fn
      for _, km in ipairs(vim.api.nvim_buf_get_keymap(bufnr, "i")) do
        if km.lhs == "<Tab>" then tab_fn = km.callback; break end
      end
      assert.truthy(tab_fn, "Tab keymap not set")
      tab_fn()
      local cursor = vim.api.nvim_win_get_cursor(0)
      assert.equal(2, cursor[1])
      assert.equal(5, cursor[2])
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.equal("Name: ", lines[1])
      assert.equal("Due: ", lines[2])
    end)

    it("falls back to line 1 col 0 and sets no Tab keymap when template has no stops", function()
      local tmpl = make_template("plain-task", { "Just plain content" })
      mock_template(tmpl)
      mock_input("no stops")
      mock_tags({})
      notes.new_todo_from_template()
      local expected = dir .. "/" .. os.date("%Y%m%dT%H%M%S") .. "-O-no-stops.md"
      wait_for(expected)
      flush()
      local cursor = vim.api.nvim_win_get_cursor(0)
      assert.equal(1, cursor[1])
      assert.equal(0, cursor[2])
      local bufnr = vim.api.nvim_get_current_buf()
      local has_tab = false
      for _, km in ipairs(vim.api.nvim_buf_get_keymap(bufnr, "i")) do
        if km.lhs == "<Tab>" then has_tab = true; break end
      end
      assert.falsy(has_tab)
    end)
  end)

  -- ─── template tab stops ──────────────────────────────────────────────────────

  describe("template tab stops", function()
    it("places cursor at the first $ and removes it from the buffer", function()
      local tmpl = make_template("form", { "## Topic: $", "", "## Notes" })
      mock_template(tmpl)
      mock_input("my meeting")
      mock_tags({})
      notes.new_note_from_template()
      local expected = dir .. "/" .. os.date("%Y%m%dT%H%M%S") .. "--my-meeting.md"
      wait_for(expected)
      flush()
      local cursor = vim.api.nvim_win_get_cursor(0)
      assert.equal(1, cursor[1])   -- line 1: "## Topic: $"
      assert.equal(10, cursor[2])  -- col 10 (0-based), right where $ was
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.equal("## Topic: ", lines[1])
    end)

    it("sets a buffer-local insert-mode Tab keymap when stops exist", function()
      local tmpl = make_template("two-stops", { "Name: $", "Date: $" })
      mock_template(tmpl)
      mock_input("my form")
      mock_tags({})
      notes.new_note_from_template()
      local expected = dir .. "/" .. os.date("%Y%m%dT%H%M%S") .. "--my-form.md"
      wait_for(expected)
      flush()
      local bufnr = vim.api.nvim_get_current_buf()
      local keymaps = vim.api.nvim_buf_get_keymap(bufnr, "i")
      local has_tab = false
      for _, km in ipairs(keymaps) do
        if km.lhs == "<Tab>" then has_tab = true; break end
      end
      assert.truthy(has_tab)
    end)

    it("Tab advances cursor to the next stop", function()
      local tmpl = make_template("advance", { "Name: $", "Date: $" })
      mock_template(tmpl)
      mock_input("advance")
      mock_tags({})
      notes.new_note_from_template()
      local expected = dir .. "/" .. os.date("%Y%m%dT%H%M%S") .. "--advance.md"
      wait_for(expected)
      flush()
      local bufnr = vim.api.nvim_get_current_buf()
      local tab_fn
      for _, km in ipairs(vim.api.nvim_buf_get_keymap(bufnr, "i")) do
        if km.lhs == "<Tab>" then tab_fn = km.callback; break end
      end
      assert.truthy(tab_fn, "Tab keymap not set")
      tab_fn()
      local cursor = vim.api.nvim_win_get_cursor(0)
      assert.equal(2, cursor[1])  -- line 2: "Date: $"
      assert.equal(6, cursor[2])  -- col 6, right where $ was
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.equal("Name: ", lines[1])
      assert.equal("Date: ", lines[2])
    end)

    it("removes the Tab keymap after the last stop is consumed", function()
      local tmpl = make_template("single-stop", { "Field: $" })
      mock_template(tmpl)
      mock_input("single stop")
      mock_tags({})
      notes.new_note_from_template()
      local expected = dir .. "/" .. os.date("%Y%m%dT%H%M%S") .. "--single-stop.md"
      wait_for(expected)
      flush()
      local bufnr = vim.api.nvim_get_current_buf()
      local tab_fn
      for _, km in ipairs(vim.api.nvim_buf_get_keymap(bufnr, "i")) do
        if km.lhs == "<Tab>" then tab_fn = km.callback; break end
      end
      assert.truthy(tab_fn, "Tab keymap should exist before last stop is consumed")
      tab_fn()
      local keymaps = vim.api.nvim_buf_get_keymap(bufnr, "i")
      local has_tab = false
      for _, km in ipairs(keymaps) do
        if km.lhs == "<Tab>" then has_tab = true; break end
      end
      assert.falsy(has_tab)
    end)

    it("falls back to line 1 col 0 and sets no Tab keymap when template has no stops", function()
      local tmpl = make_template("plain", { "Just plain content" })
      mock_template(tmpl)
      mock_input("no stops")
      mock_tags({})
      notes.new_note_from_template()
      local expected = dir .. "/" .. os.date("%Y%m%dT%H%M%S") .. "--no-stops.md"
      wait_for(expected)
      flush()
      local cursor = vim.api.nvim_win_get_cursor(0)
      assert.equal(1, cursor[1])
      assert.equal(0, cursor[2])
      local bufnr = vim.api.nvim_get_current_buf()
      local has_tab = false
      for _, km in ipairs(vim.api.nvim_buf_get_keymap(bufnr, "i")) do
        if km.lhs == "<Tab>" then has_tab = true; break end
      end
      assert.falsy(has_tab)
    end)
  end)

  -- ─── search_templates ─────────────────────────────────────────────────────────

  describe("search_templates", function()
    it("notifies when no templates exist", function()
      local notified = false
      local orig_notify = vim.notify
      vim.notify = function(msg, _) if msg:find("no templates") then notified = true end end
      tel.search_templates()
      vim.notify = orig_notify
      assert.truthy(notified)
    end)
  end)

  -- ─── new_template ────────────────────────────────────────────────────────────

  describe("new_template", function()
    it("opens a buffer for the slugified template path", function()
      mock_input("meeting notes")
      notes.new_template()
      flush()
      assert.equal(dir .. "/.templates/meeting-notes.md", vim.fn.expand("%:p"))
    end)

    it("creates the .templates directory when it does not exist", function()
      assert.equal(0, vim.fn.isdirectory(dir .. "/.templates"))
      mock_input("my template")
      notes.new_template()
      assert.equal(1, vim.fn.isdirectory(dir .. "/.templates"))
    end)

    it("slugifies special characters in the template name", function()
      mock_input("Hello, World!")
      notes.new_template()
      flush()
      assert.equal(dir .. "/.templates/hello-world.md", vim.fn.expand("%:p"))
    end)

    it("does nothing when name input is cancelled", function()
      mock_input(nil)
      notes.new_template()
      flush()
      assert.same({}, vim.fn.glob(dir .. "/.templates/*.md", false, true))
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

    it("falls back to filename stem when note has no H1 heading", function()
      write_file(dir .. "/20260514--no-heading.md", { "just some content", "" })
      idx.open()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.truthy(vim.tbl_contains(lines, "- [20260514--no-heading](20260514--no-heading.md)"))
    end)
  end)

  -- ─── stats ───────────────────────────────────────────────────────────────────

  describe("stats", function()
    local function stat_value(lines, label)
      for _, l in ipairs(lines) do
        local n = l:match(label .. "%s+(%d+)")
        if n then return tonumber(n) end
      end
    end

    it("opens a buffer with the stats header", function()
      st.open()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.truthy(vim.tbl_contains(lines, "# Notes Statistics"))
      assert.truthy(vim.tbl_contains(lines, "## Overview"))
      assert.truthy(vim.tbl_contains(lines, "## Activity"))
    end)

    it("counts notes, open todos and done todos correctly", function()
      write_file(dir .. "/20260514--note-a.md",  { "# A", "" })
      write_file(dir .. "/20260514--note-b.md",  { "# B", "" })
      write_file(dir .. "/20260514-O-todo.md",   { "# TODO", "" })
      write_file(dir .. "/20260514-X-done.md",   { "# DONE", "" })
      st.open()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.equal(4, stat_value(lines, "Total"))
      assert.equal(2, stat_value(lines, "Notes"))
      assert.equal(1, stat_value(lines, "Open todos"))
      assert.equal(1, stat_value(lines, "Done todos"))
    end)

    it("counts unique tags", function()
      write_file(dir .. "/20260514--a__foo_bar.md", { "# A", "" })
      write_file(dir .. "/20260514--b__foo.md",     { "# B", "" })
      st.open()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.equal(2, stat_value(lines, "Tags"))
    end)

    it("shows top tags sorted by frequency", function()
      write_file(dir .. "/20260514--a__foo.md", { "# A", "" })
      write_file(dir .. "/20260514--b__foo.md", { "# B", "" })
      write_file(dir .. "/20260514--c__bar.md", { "# C", "" })
      st.open()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.truthy(vim.tbl_contains(lines, "## Top Tags"))
      local foo_count, bar_count
      for _, l in ipairs(lines) do
        local n = l:match("foo%s+(%d+)")
        if n then foo_count = tonumber(n) end
        n = l:match("bar%s+(%d+)")
        if n then bar_count = tonumber(n) end
      end
      assert.equal(2, foo_count)
      assert.equal(1, bar_count)
    end)

    it("omits Top Tags section when no notes have tags", function()
      write_file(dir .. "/20260514--plain.md", { "# PLAIN", "" })
      st.open()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.falsy(vim.tbl_contains(lines, "## Top Tags"))
    end)

    it("excludes templates from counts", function()
      write_file(dir .. "/20260514--note.md", { "# NOTE", "" })
      make_template("meeting", { "# Meeting", "" })
      st.open()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.equal(1, stat_value(lines, "Total"))
    end)

    it("counts files created this month in the activity section", function()
      local today = os.date("%Y%m%dT%H%M%S")
      write_file(dir .. "/" .. today .. "--fresh.md", { "# FRESH", "" })
      write_file(dir .. "/20200101--old.md",          { "# OLD", "" })
      st.open()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.equal(1, stat_value(lines, "This month"))
    end)

    it("counts files created last month in the activity section", function()
      local t = os.date("*t")
      local lm_year, lm_num = t.year, t.month - 1
      if lm_num == 0 then lm_num = 12; lm_year = lm_year - 1 end
      local last_month_ts = string.format("%04d%02d01T120000", lm_year, lm_num)
      write_file(dir .. "/" .. last_month_ts .. "--last-month.md", { "# LAST", "" })
      write_file(dir .. "/20200101--old.md",                       { "# OLD", "" })
      st.open()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.equal(1, stat_value(lines, "Last month"))
    end)

    it("has r and q keymaps bound on the buffer", function()
      st.open()
      local bufnr = vim.api.nvim_get_current_buf()
      local keymaps = vim.api.nvim_buf_get_keymap(bufnr, "n")
      local lhs_set = {}
      for _, km in ipairs(keymaps) do lhs_set[km.lhs] = true end
      assert.truthy(lhs_set["r"])
      assert.truthy(lhs_set["q"])
    end)

    it("reuses the same buffer on repeated open calls", function()
      st.open()
      local bufnr1 = vim.api.nvim_get_current_buf()
      vim.cmd("enew")
      st.open()
      assert.equal(bufnr1, vim.api.nvim_get_current_buf())
    end)

    it("counts notes with at least one outgoing link", function()
      write_file(dir .. "/20260514--linked.md",   { "# LINKED", "", "see [Other](20260514--other.md)" })
      write_file(dir .. "/20260514--other.md",    { "# OTHER", "" })
      write_file(dir .. "/20260514--unlinked.md", { "# UNLINKED", "" })
      st.open()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert.equal(1, stat_value(lines, "Linked"))
    end)

    it("shows linked percentage in the overview", function()
      write_file(dir .. "/20260514--a.md", { "# A", "", "[B](20260514--b.md)" })
      write_file(dir .. "/20260514--b.md", { "# B", "", "[A](20260514--a.md)" })
      write_file(dir .. "/20260514--c.md", { "# C", "" })
      write_file(dir .. "/20260514--d.md", { "# D", "" })
      st.open()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local linked_line
      for _, l in ipairs(lines) do
        if l:find("Linked", 1, true) then linked_line = l; break end
      end
      assert.truthy(linked_line)
      assert.truthy(linked_line:find("2", 1, true))
      assert.truthy(linked_line:find("50%%"))
    end)

    it("shows 0%% when no notes have links", function()
      write_file(dir .. "/20260514--plain.md", { "# PLAIN", "" })
      st.open()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      local linked_line
      for _, l in ipairs(lines) do
        if l:find("Linked", 1, true) then linked_line = l; break end
      end
      assert.truthy(linked_line)
      assert.truthy(linked_line:find("0%%"))
    end)
  end)

  -- ─── insert_link ─────────────────────────────────────────────────────────────

  describe("insert_link", function()
    local saved = {}
    local telescope_modules = {
      "telescope.pickers", "telescope.finders",
      "telescope.config", "telescope.actions", "telescope.actions.state",
    }

    before_each(function()
      for _, mod in ipairs(telescope_modules) do
        saved[mod] = package.loaded[mod]
      end
    end)

    after_each(function()
      for _, mod in ipairs(telescope_modules) do
        package.loaded[mod] = saved[mod]
      end
    end)

    it("inserts a markdown link to the selected note at the cursor position", function()
      local target = dir .. "/20260514--target.md"
      local source = dir .. "/20260514--source.md"
      write_file(target, { "# TARGET NOTE", "" })
      write_file(source, { "# SOURCE", "", "see " })
      open_buf(source)
      vim.api.nvim_win_set_cursor(0, { 3, 3 })

      local enter_fn
      package.loaded["telescope.actions"] = {
        select_default = { replace = function(_, fn) enter_fn = fn end },
        close          = function() end,
      }
      package.loaded["telescope.actions.state"] = {
        get_selected_entry = function()
          return { value = { path = target, title = "TARGET NOTE" } }
        end,
      }
      package.loaded["telescope.pickers"] = {
        new = function(_, opts)
          return { find = function() opts.attach_mappings(1, function() end) end }
        end,
      }
      package.loaded["telescope.finders"] = { new_table = function() return {} end }
      package.loaded["telescope.config"]  = {
        values = {
          generic_sorter = function() return {} end,
          file_previewer = function() return {} end,
        },
      }

      tel.insert_link()
      assert.truthy(enter_fn, "select_default handler was not registered")
      enter_fn()
      flush()

      local line = vim.api.nvim_buf_get_lines(0, 2, 3, false)[1]
      assert.truthy(line:find("[TARGET NOTE]", 1, true))
      assert.truthy(line:find("20260514--target.md", 1, true))
    end)

    it("warns when no file is open", function()
      vim.cmd("enew")
      local warned = false
      local orig_notify = vim.notify
      vim.notify = function(_, level) if level == vim.log.levels.WARN then warned = true end end
      tel.insert_link()
      vim.notify = orig_notify
      assert.truthy(warned)
    end)
  end)

  -- ─── insert_url_link ─────────────────────────────────────────────────────────

  describe("insert_url_link", function()
    local function setup_buf(lines, row, col)
      local path = dir .. "/note.md"
      write_file(path, lines)
      open_buf(path)
      vim.api.nvim_win_set_cursor(0, { row, col })
    end

    it("inserts markdown link with URL from first prompt and title from second", function()
      vim.fn.setreg("+", "https://example.com")
      setup_buf({ "see " }, 1, 3)
      local responses = { "https://example.com", "My Site" }
      local i = 0
      vim.ui.input = function(_, cb) i = i + 1; cb(responses[i]) end
      notes.insert_url_link()
      flush()
      local line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
      assert.equal("see [My Site](https://example.com)", line)
    end)

    it("pre-fills URL prompt with clipboard content", function()
      vim.fn.setreg("+", "https://example.com")
      setup_buf({ "" }, 1, 0)
      local captured_default
      local i = 0
      vim.ui.input = function(opts, cb)
        i = i + 1
        if i == 1 then captured_default = opts.default end
        cb("value")
      end
      notes.insert_url_link()
      flush()
      assert.equal("https://example.com", captured_default)
    end)

    it("title prompt has no default", function()
      vim.fn.setreg("+", "https://example.com")
      setup_buf({ "" }, 1, 0)
      local title_default = "sentinel"
      local i = 0
      vim.ui.input = function(opts, cb)
        i = i + 1
        if i == 2 then title_default = opts.default end
        cb("value")
      end
      notes.insert_url_link()
      flush()
      assert.is_nil(title_default)
    end)

    it("does nothing when URL prompt is cancelled", function()
      vim.fn.setreg("+", "https://example.com")
      setup_buf({ "hello" }, 1, 4)
      vim.ui.input = function(_, cb) cb(nil) end
      notes.insert_url_link()
      flush()
      local line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
      assert.equal("hello", line)
    end)

    it("does nothing when title prompt is cancelled", function()
      vim.fn.setreg("+", "https://example.com")
      setup_buf({ "hello" }, 1, 4)
      local i = 0
      vim.ui.input = function(_, cb)
        i = i + 1
        cb(i == 1 and "https://example.com" or nil)
      end
      notes.insert_url_link()
      flush()
      local line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
      assert.equal("hello", line)
    end)

    it("inserts link with empty title when title input is left empty", function()
      vim.fn.setreg("+", "https://example.com")
      setup_buf({ "" }, 1, 0)
      local responses = { "https://example.com", "" }
      local i = 0
      vim.ui.input = function(_, cb) i = i + 1; cb(responses[i]) end
      notes.insert_url_link()
      flush()
      local line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
      assert.equal("[](https://example.com)", line)
    end)
  end)

  -- ─── rename_tag ──────────────────────────────────────────────────────────────

  describe("rename_tag", function()
    local saved = {}
    local telescope_modules = {
      "telescope.pickers", "telescope.finders",
      "telescope.config", "telescope.actions", "telescope.actions.state",
    }

    before_each(function()
      for _, mod in ipairs(telescope_modules) do
        saved[mod] = package.loaded[mod]
      end
    end)

    after_each(function()
      for _, mod in ipairs(telescope_modules) do
        package.loaded[mod] = saved[mod]
      end
    end)

    local function setup_mock(selected_tag)
      local handles = {}
      package.loaded["telescope.actions"] = {
        select_default = { replace = function(_, fn) handles.enter = fn end },
        close          = function() end,
      }
      package.loaded["telescope.actions.state"] = {
        get_selected_entry = function()
          return selected_tag and { value = selected_tag } or nil
        end,
      }
      package.loaded["telescope.pickers"] = {
        new = function(_, picker_opts)
          return {
            find = function()
              picker_opts.attach_mappings(1, function() end)
            end,
          }
        end,
      }
      package.loaded["telescope.finders"] = { new_table = function() return {} end }
      package.loaded["telescope.config"]  = { values = { generic_sorter = function() return {} end } }
      return handles
    end

    it("notifies when no tags exist", function()
      local notified = false
      local orig_notify = vim.notify
      vim.notify = function(msg, _) if msg:find("no tags") then notified = true end end
      tel.rename_tag()
      vim.notify = orig_notify
      assert.truthy(notified)
    end)

    it("renames all files carrying the old tag", function()
      local a = dir .. "/20260514--note-a__foo.md"
      local b = dir .. "/20260514--note-b__foo.md"
      write_file(a, { "# NOTE A", "" })
      write_file(b, { "# NOTE B", "" })
      local h = setup_mock("foo")
      mock_input("bar")
      tel.rename_tag()
      h.enter()
      flush()
      assert.equal(0, vim.fn.filereadable(a))
      assert.equal(0, vim.fn.filereadable(b))
      assert.equal(1, vim.fn.filereadable(dir .. "/20260514--note-a__bar.md"))
      assert.equal(1, vim.fn.filereadable(dir .. "/20260514--note-b__bar.md"))
    end)

    it("preserves other tags on renamed files", function()
      local orig = dir .. "/20260514--note__bar_foo_zzz.md"
      write_file(orig, { "# NOTE", "" })
      local h = setup_mock("foo")
      mock_input("mid")
      tel.rename_tag()
      h.enter()
      flush()
      assert.equal(0, vim.fn.filereadable(orig))
      assert.equal(1, vim.fn.filereadable(dir .. "/20260514--note__bar_mid_zzz.md"))
    end)

    it("does not rename files that do not carry the old tag", function()
      local with_tag = dir .. "/20260514--note-a__foo.md"
      local without  = dir .. "/20260514--note-b__bar.md"
      write_file(with_tag, { "# A", "" })
      write_file(without,  { "# B", "" })
      local h = setup_mock("foo")
      mock_input("qux")
      tel.rename_tag()
      h.enter()
      flush()
      assert.equal(0, vim.fn.filereadable(with_tag))
      assert.equal(1, vim.fn.filereadable(dir .. "/20260514--note-a__qux.md"))
      assert.equal(1, vim.fn.filereadable(without))
    end)

    it("updates backlinks in referencing notes", function()
      local note   = dir .. "/20260514--note__foo.md"
      local linker = dir .. "/20260514--linker.md"
      write_file(note,   { "# NOTE", "" })
      write_file(linker, { "# LINKER", "", "see [Note](20260514--note__foo.md)" })
      local h = setup_mock("foo")
      mock_input("bar")
      tel.rename_tag()
      h.enter()
      flush()
      local line = vim.fn.readfile(linker)[3]
      assert.truthy(line:find("20260514--note__bar.md", 1, true))
      assert.falsy(line:find("20260514--note__foo.md", 1, true))
    end)

    it("notifies with file and link counts", function()
      local a      = dir .. "/20260514--note-a__foo.md"
      local b      = dir .. "/20260514--note-b__foo.md"
      local linker = dir .. "/20260514--linker.md"
      write_file(a,      { "# A", "" })
      write_file(b,      { "# B", "" })
      write_file(linker, { "# LINKER", "", "[A](20260514--note-a__foo.md)" })
      local msg
      local orig_notify = vim.notify
      vim.notify = function(m, _) msg = m end
      local h = setup_mock("foo")
      mock_input("bar")
      tel.rename_tag()
      h.enter()
      flush()
      vim.notify = orig_notify
      assert.truthy(msg)
      assert.truthy(msg:find("foo", 1, true))
      assert.truthy(msg:find("bar", 1, true))
      assert.truthy(msg:find("2 files", 1, true))
      assert.truthy(msg:find("1 link", 1, true))
    end)

    it("does nothing when input is cancelled", function()
      local orig = dir .. "/20260514--note__foo.md"
      write_file(orig, { "# NOTE", "" })
      local h = setup_mock("foo")
      mock_input(nil)
      tel.rename_tag()
      h.enter()
      flush()
      assert.equal(1, vim.fn.filereadable(orig))
    end)

    it("notifies and does nothing when new name matches old tag", function()
      local orig = dir .. "/20260514--note__foo.md"
      write_file(orig, { "# NOTE", "" })
      local msg
      local orig_notify = vim.notify
      vim.notify = function(m, _) msg = m end
      local h = setup_mock("foo")
      mock_input("foo")
      tel.rename_tag()
      h.enter()
      flush()
      vim.notify = orig_notify
      assert.truthy(msg:find("unchanged", 1, true))
      assert.equal(1, vim.fn.filereadable(orig))
    end)

    it("warns and does nothing when new name is invalid", function()
      local orig = dir .. "/20260514--note__foo.md"
      write_file(orig, { "# NOTE", "" })
      local warned = false
      local orig_notify = vim.notify
      vim.notify = function(_, level) if level == vim.log.levels.WARN then warned = true end end
      local h = setup_mock("foo")
      mock_input("!!!")
      tel.rename_tag()
      h.enter()
      flush()
      vim.notify = orig_notify
      assert.truthy(warned)
      assert.equal(1, vim.fn.filereadable(orig))
    end)

    it("notifies when no files carry the selected tag", function()
      local note = dir .. "/20260514--note__foo.md"
      write_file(note, { "# NOTE", "" })
      local msg
      local orig_notify = vim.notify
      vim.notify = function(m, _) msg = m end
      local h = setup_mock("nonexistent")
      mock_input("bar")
      tel.rename_tag()
      h.enter()
      flush()
      vim.notify = orig_notify
      assert.truthy(msg:find("no files", 1, true))
      assert.equal(1, vim.fn.filereadable(note))
    end)

    it("redirects the current buffer when it was one of the renamed files", function()
      local orig = dir .. "/20260514--note__foo.md"
      write_file(orig, { "# NOTE", "" })
      open_buf(orig)
      local old_buf = vim.api.nvim_get_current_buf()
      local h = setup_mock("foo")
      mock_input("bar")
      tel.rename_tag()
      h.enter()
      flush()
      local new = dir .. "/20260514--note__bar.md"
      assert.equal(1, vim.fn.filereadable(new))
      assert.equal(new, vim.fn.expand("%:p"))
      assert.falsy(vim.api.nvim_buf_is_valid(old_buf))
    end)

    it("works on todo files", function()
      local todo = dir .. "/20260514-O-fix-bug__foo_work.md"
      write_file(todo, { "# FIX BUG", "" })
      local h = setup_mock("foo")
      mock_input("ops")
      tel.rename_tag()
      h.enter()
      flush()
      assert.equal(0, vim.fn.filereadable(todo))
      assert.equal(1, vim.fn.filereadable(dir .. "/20260514-O-fix-bug__ops_work.md"))
    end)
  end)

  -- ─── search_untagged ─────────────────────────────────────────────────────────

  describe("search_untagged", function()
    it("notifies when all notes are tagged", function()
      write_file(dir .. "/20260514--note-a__work.md", { "# A", "" })
      write_file(dir .. "/20260514--note-b__pkm_writing.md", { "# B", "" })
      local notified = false
      local orig_notify = vim.notify
      vim.notify = function(msg, _) if msg:find("no untagged") then notified = true end end
      tel.search_untagged()
      vim.notify = orig_notify
      assert.truthy(notified)
    end)

    it("notifies when the notes directory is empty", function()
      local notified = false
      local orig_notify = vim.notify
      vim.notify = function(msg, _) if msg:find("no untagged") then notified = true end end
      tel.search_untagged()
      vim.notify = orig_notify
      assert.truthy(notified)
    end)

    it("does not notify when untagged notes exist", function()
      write_file(dir .. "/20260514--untagged.md", { "# UNTAGGED", "" })
      write_file(dir .. "/20260514--tagged__work.md", { "# TAGGED", "" })
      local notified = false
      local orig_notify = vim.notify
      vim.notify = function(msg, _) if msg:find("no untagged") then notified = true end end
      -- Telescope is unavailable in headless test env; we only care that it
      -- does not emit the "no untagged" notification before trying to open it
      pcall(tel.search_untagged)
      vim.notify = orig_notify
      assert.falsy(notified)
    end)

    it("excludes tagged notes from the untagged list", function()
      write_file(dir .. "/20260514--plain.md",        { "# PLAIN", "" })
      write_file(dir .. "/20260514--tagged__foo.md",  { "# TAGGED", "" })
      local orig_notify = vim.notify
      local notified = false
      vim.notify = function(msg, _) if msg:find("no untagged") then notified = true end end
      pcall(tel.search_untagged)
      vim.notify = orig_notify
      assert.falsy(notified)
    end)

    it("excludes templates from untagged search", function()
      make_template("bare", { "just content" })
      local notified = false
      local orig_notify = vim.notify
      vim.notify = function(msg, _) if msg:find("no untagged") then notified = true end end
      tel.search_untagged()
      vim.notify = orig_notify
      assert.truthy(notified)
    end)
  end)

  -- ─── pick_tags ───────────────────────────────────────────────────────────────

  describe("pick_tags", function()
    local saved = {}
    local telescope_modules = {
      "telescope.pickers", "telescope.finders",
      "telescope.config", "telescope.actions", "telescope.actions.state",
    }
    local saved_defer_fn

    before_each(function()
      saved_defer_fn = vim.defer_fn
      for _, mod in ipairs(telescope_modules) do
        saved[mod] = package.loaded[mod]
      end
    end)

    after_each(function()
      vim.defer_fn = saved_defer_fn
      for _, mod in ipairs(telescope_modules) do
        package.loaded[mod] = saved[mod]
      end
    end)

    local function setup_mock(steps)
      -- Normalize: single step object {multi=..., prompt=...} becomes {steps}
      if type(steps[1]) ~= "table" then steps = { steps } end

      local handles = { open_count = 0 }
      local step    = 0

      local function get_step()
        return steps[math.max(1, math.min(step, #steps))]
      end

      package.loaded["telescope.actions"] = {
        select_default   = { replace = function(_, fn) handles.enter = fn end },
        close            = function() end,
        toggle_selection = function() end,
      }
      package.loaded["telescope.actions.state"] = {
        get_current_picker = function()
          local s = get_step()
          return {
            get_multi_selection = function() return s.multi or {} end,
            manager             = { num_results = function() return 0 end, get_entry = function() return nil end },
            selection_row       = 1,
            move_selection      = function() end,
          }
        end,
        get_current_line = function() return get_step().prompt or "" end,
      }
      package.loaded["telescope.pickers"] = {
        new = function(_, picker_opts)
          step = step + 1
          handles.open_count = step
          return {
            find = function()
              local function map(mode, key, fn)
                if mode == "n" and key == "<Esc>" then handles.escape = fn end
              end
              picker_opts.attach_mappings(vim.api.nvim_get_current_buf(), map)
            end,
          }
        end,
      }
      package.loaded["telescope.finders"] = { new_table = function() return {} end }
      package.loaded["telescope.config"]  = { values = { generic_sorter = function() return {} end } }
      return handles
    end

    it("calls callback with {} when user deselects all pre-selected tags and confirms", function()
      local h = setup_mock({ multi = {}, prompt = "" })
      local result
      tel.pick_tags(function(tags) result = tags end, { pre_selected = { "foo", "bar" } })
      assert.truthy(h.enter, "select_default handler was not registered")
      h.enter()
      vim.wait(200, function() return result ~= nil end, 10)
      assert.same({}, result)
    end)

    it("does not call callback when user presses Escape (cancels the operation)", function()
      local h = setup_mock({ multi = {}, prompt = "" })
      local called = false
      tel.pick_tags(function() called = true end, { pre_selected = { "foo", "bar" } })
      assert.truthy(h.escape, "Escape handler was not registered")
      h.escape()
      vim.wait(200, function() return false end, 10)
      assert.falsy(called, "callback must not be called on Escape")
    end)

    it("calls callback with multi-selected items", function()
      local h = setup_mock({ multi = { { value = "lua" }, { value = "nvim" } }, prompt = "" })
      local result
      tel.pick_tags(function(tags) result = tags end, {})
      assert.truthy(h.enter)
      h.enter()
      vim.wait(200, function() return result ~= nil end, 10)
      assert.same({ "lua", "nvim" }, result)
    end)

    it("re-opens picker with typed tag pre-selected, finalizes on empty Enter", function()
      local h = setup_mock({
        { multi = {},                        prompt = "newtag" },
        { multi = { { value = "newtag" } },  prompt = ""       },
      })
      local result
      tel.pick_tags(function(tags) result = tags end, {})
      assert.truthy(h.enter)
      h.enter()
      vim.wait(200, function() return h.open_count >= 2 end, 10)
      h.enter()
      vim.wait(200, function() return result ~= nil end, 10)
      assert.same({ "newtag" }, result)
    end)

    it("does not duplicate typed tag when it matches a multi-selected item", function()
      local h = setup_mock({
        { multi = { { value = "lua" } }, prompt = "lua" },
        { multi = { { value = "lua" } }, prompt = ""    },
      })
      local result
      tel.pick_tags(function(tags) result = tags end, {})
      assert.truthy(h.enter)
      h.enter()
      vim.wait(200, function() return h.open_count >= 2 end, 10)
      h.enter()
      vim.wait(200, function() return result ~= nil end, 10)
      assert.same({ "lua" }, result)
    end)

    it("includes both multi-selected and typed tag when they differ", function()
      local h = setup_mock({
        { multi = { { value = "lua" } },                         prompt = "nvim" },
        { multi = { { value = "lua" }, { value = "nvim" } },     prompt = ""     },
      })
      local result
      tel.pick_tags(function(tags) result = tags end, {})
      assert.truthy(h.enter)
      h.enter()
      vim.wait(200, function() return h.open_count >= 2 end, 10)
      h.enter()
      vim.wait(200, function() return result ~= nil end, 10)
      assert.same({ "lua", "nvim" }, result)
    end)

    -- ─── pre-selection + sorting (rich mock) ─────────────────────────────────

    local function setup_rich_mock(steps)
      -- Like setup_mock but with a real-ish manager so the defer_fn pre-selection
      -- can be exercised. Cursor is 1-indexed to match Telescope's selection_row.
      -- vim.defer_fn is intercepted so pre-selection is called synchronously in tests.
      if type(steps[1]) ~= "table" then steps = { steps } end

      local handles       = { open_count = 0 }
      local step          = 0
      local cursor        = 0  -- 0-indexed visual row, matching Telescope's selection_row
      local toggled       = {}
      local finder_res    = {}
      local prompt_buf    = vim.api.nvim_create_buf(false, true)  -- scratch buf stays valid
      local orig_defer    = vim.defer_fn
      local pending_defer = nil

      local function get_step()
        return steps[math.max(1, math.min(step, #steps))]
      end

      -- Intercept defer_fn so we can trigger pre-selection on demand
      vim.defer_fn = function(fn, _) pending_defer = fn end

      package.loaded["telescope.finders"] = {
        new_table = function(o)
          finder_res = vim.deepcopy(o.results)
          return {}
        end,
      }
      package.loaded["telescope.config"] = { values = { generic_sorter = function() return {} end } }
      package.loaded["telescope.actions"] = {
        select_default   = { replace = function(_, fn) handles.enter = fn end },
        close            = function() end,
        toggle_selection = function()
          -- cursor is 0-indexed; finder_res is 1-indexed
          if finder_res[cursor + 1] then
            table.insert(toggled, finder_res[cursor + 1])
          end
        end,
      }
      package.loaded["telescope.actions.state"] = {
        get_current_picker = function()
          local res = finder_res
          return {
            get_multi_selection = function(_)
              return vim.tbl_map(function(v) return { value = v } end, toggled)
            end,
            manager = {
              num_results = function(_) return #res end,
              get_entry   = function(_, i) return res[i] and { value = res[i] } or nil end,
            },
            sorting_strategy  = "ascending",
            get_selection_row = function(_) return cursor end,
            get_reset_row     = function(_) return 0 end,
            get_index         = function(_, row) return row + 1 end,
            move_selection    = function(_, delta) cursor = cursor + delta end,
          }
        end,
        get_current_line = function() return get_step().prompt or "" end,
      }
      package.loaded["telescope.pickers"] = {
        new = function(_, picker_opts)
          step             = step + 1
          handles.open_count = step
          cursor           = 0  -- reset to 0-indexed row 0 on each new picker
          toggled          = {}
          pending_defer    = nil
          return {
            find = function()
              local function map(mode, key, fn)
                if mode == "n" and key == "<Esc>" then handles.escape = fn end
              end
              picker_opts.attach_mappings(prompt_buf, map)
              -- run any scheduled pre-selection immediately (synchronous in tests)
              if pending_defer then
                local fn = pending_defer
                pending_defer = nil
                fn()
              end
            end,
          }
        end,
      }
      handles.get_finder_res = function() return finder_res end
      handles.get_toggled    = function() return toggled end
      handles.cleanup = function()
        vim.defer_fn = orig_defer
        pcall(vim.api.nvim_buf_delete, prompt_buf, { force = true })
      end
      return handles
    end

    it("presents all tags in alphabetical order (including extra_tags)", function()
      write_file(dir .. "/20240101T120000--n1__zzz.md",  { "# N1" })
      write_file(dir .. "/20240101T120001--n2__bbb.md",  { "# N2" })
      local h = setup_rich_mock({ prompt = "" })
      tel.pick_tags(function() end, { extra_tags = { "mmm" } })
      assert.same({ "bbb", "mmm", "zzz" }, h.get_finder_res())
      h.cleanup()
    end)

    it("pre-selects extra_tags (new typed tags) when the picker re-opens", function()
      write_file(dir .. "/20240101T120000--n1__bbb.md", { "# N1" })
      local h = setup_rich_mock({
        { multi = {}, prompt = "zzz_new" },
        { multi = {},  prompt = ""        },
      })
      local result
      tel.pick_tags(function(tags) result = tags end, {})
      h.enter()
      vim.wait(300, function() return h.open_count >= 2 end, 10)
      assert.equals(2, h.open_count, "second picker should open")
      assert.same({ "bbb", "zzz_new" }, h.get_finder_res(), "tags should be sorted alphabetically")
      assert.same({ "zzz_new" }, h.get_toggled(), "zzz_new should be pre-selected")
      h.enter()
      vim.wait(200, function() return result ~= nil end, 10)
      assert.same({ "zzz_new" }, result)
      h.cleanup()
    end)

    it("pre-selects existing tags for refactor flow", function()
      write_file(dir .. "/20240101T120000--n1__aaa_ccc.md", { "# N1" })
      local h = setup_rich_mock({ prompt = "" })
      tel.pick_tags(function() end, { pre_selected = { "aaa", "ccc" } })
      assert.same({ "aaa", "ccc" }, h.get_toggled(), "both tags should be pre-selected")
      h.cleanup()
    end)

    -- ─── broad multi-step scenarios ──────────────────────────────────────────

    -- Helper: open multiple pickers in sequence with the rich mock.
    -- Each entry in `interactions` is a function(h) that drives one picker step
    -- by calling h.enter() or h.escape() and asserting intermediate state.
    -- Returns the final callback result.
    local function run_scenario(existing_tags, interactions)
      for _, tag in ipairs(existing_tags) do
        write_file(dir .. "/20240101T120000--x__" .. tag .. ".md", { "# X" })
      end

      -- Build a step list that always returns empty prompt unless overridden
      local prompts = {}
      local h = setup_rich_mock(vim.tbl_map(function(p) return { prompt = p } end,
        vim.list_extend(vim.deepcopy(prompts), { "" })))
      -- We need dynamic prompts per step, so replace get_current_line per call
      local prompt_seq = {}
      local prompt_call = 0
      package.loaded["telescope.actions.state"].get_current_line = function()
        prompt_call = prompt_call + 1
        return prompt_seq[prompt_call] or ""
      end

      local result
      tel.pick_tags(function(tags) result = tags end, {})

      for _, interaction in ipairs(interactions) do
        interaction(h, prompt_seq)
        vim.wait(300, function() return result ~= nil or h.open_count > #interactions end, 10)
      end
      vim.wait(200, function() return result ~= nil end, 10)
      h.cleanup()
      return result
    end

    it("multiple space-separated new tags typed in one step", function()
      write_file(dir .. "/20240101T120000--n1__existing.md", { "# N1" })
      local h = setup_rich_mock({
        { prompt = "alpha beta gamma" },
        { prompt = ""                 },
      })
      local result
      tel.pick_tags(function(tags) result = tags end, {})
      h.enter()
      vim.wait(300, function() return h.open_count >= 2 end, 10)
      assert.same({ "alpha", "beta", "gamma" }, h.get_toggled(),
        "all three typed tags should be pre-selected in second picker")
      h.enter()
      vim.wait(200, function() return result ~= nil end, 10)
      table.sort(result)
      assert.same({ "alpha", "beta", "gamma" }, result)
      h.cleanup()
    end)

    it("typed tags appear sorted among existing tags", function()
      write_file(dir .. "/20240101T120000--n1__mmm.md", { "# N1" })
      local h = setup_rich_mock({
        { prompt = "aaa zzz" },
        { prompt = ""        },
      })
      local result
      tel.pick_tags(function(tags) result = tags end, {})
      h.enter()
      vim.wait(300, function() return h.open_count >= 2 end, 10)
      assert.same({ "aaa", "mmm", "zzz" }, h.get_finder_res(),
        "second picker should show all tags in alphabetical order")
      h.cleanup()
      -- result not needed, just checking sort
      package.loaded["telescope.actions.state"].get_current_line = function() return "" end
    end)

    it("ESC cancels without calling callback", function()
      local h = setup_rich_mock({ prompt = "" })
      local called = false
      tel.pick_tags(function() called = true end, {})
      h.escape()
      vim.wait(200, function() return false end, 10)
      assert.falsy(called, "ESC must not create/update anything")
      h.cleanup()
    end)

    it("ESC during re-opened picker cancels entirely", function()
      local h = setup_rich_mock({
        { prompt = "newtag" },
        { prompt = ""       },
      })
      local called = false
      tel.pick_tags(function() called = true end, {})
      h.enter()
      vim.wait(300, function() return h.open_count >= 2 end, 10)
      h.escape()
      vim.wait(200, function() return false end, 10)
      assert.falsy(called, "ESC in second picker must not trigger callback")
      h.cleanup()
    end)

    it("three-step accumulation: type in step 1, type more in step 2, confirm in step 3", function()
      local h = setup_rich_mock({
        { prompt = "aaa" },
        { prompt = "bbb" },
        { prompt = ""    },
      })
      local result
      tel.pick_tags(function(tags) result = tags end, {})

      -- step 1: type "aaa"
      h.enter()
      vim.wait(300, function() return h.open_count >= 2 end, 10)
      assert.same({ "aaa" }, h.get_toggled(), "step 2: aaa pre-selected")

      -- step 2: type "bbb"
      h.enter()
      vim.wait(300, function() return h.open_count >= 3 end, 10)
      assert.same({ "aaa", "bbb" }, h.get_toggled(), "step 3: both aaa and bbb pre-selected")

      -- step 3: confirm
      h.enter()
      vim.wait(200, function() return result ~= nil end, 10)
      table.sort(result)
      assert.same({ "aaa", "bbb" }, result)
      h.cleanup()
    end)

    it("pre-selected tag that user deselects is absent from final callback", function()
      -- Simulate: type "keep remove" -> second picker pre-selects both ->
      -- user Tab-deselects "remove" (mock: get_multi_selection only has "keep") -> confirm
      local h = setup_rich_mock({
        { prompt = "keep remove" },
        { prompt = ""            },
      })
      -- Override get_multi_selection for the second picker to simulate user deselecting "remove"
      local step2_multi_override = nil
      local orig_state = package.loaded["telescope.actions.state"]
      local orig_get_picker = orig_state.get_current_picker
      local picker_call = 0
      orig_state.get_current_picker = function(buf)
        local picker = orig_get_picker(buf)
        picker_call = picker_call + 1
        if picker_call > 1 then
          -- second picker's enter: user has deselected "remove"
          picker.get_multi_selection = function(_)
            return { { value = "keep" } }
          end
        end
        return picker
      end

      local result
      tel.pick_tags(function(tags) result = tags end, {})
      h.enter()
      vim.wait(300, function() return h.open_count >= 2 end, 10)
      assert.same({ "keep", "remove" }, h.get_toggled(), "both should be pre-selected")
      h.enter()
      vim.wait(200, function() return result ~= nil end, 10)
      assert.same({ "keep" }, result, "only 'keep' should be in callback")
      h.cleanup()
    end)

    it("re-typed tag that was previously deselected is included in callback", function()
      -- step 1: type "a b" -> picker 2 has a+b pre-selected
      -- step 2: user deselected "a" (multi only has "b"), types "a" again -> picker 3 has a+b pre-selected
      -- step 3: confirm -> callback(["a","b"])
      local h = setup_rich_mock({
        { prompt = "a b" },
        { prompt = "a"   },
        { prompt = ""    },
      })
      -- Picker 2's enter: multi only has "b" (user deselected "a")
      local orig_state = package.loaded["telescope.actions.state"]
      local orig_get_picker = orig_state.get_current_picker
      local call_count = 0
      orig_state.get_current_picker = function(buf)
        local picker = orig_get_picker(buf)
        call_count = call_count + 1
        if call_count == 2 then
          picker.get_multi_selection = function(_) return { { value = "b" } } end
        end
        return picker
      end

      local result
      tel.pick_tags(function(tags) result = tags end, {})

      h.enter()  -- picker 1 -> picker 2
      vim.wait(300, function() return h.open_count >= 2 end, 10)
      assert.same({ "a", "b" }, h.get_toggled(), "picker 2: a and b pre-selected")

      h.enter()  -- picker 2 -> picker 3 (typed "a" while multi only had "b")
      vim.wait(300, function() return h.open_count >= 3 end, 10)
      assert.same({ "a", "b" }, h.get_toggled(), "picker 3: a and b pre-selected")

      h.enter()  -- picker 3: confirm
      vim.wait(200, function() return result ~= nil end, 10)
      table.sort(result)
      assert.same({ "a", "b" }, result)
      h.cleanup()
    end)

    it("duplicate typed tag is not added twice", function()
      local h = setup_rich_mock({
        { prompt = "x x" },  -- typed the same tag twice in the prompt
        { prompt = ""    },
      })
      local result
      tel.pick_tags(function(tags) result = tags end, {})
      h.enter()
      vim.wait(300, function() return h.open_count >= 2 end, 10)
      assert.same({ "x" }, h.get_toggled(), "x should be pre-selected exactly once")
      h.enter()
      vim.wait(200, function() return result ~= nil end, 10)
      assert.same({ "x" }, result)
      h.cleanup()
    end)

    it("slug normalisation: typed tag with spaces and hyphens is stored as underscore slug", function()
      local h = setup_rich_mock({
        { prompt = "my-tag" },
        { prompt = ""       },
      })
      local result
      tel.pick_tags(function(tags) result = tags end, {})
      h.enter()
      vim.wait(300, function() return h.open_count >= 2 end, 10)
      -- my-tag slugifies to my_tag
      assert.same({ "my_tag" }, h.get_toggled(), "my-tag should be stored as my_tag")
      h.enter()
      vim.wait(200, function() return result ~= nil end, 10)
      assert.same({ "my_tag" }, result)
      h.cleanup()
    end)

    it("empty Enter on first open (no selection, no typing) calls callback with empty list", function()
      local h = setup_rich_mock({ prompt = "" })
      local result
      tel.pick_tags(function(tags) result = tags end, {})
      h.enter()
      vim.wait(200, function() return result ~= nil end, 10)
      assert.same({}, result)
      h.cleanup()
    end)

    -- ─── descending-strategy mock (reproduces real Telescope behavior) ─────────
    --
    -- setup_rich_mock sets selection_row on the picker table, so
    -- picker.selection_row or 0 returns the correct cursor.  Real Telescope stores
    -- the cursor as picker._selection_row (private field), so picker.selection_row
    -- is always nil and the denim code always starts with current=0.
    --
    -- Telescope's default sorting_strategy is "descending": the cursor starts at
    -- visual row max_results-1 (bottom), and get_index(row) = max_results - row,
    -- so the entry at manager index i is at visual row max_results-i.  The denim
    -- code assumes entry i is at row i-1 (ascending), so move_selection lands on
    -- the wrong row and toggles the wrong tag.

    local function setup_descending_mock(steps, max_r)
      -- max_r: simulated max_results (results window height, default 10)
      max_r = max_r or 10
      if type(steps[1]) ~= "table" then steps = { steps } end

      local handles       = { open_count = 0 }
      local step          = 0
      local sel_row       = max_r - 1  -- cursor at bottom, as in descending Telescope
      local toggled       = {}
      local finder_res    = {}
      local prompt_buf    = vim.api.nvim_create_buf(false, true)
      local orig_defer    = vim.defer_fn
      local pending_defer = nil

      local function get_step()
        return steps[math.max(1, math.min(step, #steps))]
      end

      vim.defer_fn = function(fn, _) pending_defer = fn end

      package.loaded["telescope.finders"] = {
        new_table = function(o)
          finder_res = vim.deepcopy(o.results)
          return {}
        end,
      }
      package.loaded["telescope.config"] = { values = { generic_sorter = function() return {} end } }
      package.loaded["telescope.actions"] = {
        select_default   = { replace = function(_, fn) handles.enter = fn end },
        close            = function() end,
        toggle_selection = function()
          -- descending: get_index(row) = max_r - row
          -- so entry at current visual row sel_row has manager index (max_r - sel_row)
          local idx = max_r - sel_row
          if finder_res[idx] then
            table.insert(toggled, finder_res[idx])
          end
        end,
      }
      package.loaded["telescope.actions.state"] = {
        get_current_picker = function()
          local res = finder_res
          return {
            sorting_strategy  = "descending",
            get_selection_row = function(_) return sel_row end,
            get_reset_row     = function(_) return max_r - 1 end,
            get_index         = function(_, row) return max_r - row end,
            get_multi_selection = function()
              return vim.tbl_map(function(v) return { value = v } end, toggled)
            end,
            manager = {
              num_results = function() return #res end,
              get_entry   = function(_, i) return res[i] and { value = res[i] } or nil end,
            },
            move_selection = function(_, delta)
              sel_row = sel_row + delta
              if sel_row < 0      then sel_row = 0        end
              if sel_row >= max_r then sel_row = max_r - 1 end
            end,
          }
        end,
        get_current_line = function() return get_step().prompt or "" end,
      }
      package.loaded["telescope.pickers"] = {
        new = function(_, picker_opts)
          step             = step + 1
          handles.open_count = step
          sel_row          = max_r - 1  -- reset to bottom on each new picker
          toggled          = {}
          pending_defer    = nil
          return {
            find = function()
              local function map(mode, key, fn)
                if mode == "n" and key == "<Esc>" then handles.escape = fn end
              end
              picker_opts.attach_mappings(prompt_buf, map)
              if pending_defer then
                local fn = pending_defer
                pending_defer = nil
                fn()
              end
            end,
          }
        end,
      }
      handles.get_finder_res = function() return finder_res end
      handles.get_toggled    = function() return toggled end
      handles.cleanup = function()
        vim.defer_fn = orig_defer
        pcall(vim.api.nvim_buf_delete, prompt_buf, { force = true })
      end
      return handles
    end

    it("[bug] pre-selects newly typed tag when it sorts after an existing disk tag", function()
      -- Disk tag: "aaa".  User types "zzz" -> picker re-opens with pre_selected={"zzz"}.
      -- Sorted tags: ["aaa", "zzz"]. In a descending picker (max_r=10):
      --   "aaa" at manager index 1, visual row 9 (bottom) - cursor starts here.
      --   "zzz" at manager index 2, visual row 8.
      -- Bug: picker.selection_row is nil so current=0; move_selection(1) moves the
      -- cursor from row 9 to 10, clamped back to 9, toggling "aaa" instead of "zzz".
      write_file(dir .. "/20240101T120000--n1__aaa.md", { "# N1" })
      local h = setup_descending_mock({ prompt = "" })
      tel.pick_tags(function() end, { pre_selected = { "zzz" }, extra_tags = { "zzz" } })
      assert.same({ "zzz" }, h.get_toggled(),
        "zzz should be pre-selected, not the existing disk tag aaa")
      h.cleanup()
    end)

    it("[bug] pre-selects multiple tags correctly in descending picker", function()
      -- Disk tags: "aaa", "bbb", "ccc". pre_selected={"aaa","ccc"} (refactor flow).
      -- Bug: after toggling "aaa" (which happens to be correct because move_selection(0)
      -- keeps cursor at the bottom row pointing at manager index 1 = "aaa"), current is
      -- still tracked as 0, so the delta for "ccc" is (3-1)-0=2, cursor goes to 11
      -- (clamped to 9), toggling manager index 1 = "aaa" again instead of "ccc".
      write_file(dir .. "/20240101T120000--n1__aaa_bbb_ccc.md", { "# N1" })
      local h = setup_descending_mock({ prompt = "" })
      tel.pick_tags(function() end, { pre_selected = { "aaa", "ccc" } })
      assert.same({ "aaa", "ccc" }, h.get_toggled(),
        "both aaa and ccc should be pre-selected in descending picker")
      h.cleanup()
    end)
  end)
end)
