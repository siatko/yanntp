local M = {}

local function get_opts()
  return require("denim.config").options
end

local utils = require("denim.utils")
local slugify_title   = utils.slugify_title
local slugify_tag     = utils.slugify_tag
local tags_from_filename = utils.tags_from_filename

function M.new_note()
  local opts = get_opts()

  vim.ui.input({ prompt = "Note name: " }, function(name)
    if not name or name == "" then return end
    vim.schedule(function()
      require("denim.telescope").pick_tags(function(tags)
        local date = os.date("%Y%m%d")
        local slug = slugify_title(name)
        local slugged = vim.tbl_map(slugify_tag, tags)
        local tag_suffix = #slugged > 0 and ("__" .. table.concat(slugged, "_")) or ""
        local filename = date .. "--" .. slug .. tag_suffix .. ".md"
        local filepath = opts.notes_dir .. "/" .. filename

        if vim.fn.filereadable(filepath) == 1 then
          vim.notify("denim: note already exists, opening: " .. filename, vim.log.levels.INFO)
          vim.cmd("edit " .. vim.fn.fnameescape(filepath))
          return
        end

        vim.cmd("edit " .. vim.fn.fnameescape(filepath))
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "# " .. name, "" })
        vim.cmd("write")
        vim.api.nvim_win_set_cursor(0, { 2, 0 })
        vim.cmd("startinsert")
      end)
    end)
  end)
end

function M.follow_link()
  local line = vim.api.nvim_get_current_line()
  local col  = vim.api.nvim_win_get_cursor(0)[2] + 1

  local pos = 1
  while pos <= #line do
    local ms, me, path = line:find("%[.-%]%((.-)%)", pos)
    if not ms then break end

    if col >= ms and col <= me then
      local current_dir = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":h")
      local target = vim.fn.fnamemodify(current_dir .. "/" .. path, ":p")
      if vim.fn.filereadable(target) == 1 then
        vim.cmd("edit " .. vim.fn.fnameescape(target))
      else
        vim.notify("denim: file not found: " .. target, vim.log.levels.WARN)
      end
      return
    end
    pos = me + 1
  end
end

function M.new_todo()
  local opts = get_opts()

  vim.ui.input({ prompt = "Todo name: " }, function(name)
    if not name or name == "" then return end
    vim.schedule(function()
      require("denim.telescope").pick_tags(function(tags)
        local date = os.date("%Y%m%d")
        local slug = slugify_title(name)
        local slugged = vim.tbl_map(slugify_tag, tags)
        local tag_suffix = #slugged > 0 and ("__" .. table.concat(slugged, "_")) or ""
        local filename = date .. "-O-" .. slug .. tag_suffix .. ".md"
        local filepath = opts.notes_dir .. "/" .. filename

        if vim.fn.filereadable(filepath) == 1 then
          vim.notify("denim: todo already exists, opening: " .. filename, vim.log.levels.INFO)
          vim.cmd("edit " .. vim.fn.fnameescape(filepath))
          return
        end

        vim.cmd("edit " .. vim.fn.fnameescape(filepath))
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "# " .. name, "" })
        vim.cmd("write")
        vim.api.nvim_win_set_cursor(0, { 2, 0 })
        vim.cmd("startinsert")
      end)
    end)
  end)
end

function M.todo_done()
  local filepath = vim.fn.expand("%:p")
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

function M.retag()
  local filepath = vim.fn.expand("%:p")
  if filepath == "" then
    vim.notify("denim: no file open", vim.log.levels.WARN)
    return
  end

  local filename     = vim.fn.fnamemodify(filepath, ":t")
  local current_tags = tags_from_filename(filename)
  local title        = #current_tags > 0
    and "Retag  (current: " .. table.concat(current_tags, ", ") .. ")"
    or  "Retag  (no current tags)"

  require("denim.telescope").pick_tags(function(tags)
    local slugged    = vim.tbl_map(slugify_tag, tags)
    local tag_suffix = #slugged > 0 and ("__" .. table.concat(slugged, "_")) or ""
    local base       = filename:match("^(.-)__[^%.]+%.md$") or filename:match("^(.-)%.md$")
    local new_filename = base .. tag_suffix .. ".md"
    local new_filepath = vim.fn.fnamemodify(filepath, ":h") .. "/" .. new_filename

    if new_filepath == filepath then
      vim.notify("denim: tags unchanged", vim.log.levels.INFO)
      return
    end

    vim.fn.rename(filepath, new_filepath)
    require("denim.telescope").update_links_to(filepath, new_filepath)
    vim.cmd("edit " .. vim.fn.fnameescape(new_filepath))
    vim.notify("denim: → " .. new_filename, vim.log.levels.INFO)
  end, { title = title })
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
      local date = os.date("%Y%m%d")
      local file_name = date .. "--" .. name
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
end

function M.ensure_notes_dir()
  vim.fn.mkdir(get_opts().notes_dir, "p")
end

return M
