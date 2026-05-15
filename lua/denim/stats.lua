local M = {}

local function get_opts()
  return require("denim.config").options
end

local function gather_stats(notes_dir)
  local all = vim.fn.systemlist({
    "find", notes_dir, "-maxdepth", "1", "-name", "*.md",
  })

  local today = os.date("*t")
  local this_month = string.format("%04d%02d", today.year, today.month)
  local lm_year = today.year
  local lm_num  = today.month - 1
  if lm_num == 0 then lm_num = 12; lm_year = lm_year - 1 end
  local last_month = string.format("%04d%02d", lm_year, lm_num)

  local stats = {
    notes = 0, open_todos = 0, done_todos = 0,
    this_month = 0, last_month = 0,
    tags = {}, linked = 0,
  }

  for _, filepath in ipairs(all) do
    local filename = vim.fn.fnamemodify(filepath, ":t")
    local date_raw = filename:match("^(%d%d%d%d%d%d%d%d)")
    if date_raw then
      if filename:match("^%d+T?%d*%-O%-") then
        stats.open_todos = stats.open_todos + 1
      elseif filename:match("^%d+T?%d*%-X%-") then
        stats.done_todos = stats.done_todos + 1
      else
        stats.notes = stats.notes + 1
      end

      local month = date_raw:sub(1, 6)
      if month == this_month then stats.this_month = stats.this_month + 1 end
      if month == last_month  then stats.last_month = stats.last_month + 1 end

      local tag_part = filename:match("__([^%.]+)%.md$")
      if tag_part then
        for tag in tag_part:gmatch("[^_]+") do
          stats.tags[tag] = (stats.tags[tag] or 0) + 1
        end
      end
    end
  end

  if #all > 0 then
    local cmd = { "grep", "-l", "](", "--" }
    for _, f in ipairs(all) do table.insert(cmd, f) end
    stats.linked = #vim.fn.systemlist(cmd)
  end

  return stats
end

local function build_lines(stats)
  local total = stats.notes + stats.open_todos + stats.done_todos

  local unique_tags = 0
  local tag_list = {}
  for tag, count in pairs(stats.tags) do
    unique_tags = unique_tags + 1
    table.insert(tag_list, { tag = tag, count = count })
  end
  table.sort(tag_list, function(a, b)
    if a.count == b.count then return a.tag < b.tag end
    return a.count > b.count
  end)

  local function row(label, n)
    return string.format("  %-14s %d", label, n)
  end

  local function row_pct(label, n, denom)
    local pct = denom > 0 and math.floor(n / denom * 100 + 0.5) or 0
    return string.format("  %-14s %d  (%d%%)", label, n, pct)
  end

  local lines = {
    "# Notes Statistics", "",
    "## Overview", "",
    row("Total",       total),
    row("Notes",       stats.notes),
    row("Open todos",  stats.open_todos),
    row("Done todos",  stats.done_todos),
    row("Tags",        unique_tags),
    row_pct("Linked",  stats.linked, total),
    "",
    "## Activity", "",
    row("This month",  stats.this_month),
    row("Last month",  stats.last_month),
  }

  if #tag_list > 0 then
    table.insert(lines, "")
    table.insert(lines, "## Top Tags")
    table.insert(lines, "")
    for i = 1, math.min(10, #tag_list) do
      local e = tag_list[i]
      table.insert(lines, string.format("  %-20s %d", e.tag, e.count))
    end
  end

  return lines
end

M._build_lines  = build_lines
M._gather_stats = gather_stats

function M.open()
  local opts    = get_opts()
  local stats   = gather_stats(opts.notes_dir)
  local lines   = build_lines(stats)
  local bufname = opts.notes_dir .. "/.stats"

  local bufnr = vim.fn.bufnr(bufname)
  if bufnr == -1 then
    bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, bufname)
  end

  vim.api.nvim_set_option_value("buftype",    "nofile",   { buf = bufnr })
  vim.api.nvim_set_option_value("swapfile",   false,      { buf = bufnr })
  vim.api.nvim_set_option_value("filetype",   "markdown", { buf = bufnr })
  vim.api.nvim_set_option_value("modifiable", true,       { buf = bufnr })
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false,      { buf = bufnr })

  vim.api.nvim_set_current_buf(bufnr)
  vim.api.nvim_win_set_cursor(0, { 1, 0 })

  vim.keymap.set("n", "r", function() M.open() end,
    { buffer = bufnr, desc = "denim: refresh stats" })
  vim.keymap.set("n", "q", "<cmd>bdelete<cr>",
    { buffer = bufnr, desc = "denim: close stats" })
end

return M
