local M = {}

local function get_opts()
  return require("denim.config").options
end

local utils = require("denim.utils")
local slugify_title   = utils.slugify_title
local slugify_tag     = utils.slugify_tag
local tags_from_filename = utils.tags_from_filename

local function uppercase(s)
  return s:upper()
end

function M.new_note()
  local opts = get_opts()

  vim.ui.input({ prompt = "Note name: " }, function(name)
    if not name or name == "" then return end
    vim.schedule(function()
      require("denim.telescope").pick_tags(function(tags)
        local date = os.date("%Y%m%dT%H%M%S")
        local slug = slugify_title(name)
        local slugged = vim.tbl_map(slugify_tag, tags)
        table.sort(slugged)
        local tag_suffix = #slugged > 0 and ("__" .. table.concat(slugged, "_")) or ""
        local filename = date .. "--" .. slug .. tag_suffix .. ".md"
        local filepath = opts.notes_dir .. "/" .. filename

        if vim.fn.filereadable(filepath) == 1 then
          vim.notify("denim: note already exists, opening: " .. filename, vim.log.levels.INFO)
          vim.cmd("edit " .. vim.fn.fnameescape(filepath))
          return
        end

        local f = io.open(filepath, "w")
        if f then
          f:write("# " .. uppercase(name) .. "\n\n")
          f:close()
        end
        vim.cmd("edit " .. vim.fn.fnameescape(filepath))
        vim.schedule(function()
          vim.api.nvim_win_set_cursor(0, { 2, 0 })
          vim.cmd("startinsert")
        end)
      end)
    end)
  end)
end

local function find_and_remove_stop(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for i, line in ipairs(lines) do
    local col = line:find("%$")
    if col then
      vim.api.nvim_buf_set_lines(bufnr, i - 1, i, false, { line:sub(1, col - 1) .. line:sub(col + 1) })
      vim.api.nvim_win_set_cursor(0, { i, col - 1 })
      return true
    end
  end
  return false
end

local function activate_tab_stops(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local has_stop = false
  for _, line in ipairs(lines) do
    if line:find("%$") then has_stop = true; break end
  end

  if not has_stop then
    vim.api.nvim_win_set_cursor(0, { 2, 0 })
    vim.cmd("startinsert")
    return
  end

  find_and_remove_stop(bufnr)
  vim.cmd("startinsert")
  vim.keymap.set("i", "<Tab>", function()
    if not find_and_remove_stop(bufnr) then
      vim.keymap.del("i", "<Tab>", { buffer = bufnr })
    end
  end, { buffer = bufnr })
end

local function open_path(path)
  local current_dir = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":h")
  local target = vim.fn.fnamemodify(current_dir .. "/" .. path, ":p")
  local ext = target:match("%.(%w+)$")
  local image_exts = { png=true, jpg=true, jpeg=true, gif=true, webp=true, svg=true, bmp=true, tiff=true, tif=true }
  if ext and image_exts[ext:lower()] then
    vim.notify("denim: image — " .. vim.fn.fnamemodify(target, ":t"), vim.log.levels.INFO)
  elseif vim.fn.filereadable(target) == 1 then
    vim.cmd("edit " .. vim.fn.fnameescape(target))
  else
    vim.notify("denim: file not found: " .. target, vim.log.levels.WARN)
  end
end

function M.new_template()
  local opts = get_opts()
  local tmpl_dir = opts.notes_dir .. "/.templates"
  vim.fn.mkdir(tmpl_dir, "p")
  vim.ui.input({ prompt = "Template name: " }, function(name)
    if not name or name == "" then return end
    local filename = slugify_title(name) .. ".md"
    local filepath = tmpl_dir .. "/" .. filename
    vim.schedule(function()
      vim.cmd("edit " .. vim.fn.fnameescape(filepath))
    end)
  end)
end

function M.new_note_from_template()
  local opts = get_opts()

  require("denim.telescope").pick_template(function(tmpl_path)
    vim.ui.input({ prompt = "Note name: " }, function(name)
      if not name or name == "" then return end
      vim.schedule(function()
        require("denim.telescope").pick_tags(function(tags)
          local date    = os.date("%Y%m%dT%H%M%S")
          local slug    = slugify_title(name)
          local slugged = vim.tbl_map(slugify_tag, tags)
          table.sort(slugged)
          local tag_suffix = #slugged > 0 and ("__" .. table.concat(slugged, "_")) or ""
          local filename   = date .. "--" .. slug .. tag_suffix .. ".md"
          local filepath   = opts.notes_dir .. "/" .. filename

          if vim.fn.filereadable(filepath) == 1 then
            vim.notify("denim: note already exists, opening: " .. filename, vim.log.levels.INFO)
            vim.cmd("edit " .. vim.fn.fnameescape(filepath))
            return
          end

          local tmpl_lines = vim.fn.readfile(tmpl_path)
          local body_start = 1
          if tmpl_lines[1] and tmpl_lines[1]:match("^#%s") then
            body_start = (tmpl_lines[2] == "") and 3 or 2
          end
          local lines = { "# " .. uppercase(name), "" }
          for i = body_start, #tmpl_lines do
            table.insert(lines, tmpl_lines[i])
          end

          vim.fn.writefile(lines, filepath)
          vim.cmd("edit " .. vim.fn.fnameescape(filepath))
          vim.schedule(function()
            activate_tab_stops(vim.api.nvim_get_current_buf())
          end)
        end)
      end)
    end)
  end)
end

function M.follow_link()
  local opts     = get_opts()
  local filepath = vim.fn.expand("%:p")
  if not vim.startswith(filepath, opts.notes_dir) then return end
  local line = vim.api.nvim_get_current_line()
  local col  = vim.api.nvim_win_get_cursor(0)[2] + 1
  local path = utils.find_link_path(line, col)
  if path then open_path(path) end
end

function M.new_todo()
  local opts = get_opts()

  vim.ui.input({ prompt = "Todo name: " }, function(name)
    if not name or name == "" then return end
    vim.schedule(function()
      require("denim.telescope").pick_tags(function(tags)
        local date = os.date("%Y%m%dT%H%M%S")
        local slug = slugify_title(name)
        local slugged = vim.tbl_map(slugify_tag, tags)
        table.sort(slugged)
        local tag_suffix = #slugged > 0 and ("__" .. table.concat(slugged, "_")) or ""
        local filename = date .. "-O-" .. slug .. tag_suffix .. ".md"
        local filepath = opts.notes_dir .. "/" .. filename

        if vim.fn.filereadable(filepath) == 1 then
          vim.notify("denim: todo already exists, opening: " .. filename, vim.log.levels.INFO)
          vim.cmd("edit " .. vim.fn.fnameescape(filepath))
          return
        end

        local f = io.open(filepath, "w")
        if f then
          f:write("# " .. uppercase(name) .. "\n\n")
          f:close()
        end
        vim.cmd("edit " .. vim.fn.fnameescape(filepath))
        vim.schedule(function()
          vim.api.nvim_win_set_cursor(0, { 2, 0 })
          vim.cmd("startinsert")
        end)
      end)
    end)
  end)
end

function M.todo_done()
  local opts     = get_opts()
  local filepath = vim.fn.expand("%:p")

  if not vim.startswith(filepath, opts.notes_dir) then
    vim.notify("denim: current file is not in notes directory", vim.log.levels.WARN)
    return
  end

  local filename = vim.fn.fnamemodify(filepath, ":t")

  if not filename:find("-O-", 1, true) then
    vim.notify("denim: current file is not an open todo", vim.log.levels.WARN)
    return
  end

  local new_filename = filename:gsub("%-O%-", "-X-", 1)
  local new_filepath = vim.fn.fnamemodify(filepath, ":h") .. "/" .. new_filename

  vim.fn.rename(filepath, new_filepath)
  vim.cmd("edit " .. vim.fn.fnameescape(new_filepath))
  vim.notify("denim: done — " .. new_filename, vim.log.levels.INFO)
end

function M.refactor()
  local opts     = get_opts()
  local filepath = vim.fn.expand("%:p")
  if filepath == "" then
    vim.notify("denim: no file open", vim.log.levels.WARN)
    return
  end

  if not vim.startswith(filepath, opts.notes_dir) then
    vim.notify("denim: current file is not in notes directory", vim.log.levels.WARN)
    return
  end

  local filename     = vim.fn.fnamemodify(filepath, ":t")
  local current_tags = tags_from_filename(filename)
  local base         = filename:match("^(.-)__[^%.]+%.md$") or filename:match("^(.-)%.md$")

  -- Split base into date+marker prefix and slug
  -- Formats: YYYYMMDD--slug  /  YYYYMMDD-O-slug  /  YYYYMMDD-X-slug
  local date_and_marker = base:match("^(%d+T?%d*%-[OX]%-)") or base:match("^(%d+T?%d*%-%-)")
  local current_slug    = date_and_marker and base:sub(#date_and_marker + 1) or base

  local file_lines  = vim.fn.readfile(filepath, "", 1)
  local current_title = (file_lines[1] and file_lines[1]:match("^#%s+(.+)$")) or current_slug

  vim.ui.input({ prompt = "Note name: ", default = current_title:lower() }, function(name)
    if name == nil then return end

    local new_slug = (name == "" or name == current_title)
      and current_slug
      or slugify_title(name)

    vim.schedule(function()
      require("denim.telescope").pick_tags(function(tags)
        local slugged    = vim.tbl_map(slugify_tag, tags)
        table.sort(slugged)
        local tag_suffix = #slugged > 0 and ("__" .. table.concat(slugged, "_")) or ""
        local new_filename = (date_and_marker or "") .. new_slug .. tag_suffix .. ".md"
        local new_filepath = vim.fn.fnamemodify(filepath, ":h") .. "/" .. new_filename

        if new_filepath == filepath then
          vim.notify("denim: nothing changed", vim.log.levels.INFO)
          return
        end

        local old_buf = vim.api.nvim_get_current_buf()
        vim.fn.rename(filepath, new_filepath)

        local lines = vim.fn.readfile(new_filepath)
        if lines and lines[1] and lines[1]:match("^#%s") then
          lines[1] = "# " .. uppercase(name)
          vim.fn.writefile(lines, new_filepath)
        end

        require("denim.telescope").update_links_to(filepath, new_filepath)
        vim.cmd("edit " .. vim.fn.fnameescape(new_filepath))
        vim.api.nvim_buf_delete(old_buf, { force = true })
        vim.notify("denim: → " .. new_filename, vim.log.levels.INFO)
      end, { pre_selected = current_tags })
    end)
  end)
end

function M.paste_image()
  local ok, img_clip = pcall(require, "img-clip")
  if not ok then
    vim.notify("denim: img-clip.nvim is required for image pasting", vim.log.levels.ERROR)
    return
  end

  local opts = get_opts()

  vim.ui.input({ prompt = "Image name: " }, function(name)
    if not name or name == "" then return end
    vim.schedule(function()
      require("denim.telescope").pick_tags(function(tags)
        local date = os.date("%Y%m%dT%H%M%S")
        local slugged = vim.tbl_map(slugify_tag, tags)
        table.sort(slugged)
        local tag_suffix = #slugged > 0 and ("__" .. table.concat(slugged, "_")) or ""
        local file_name = date .. "--" .. name .. tag_suffix
        local existing = vim.fn.glob(opts.notes_dir .. "/" .. file_name .. ".*")
        if existing ~= "" then
          vim.notify(
            "denim: image already exists: " .. vim.fn.fnamemodify(existing, ":t"),
            vim.log.levels.WARN
          )
          return
        end

        img_clip.paste_image({
          dir_path = opts.notes_dir,
          file_name = file_name,
          prompt_for_file_name = false,
          insert_mode_after_paste = false,
          template = "![$FILE_NAME_NO_EXT]($FILE_PATH)",
        })
      end)
    end)
  end)
end

function M.ensure_notes_dir()
  vim.fn.mkdir(get_opts().notes_dir, "p")
end

return M
