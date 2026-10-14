local M = {}

local cached_items = nil
local last_loaded_mtime = 0

local function get_history_file()
  local home = vim.env.HOME or os.getenv("HOME")
  return home .. "/.claude/history.jsonl"
end

local function clean_text(text)
  if not text then return nil end
  local t = vim.trim(text)
  if #t < 3 then return nil end
  return t
end

local function load_items()
  local path = get_history_file()
  local stat = vim.loop.fs_stat(path)
  if not stat then
    cached_items = {}
    return cached_items
  end

  if cached_items and stat.mtime.sec == last_loaded_mtime then
    return cached_items
  end

  last_loaded_mtime = stat.mtime.sec
  local file = io.open(path, "r")
  if not file then
    cached_items = {}
    return cached_items
  end

  local raw_lines = {}
  for line in file:lines() do
    if #line > 0 then
      table.insert(raw_lines, line)
    end
  end
  file:close()

  local seen = {}
  local items = {}
  local kind_text = 1 -- CompletionItemKind.Text (LSP 3.17)

  local count = 0
  local max_items = 2000

  for i = #raw_lines, 1, -1 do
    local ok, json = pcall(vim.json.decode, raw_lines[i])
    if ok and json and type(json) == "table" then
      local text = json.display or json.content
      if type(text) == "string" then
        for _, sub in ipairs(vim.split(text, "\n", { trimempty = true })) do
          local cleaned = clean_text(sub)
          if cleaned and not seen[cleaned] then
            seen[cleaned] = true
            count = count + 1
            table.insert(items, {
              label = cleaned,
              kind = kind_text,
              detail = "Claude",
              documentation = {
                kind = "markdown",
                value = "```\n" .. cleaned .. "\n```",
              },
              sortText = string.format("%06d", count),
            })
            if count >= max_items then
              break
            end
          end
        end
      end
    end
    if count >= max_items then
      break
    end
  end

  cached_items = items
  return cached_items
end

function M.new(opts)
  local self = setmetatable({}, { __index = M })
  self.opts = opts or {}
  return self
end

function M:get_completions(ctx, callback)
  local items = load_items()
  callback({
    is_incomplete_forward = false,
    is_incomplete_backward = false,
    items = vim.deepcopy(items),
  })
  return function() end
end

return M
