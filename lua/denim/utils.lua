local M = {}

local function lower_utf8(s)
  -- Lua's string.lower() is ASCII-only; map common uppercase non-ASCII chars
  s = s:gsub("Ä", "ä"):gsub("Ö", "ö"):gsub("Ü", "ü"):gsub("ẞ", "ß")
  return s:lower()
end

function M.slugify_title(name)
  local s = lower_utf8(name)
  s = s:gsub("[%s]+", "-")
  -- %c and %p only match ASCII, so UTF-8 high bytes are preserved
  s = s:gsub("[%c%p]", function(c) if c == "-" then return c end return "" end)
  s = s:gsub("%-+", "-")
  s = s:gsub("^%-", ""):gsub("%-$", "")
  return s
end

function M.slugify_tag(tag)
  local s = lower_utf8(tag)
  s = s:gsub("[%s%-]+", "_")
  s = s:gsub("[%c%p]", function(c) if c == "_" then return c end return "" end)
  s = s:gsub("_+", "_")
  s = s:gsub("^_", ""):gsub("_$", "")
  return s
end

function M.tags_from_filename(filename)
  local tag_part = filename:match("__([^%.]+)%.md$")
  if not tag_part then return {} end
  local tags = {}
  for tag in tag_part:gmatch("[^_]+") do
    if tag ~= "" then table.insert(tags, tag) end
  end
  return tags
end

function M.relative_path(from_dir, to_file)
  local function split(path)
    local t = {}
    for s in path:gmatch("[^/]+") do t[#t+1] = s end
    return t
  end
  local src, dst = split(from_dir), split(to_file)
  local i = 1
  while i <= #src and i <= #dst and src[i] == dst[i] do i = i + 1 end
  local parts = {}
  for _ = i, #src do parts[#parts+1] = ".." end
  for j = i, #dst do parts[#parts+1] = dst[j] end
  return #parts > 0 and table.concat(parts, "/") or "."
end

function M.rename_tag_in_filename(filename, old_tag, new_tag)
  local base     = filename:match("^(.-)__[^%.]+%.md$")
  local tag_part = filename:match("__([^%.]+)%.md$")
  if not tag_part then return filename, false end

  local tags, seen = {}, {}
  local found = false
  for tag in tag_part:gmatch("[^_]+") do
    local t = (tag == old_tag) and new_tag or tag
    found = found or (tag == old_tag)
    if t ~= "" and not seen[t] then
      seen[t] = true
      table.insert(tags, t)
    end
  end

  if not found then return filename, false end
  table.sort(tags)
  local suffix = #tags > 0 and ("__" .. table.concat(tags, "_")) or ""
  return base .. suffix .. ".md", true
end

function M.add_tag_to_filename(filename, tag)
  local base = filename:match("^(.-)__[^%.]+%.md$") or filename:match("^(.-)%.md$")
  if not base then return filename, false end
  local existing = M.tags_from_filename(filename)
  for _, t in ipairs(existing) do
    if t == tag then return filename, false end
  end
  table.insert(existing, tag)
  table.sort(existing)
  return base .. "__" .. table.concat(existing, "_") .. ".md", true
end

function M.resolve_slug(name, current_title, current_slug)
  if name == "" or name:lower() == current_title:lower() then
    return current_slug
  end
  return M.slugify_title(name)
end

function M.multiterm_match(prompt, line)
  if prompt == "" then return true end
  for _, term in ipairs(vim.split(prompt, "%s+", { trimempty = true })) do
    if not line:find(term, 1, true) then return false end
  end
  return true
end

function M.find_link_path(line, col)
  local nearest_path, nearest_dist = nil, math.huge
  local pos = 1
  while pos <= #line do
    local ms, me, path = line:find("%[.-%]%((.-)%)", pos)
    if not ms then break end

    if col >= ms and col <= me then
      return path
    end
    local dist = math.min(math.abs(col - ms), math.abs(col - me))
    if dist < nearest_dist then
      nearest_dist = dist
      nearest_path = path
    end
    pos = me + 1
  end
  return nearest_path
end

return M
