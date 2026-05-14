local M = {}

function M.slugify_title(name)
  local s = name:lower()
  s = s:gsub("[%s]+", "-")
  s = s:gsub("[^%w%-]", "")
  s = s:gsub("%-+", "-")
  s = s:gsub("^%-", ""):gsub("%-$", "")
  return s
end

function M.slugify_tag(tag)
  local s = tag:lower()
  s = s:gsub("[%s%-]+", "_")
  s = s:gsub("[^%w_]", "")
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

return M
