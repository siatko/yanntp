local M = {}

local function get_opts()
  return require("yanntp.config").options
end

local function gather_notes(notes_dir)
  local all = vim.fn.systemlist({
    "find", notes_dir, "-name", "*.md",
    "-not", "-path", "*/99_attachments/*",
  })

  local notes = {}
  for _, filepath in ipairs(all) do
    local filename = vim.fn.fnamemodify(filepath, ":t")
    local date_raw = filename:match("^(%d%d%d%d%d%d%d%d)")
    if date_raw then
      local status = "note"
      if filename:match("^%d+%-O%-") then
        status = "open_todo"
      elseif filename:match("^%d+%-X%-") then
        status = "done_todo"
      end

      local file_lines = vim.fn.readfile(filepath, "", 1)
      local title = (file_lines and file_lines[1] and file_lines[1]:match("^#%s+(.+)$"))
        or vim.fn.fnamemodify(filepath, ":t:r")

      local rel_dir = vim.fn.fnamemodify(filepath, ":h"):sub(#notes_dir + 2)

      table.insert(notes, {
        filepath = filepath,
        date     = date_raw,
        date_fmt = date_raw:sub(1, 4) .. "-" .. date_raw:sub(5, 6) .. "-" .. date_raw:sub(7, 8),
        title    = title,
        status   = status,
        rel_path = rel_dir .. "/" .. filename,
      })
    end
  end

  table.sort(notes, function(a, b)
    if a.date == b.date then return a.filepath > b.filepath end
    return a.date > b.date
  end)

  return notes
end

local function build_lines(notes)
  if #notes == 0 then
    return { "# Notes Index", "", "No notes yet." }
  end

  local lines        = { "# Notes Index", "" }
  local current_date = nil

  for _, note in ipairs(notes) do
    if note.date_fmt ~= current_date then
      if current_date then table.insert(lines, "") end
      table.insert(lines, "## " .. note.date_fmt)
      table.insert(lines, "")
      current_date = note.date_fmt
    end

    local item
    if note.status == "open_todo" then
      item = "- [ ] [" .. note.title .. "](" .. note.rel_path .. ")"
    elseif note.status == "done_todo" then
      item = "- [x] [" .. note.title .. "](" .. note.rel_path .. ")"
    else
      item = "- [" .. note.title .. "](" .. note.rel_path .. ")"
    end

    table.insert(lines, item)
  end

  return lines
end

M._build_lines = build_lines

function M.open()
  local opts    = get_opts()
  local bufname = opts.notes_dir .. "/.index"
  local notes   = gather_notes(opts.notes_dir)
  local lines   = build_lines(notes)

  local bufnr = vim.fn.bufnr(bufname)
  if bufnr == -1 then
    bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, bufname)
  end

  vim.api.nvim_set_option_value("buftype",  "nofile", { buf = bufnr })
  vim.api.nvim_set_option_value("swapfile", false,    { buf = bufnr })
  vim.api.nvim_set_option_value("filetype", "markdown", { buf = bufnr })
  vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })

  vim.api.nvim_set_current_buf(bufnr)
  vim.api.nvim_win_set_cursor(0, { 1, 0 })

  vim.keymap.set("n", "<CR>", function()
    require("yanntp.notes").follow_link()
  end, { buffer = bufnr, desc = "yanntp: follow link" })

  vim.keymap.set("n", "r", function()
    M.open()
  end, { buffer = bufnr, desc = "yanntp: refresh index" })

  vim.keymap.set("n", "q", "<cmd>bdelete<cr>", {
    buffer = bufnr, desc = "yanntp: close index",
  })
end

return M
