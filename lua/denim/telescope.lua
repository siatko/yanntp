local M = {}

local function get_opts()
  return require("denim.config").options
end

local utils = require("denim.utils")

local function get_telescope()
  local ok, t = pcall(require, "telescope.builtin")
  if not ok then
    vim.notify("denim: telescope.nvim is required for search", vim.log.levels.ERROR)
    return nil
  end
  return t
end

local function find_cmd()
  if vim.fn.executable("fd") == 1 then
    return { "fd", "--type", "f", "--extension", "md" }
  end
  return { "find", ".", "-name", "*.md" }
end

function M.search_notes()
  local t = get_telescope()
  if not t then return end

  t.find_files({
    prompt_title = "Notes",
    cwd = get_opts().notes_dir,
    find_command = find_cmd(),
  })
end

function M.search_content()
  local t = get_telescope()
  if not t then return end

  t.live_grep({
    prompt_title = "Notes Content",
    cwd = get_opts().notes_dir,
    additional_args = { "--glob", "*.md" },
  })
end


local function all_note_files(notes_dir)
  return vim.fn.systemlist({ "find", notes_dir, "-maxdepth", "1", "-name", "*.md" })
end

local tags_from_filename = utils.tags_from_filename

local function collect_tags(notes_dir)
  local seen, tags = {}, {}
  for _, filepath in ipairs(all_note_files(notes_dir)) do
    for _, tag in ipairs(tags_from_filename(vim.fn.fnamemodify(filepath, ":t"))) do
      if not seen[tag] then
        seen[tag] = true
        table.insert(tags, tag)
      end
    end
  end
  table.sort(tags)
  return tags
end

local function files_with_all_tags(notes_dir, selected_tags)
  local result = {}
  for _, filepath in ipairs(all_note_files(notes_dir)) do
    local tag_set = {}
    for _, t in ipairs(tags_from_filename(vim.fn.fnamemodify(filepath, ":t"))) do
      tag_set[t] = true
    end
    local has_all = true
    for _, tag in ipairs(selected_tags) do
      if not tag_set[tag] then has_all = false; break end
    end
    if has_all then table.insert(result, filepath) end
  end
  return result
end

local function open_tag_results(notes_dir, selected)
  local files = files_with_all_tags(notes_dir, selected)
  if #files == 0 then
    vim.notify("denim: no notes found for tags: " .. table.concat(selected, " "), vim.log.levels.INFO)
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf    = require("telescope.config").values

  pickers.new({}, {
    prompt_title = "Tags: " .. table.concat(selected, " "),
    finder = finders.new_table({
      results = files,
      entry_maker = function(entry)
        return {
          value   = entry,
          display = vim.fn.fnamemodify(entry, ":~:."),
          ordinal = entry,
          path    = entry,
        }
      end,
    }),
    sorter    = conf.generic_sorter({}),
    previewer = conf.file_previewer({}),
  }):find()
end

local relative_path = utils.relative_path

function M.insert_link()
  local notes_dir    = get_opts().notes_dir
  local current_file = vim.fn.expand("%:p")

  if current_file == "" then
    vim.notify("denim: save the file before inserting a link", vim.log.levels.WARN)
    return
  end

  local entries = {}
  for _, filepath in ipairs(all_note_files(notes_dir)) do
    if filepath ~= current_file then
      local lines = vim.fn.readfile(filepath, "", 1)
      local title = (lines and lines[1] and lines[1]:match("^#%s+(.+)$"))
        or vim.fn.fnamemodify(filepath, ":t:r")
      table.insert(entries, { path = filepath, title = title })
    end
  end

  local pickers      = require("telescope.pickers")
  local finders      = require("telescope.finders")
  local conf         = require("telescope.config").values
  local actions      = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local from_dir     = vim.fn.fnamemodify(current_file, ":h")

  pickers.new({}, {
    prompt_title = "Link to note",
    finder = finders.new_table({
      results = entries,
      entry_maker = function(e)
        return {
          value   = e,
          display = e.title .. "  (" .. vim.fn.fnamemodify(e.path, ":t") .. ")",
          ordinal = e.title .. " " .. vim.fn.fnamemodify(e.path, ":t"),
          path    = e.path,
        }
      end,
    }),
    sorter    = conf.generic_sorter({}),
    previewer = conf.file_previewer({}),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        if not entry then return end
        actions.close(prompt_bufnr)
        vim.schedule(function()
          local rel  = relative_path(from_dir, entry.value.path)
          local link = string.format("[%s](%s)", entry.value.title, rel)
          local row, col = unpack(vim.api.nvim_win_get_cursor(0))
          local ln = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
          vim.api.nvim_buf_set_lines(0, row - 1, row, false,
            { ln:sub(1, col + 1) .. link .. ln:sub(col + 2) })
          vim.api.nvim_win_set_cursor(0, { row, col + #link })
        end)
      end)
      return true
    end,
  }):find()
end

function M.update_links_to(old_filepath, new_filepath)
  local old_abs = vim.fn.fnamemodify(old_filepath, ":p")
  local new_abs = vim.fn.fnamemodify(new_filepath, ":p")
  local updated = 0

  for _, filepath in ipairs(all_note_files(get_opts().notes_dir)) do
    local abs      = vim.fn.fnamemodify(filepath, ":p")
    if abs ~= old_abs and abs ~= new_abs then
      local lines    = vim.fn.readfile(filepath)
      local file_dir = vim.fn.fnamemodify(filepath, ":h")
      local changed  = false

      local new_lines = vim.tbl_map(function(line)
        return line:gsub("%[(.-)%]%((.-)%)", function(text, path)
          local resolved = vim.fn.fnamemodify(file_dir .. "/" .. path, ":p")
          if resolved == old_abs then
            changed = true
            return "[" .. text .. "](" .. relative_path(file_dir, new_filepath) .. ")"
          end
        end)
      end, lines)

      if changed then
        vim.fn.writefile(new_lines, filepath)
        updated = updated + 1
        local bufnr = vim.fn.bufnr(filepath)
        if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
          vim.api.nvim_buf_call(bufnr, function() vim.cmd("edit") end)
        end
      end
    end
  end

  if updated > 0 then
    vim.notify(
      string.format("denim: updated links in %d note%s", updated, updated == 1 and "" or "s"),
      vim.log.levels.INFO
    )
  end
end

function M.backlinks()
  local current_file = vim.fn.expand("%:p")
  if current_file == "" then
    vim.notify("denim: save the file first", vim.log.levels.WARN)
    return
  end

  local filename  = vim.fn.fnamemodify(current_file, ":t")
  local notes_dir = get_opts().notes_dir
  local results   = {}

  for _, filepath in ipairs(all_note_files(notes_dir)) do
    if filepath ~= current_file then
      for _, line in ipairs(vim.fn.readfile(filepath)) do
        if line:find(filename, 1, true) then
          table.insert(results, filepath)
          break
        end
      end
    end
  end

  if #results == 0 then
    vim.notify("denim: no backlinks to " .. filename, vim.log.levels.INFO)
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf    = require("telescope.config").values

  pickers.new({}, {
    prompt_title = "Backlinks → " .. filename,
    finder = finders.new_table({
      results = results,
      entry_maker = function(entry)
        local lines = vim.fn.readfile(entry, "", 1)
        local title = (lines and lines[1] and lines[1]:match("^#%s+(.+)$"))
          or vim.fn.fnamemodify(entry, ":t:r")
        return {
          value   = entry,
          display = title .. "  (" .. vim.fn.fnamemodify(entry, ":t") .. ")",
          ordinal = title,
          path    = entry,
        }
      end,
    }),
    sorter    = conf.generic_sorter({}),
    previewer = conf.file_previewer({}),
  }):find()
end

function M.pick_tags(callback, opts)
  opts = opts or {}
  local pre_selected = opts.pre_selected or {}
  local all_tags     = collect_tags(get_opts().notes_dir)

  table.sort(all_tags)

  local pickers      = require("telescope.pickers")
  local finders      = require("telescope.finders")
  local conf         = require("telescope.config").values
  local actions      = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  pickers.new({}, {
    prompt_title = opts.title or "Tags  (<Tab> multi-select, <Esc> skip)",
    finder = finders.new_table({ results = all_tags }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      if #pre_selected > 0 then
        vim.defer_fn(function()
          if not vim.api.nvim_buf_is_valid(prompt_bufnr) then return end
          local picker = action_state.get_current_picker(prompt_bufnr)
          if not picker or not picker._multi or not picker.manager then return end
          local pre_set = {}
          for _, t in ipairs(pre_selected) do pre_set[t] = true end
          local num = picker.manager:num_results()
          for i = 1, num do
            local entry = picker.manager:get_entry(i)
            if entry and pre_set[entry.value] then
              picker._multi:add(entry)
            end
          end
          picker:refresh(finders.new_table({ results = all_tags }), { reset_prompt = false })
        end, 50)
      end

      actions.select_default:replace(function()
        local picker      = action_state.get_current_picker(prompt_bufnr)
        local multi       = picker:get_multi_selection()
        local prompt_text = vim.trim(action_state.get_current_line())
        local selected    = {}

        if #multi > 0 then
          for _, e in ipairs(multi) do
            table.insert(selected, e.value)
          end
        elseif prompt_text == "" then
          -- nothing explicitly selected: keep existing tags
          actions.close(prompt_bufnr)
          vim.schedule(function() callback(pre_selected) end)
          return
        end

        if prompt_text ~= "" then
          local found = false
          for _, s in ipairs(selected) do
            if s == prompt_text then found = true; break end
          end
          if not found then table.insert(selected, prompt_text) end
        end

        actions.close(prompt_bufnr)
        vim.schedule(function() callback(selected) end)
      end)
      map("n", "<Esc>", function()
        actions.close(prompt_bufnr)
        vim.schedule(function() callback(pre_selected) end)
      end)
      map("i", "<Esc>", function()
        actions.close(prompt_bufnr)
        vim.schedule(function() callback(pre_selected) end)
      end)
      return true
    end,
  }):find()
end

function M.list_open_todos()
  local t = get_telescope()
  if not t then return end
  local notes_dir = get_opts().notes_dir
  t.find_files({
    prompt_title = "Open Todos",
    cwd = notes_dir,
    find_command = { "find", notes_dir, "-maxdepth", "1", "-name", "*-O-*.md" },
  })
end

function M.list_done_todos()
  local t = get_telescope()
  if not t then return end
  local notes_dir = get_opts().notes_dir
  t.find_files({
    prompt_title = "Done Todos",
    cwd = notes_dir,
    find_command = { "find", notes_dir, "-maxdepth", "1", "-name", "*-X-*.md" },
  })
end

function M.search_tags()
  local notes_dir = get_opts().notes_dir
  local all_tags = collect_tags(notes_dir)

  if #all_tags == 0 then
    vim.notify("denim: no tags found in notes", vim.log.levels.INFO)
    return
  end

  local pickers      = require("telescope.pickers")
  local finders      = require("telescope.finders")
  local conf         = require("telescope.config").values
  local actions      = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  pickers.new({}, {
    prompt_title = "Tags  (<Tab> multi-select, <Enter> search)",
    finder = finders.new_table({ results = all_tags }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local picker = action_state.get_current_picker(prompt_bufnr)
        local multi  = picker:get_multi_selection()
        local selected
        if #multi > 0 then
          selected = vim.tbl_map(function(e) return e.value end, multi)
        else
          local entry = action_state.get_selected_entry()
          if not entry then return end
          selected = { entry.value }
        end
        actions.close(prompt_bufnr)
        vim.schedule(function() open_tag_results(notes_dir, selected) end)
      end)
      return true
    end,
  }):find()
end

return M
