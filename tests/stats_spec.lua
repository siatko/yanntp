local build_lines = require("denim.stats")._build_lines

local function row(label, n)
  return string.format("  %-14s %d", label, n)
end

local function row_pct(label, n, denom)
  local pct = denom > 0 and math.floor(n / denom * 100 + 0.5) or 0
  return string.format("  %-14s %d  (%d%%)", label, n, pct)
end

local function empty_stats()
  return { notes = 0, open_todos = 0, done_todos = 0,
           this_month = 0, last_month = 0, tags = {}, linked = 0 }
end

describe("stats build_lines", function()
  it("includes header", function()
    assert.equal("# Notes Statistics", build_lines(empty_stats())[1])
  end)

  it("includes Overview and Activity sections", function()
    local lines = build_lines(empty_stats())
    assert.truthy(vim.tbl_contains(lines, "## Overview"))
    assert.truthy(vim.tbl_contains(lines, "## Activity"))
  end)

  it("omits Top Tags section when no tags", function()
    local lines = build_lines(empty_stats())
    assert.falsy(vim.tbl_contains(lines, "## Top Tags"))
  end)

  it("computes total as notes + open_todos + done_todos", function()
    local s = empty_stats()
    s.notes = 3; s.open_todos = 1; s.done_todos = 2
    local lines = build_lines(s)
    assert.truthy(vim.tbl_contains(lines, row("Total", 6)))
  end)

  it("renders notes, open_todos, done_todos counts separately", function()
    local s = empty_stats()
    s.notes = 4; s.open_todos = 2; s.done_todos = 1
    local lines = build_lines(s)
    assert.truthy(vim.tbl_contains(lines, row("Notes", 4)))
    assert.truthy(vim.tbl_contains(lines, row("Open todos", 2)))
    assert.truthy(vim.tbl_contains(lines, row("Done todos", 1)))
  end)

  it("counts unique tags", function()
    local s = empty_stats()
    s.tags = { work = 3, personal = 1, project = 2 }
    local lines = build_lines(s)
    assert.truthy(vim.tbl_contains(lines, row("Tags", 3)))
  end)

  it("renders linked count with percentage", function()
    local s = empty_stats()
    s.notes = 4; s.linked = 2
    local lines = build_lines(s)
    assert.truthy(vim.tbl_contains(lines, row_pct("Linked", 2, 4)))
  end)

  it("rounds linked percentage half-up", function()
    local s = empty_stats()
    s.notes = 3; s.linked = 2  -- 66.67% rounds to 67
    local lines = build_lines(s)
    assert.truthy(vim.tbl_contains(lines, row_pct("Linked", 2, 3)))
  end)

  it("shows 0% linked when total is zero", function()
    local s = empty_stats()
    local lines = build_lines(s)
    assert.truthy(vim.tbl_contains(lines, row_pct("Linked", 0, 0)))
  end)

  it("renders this month and last month counts", function()
    local s = empty_stats()
    s.this_month = 5; s.last_month = 3
    local lines = build_lines(s)
    assert.truthy(vim.tbl_contains(lines, row("This month", 5)))
    assert.truthy(vim.tbl_contains(lines, row("Last month", 3)))
  end)

  it("includes Top Tags section when tags exist", function()
    local s = empty_stats()
    s.tags = { work = 5 }
    local lines = build_lines(s)
    assert.truthy(vim.tbl_contains(lines, "## Top Tags"))
  end)

  it("sorts top tags by count descending", function()
    local s = empty_stats()
    s.tags = { alpha = 1, beta = 5, gamma = 3 }
    local lines = build_lines(s)
    local pos = {}
    for i, l in ipairs(lines) do
      for _, name in ipairs({ "alpha", "beta", "gamma" }) do
        if l:find(name, 1, true) then pos[name] = i end
      end
    end
    assert.truthy(pos.beta < pos.gamma and pos.gamma < pos.alpha)
  end)

  it("breaks count ties alphabetically ascending", function()
    local s = empty_stats()
    s.tags = { zebra = 2, apple = 2 }
    local lines = build_lines(s)
    local pos_a, pos_z
    for i, l in ipairs(lines) do
      if l:find("apple", 1, true) then pos_a = i end
      if l:find("zebra", 1, true) then pos_z = i end
    end
    assert.truthy(pos_a < pos_z)
  end)

  it("caps top tags display at 10 entries", function()
    local s = empty_stats()
    for i = 1, 15 do s.tags[string.format("tag%02d", i)] = i end
    local lines = build_lines(s)
    local in_tags, count = false, 0
    for _, l in ipairs(lines) do
      if l == "## Top Tags" then in_tags = true end
      if in_tags and l:match("^  %S") then count = count + 1 end
    end
    assert.equal(10, count)
  end)
end)
