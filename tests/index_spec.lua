local build_lines = require("denim.index")._build_lines

describe("build_lines", function()
  it("returns placeholder when no notes", function()
    local lines = build_lines({})
    assert.equal("No notes yet.", lines[3])
  end)

  it("includes header", function()
    local lines = build_lines({})
    assert.equal("# Notes Index", lines[1])
  end)

  it("renders a regular note", function()
    local notes = {
      { date = "20260514", date_fmt = "2026-05-14", status = "note",
        title = "My Note", rel_path = "inbox/20260514--my-note.md" },
    }
    local lines = build_lines(notes)
    assert.truthy(vim.tbl_contains(lines, "- [My Note](inbox/20260514--my-note.md)"))
  end)

  it("renders an open todo with checkbox", function()
    local notes = {
      { date = "20260514", date_fmt = "2026-05-14", status = "open_todo",
        title = "Fix Bug", rel_path = "20260514--fix-bug__todo.md" },
    }
    local lines = build_lines(notes)
    assert.truthy(vim.tbl_contains(lines, "- [ ] [Fix Bug](20260514--fix-bug__todo.md)"))
  end)

  it("renders a done todo with checked checkbox", function()
    local notes = {
      { date = "20260514", date_fmt = "2026-05-14", status = "done_todo",
        title = "Write Tests", rel_path = "20260514--write-tests__done.md" },
    }
    local lines = build_lines(notes)
    assert.truthy(vim.tbl_contains(lines, "- [x] [Write Tests](20260514--write-tests__done.md)"))
  end)

  it("groups notes under date headers", function()
    local notes = {
      { date = "20260514", date_fmt = "2026-05-14", status = "note",
        title = "Note A", rel_path = "inbox/a.md" },
      { date = "20260513", date_fmt = "2026-05-13", status = "note",
        title = "Note B", rel_path = "inbox/b.md" },
    }
    local lines = build_lines(notes)
    assert.truthy(vim.tbl_contains(lines, "## 2026-05-14"))
    assert.truthy(vim.tbl_contains(lines, "## 2026-05-13"))
  end)

  it("inserts a blank line between different-date groups", function()
    local notes = {
      { date = "20260514", date_fmt = "2026-05-14", status = "note",
        title = "Note A", rel_path = "inbox/a.md" },
      { date = "20260513", date_fmt = "2026-05-13", status = "note",
        title = "Note B", rel_path = "inbox/b.md" },
    }
    local lines = build_lines(notes)
    local pos13
    for i, l in ipairs(lines) do
      if l == "## 2026-05-13" then pos13 = i end
    end
    assert.truthy(pos13)
    assert.equal("", lines[pos13 - 1])
  end)

  it("does not repeat date header for same-day notes", function()
    local notes = {
      { date = "20260514", date_fmt = "2026-05-14", status = "note",
        title = "Note A", rel_path = "inbox/a.md" },
      { date = "20260514", date_fmt = "2026-05-14", status = "note",
        title = "Note B", rel_path = "inbox/b.md" },
    }
    local lines = build_lines(notes)
    local count = 0
    for _, l in ipairs(lines) do
      if l == "## 2026-05-14" then count = count + 1 end
    end
    assert.equal(1, count)
  end)
end)
