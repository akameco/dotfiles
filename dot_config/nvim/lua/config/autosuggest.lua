-- ~/.config/nvim/lua/config/autosuggest.lua
-- Claude Code 履歴 (~/.claude/history.jsonl) やメモから
-- 過去の文章・指示文をインライン薄字サジェストし、Tab キーで確定するモジュール

local M = {}

local ns_id = vim.api.nvim_create_namespace("claude_history_autosuggest")
local current_suggestion = nil -- { text = string, row = number, col = number }
local history_lines = {}
local is_loaded = false
local is_loading = false

-- Claude 履歴およびメモの読み込み (末尾から高速に最新の文章を抽出)
function M.load_history(force)
  if (is_loaded and not force) or is_loading then
    return
  end
  is_loading = true

  vim.schedule(function()
    local seen = {}
    local list = {}

    local function add_entry(text)
      if not text then return end
      text = vim.trim(text)
      -- 3文字以上で特殊記号のみでない文章を採用
      if #text >= 3 and not seen[text] and not text:match("^[%p%s]+$") then
        seen[text] = true
        table.insert(list, text)
      end
    end

    -- 1. ~/.claude/history.jsonl の読み込み
    local history_path = vim.fn.expand("~/.claude/history.jsonl")
    local hf = io.open(history_path, "r")
    if hf then
      local size = hf:seek("end") or 0
      local read_size = math.min(size, 500 * 1024) -- 最新 500KB (約 1,000〜2,000 件)
      hf:seek("set", math.max(0, size - read_size))
      local data = hf:read("*a")
      hf:close()

      if data then
        local claude_entries = {}
        for line in data:gmatch("[^\r\n]+") do
          local display = line:match('"display"%s*:%s*"(.-)"')
          if display then
            display = display:gsub('\\"', '"'):gsub("\\n", " "):gsub("\\\\", "\\")
            -- 複数行の場合は1行目を採用
            local first_line = display:match("^[^\r\n]+") or display
            table.insert(claude_entries, first_line)
          end
        end
        -- 最新順に追加
        for i = #claude_entries, 1, -1 do
          add_entry(claude_entries[i])
        end
      end
    end

    -- 2. ~/Memo/memo.md の読み込み (見出しや箇条書きの文章)
    local memo_path = vim.fn.expand("~/Memo/memo.md")
    local mf = io.open(memo_path, "r")
    if mf then
      for line in mf:lines() do
        -- 見出し記号 (#) やリスト記号 (- ) を除去
        local cleaned = line:gsub("^[#%-%*]%s*", "")
        add_entry(cleaned)
      end
      mf:close()
    end

    history_lines = list
    is_loaded = true
    is_loading = false
  end)
end

-- ゴーストテキストの消去
function M.clear()
  if current_suggestion then
    local bufnr = vim.api.nvim_get_current_buf()
    pcall(vim.api.nvim_buf_clear_namespace, bufnr, ns_id, 0, -1)
    current_suggestion = nil
  end
end

-- サジェストを確定してテキストを返す (expr = true キーマップ用)
function M.accept()
  if current_suggestion then
    local text = current_suggestion.text
    M.clear()
    return text
  end
  return nil
end

-- 挿入モード中のサジェスト更新
function M.update()
  if not is_loaded then
    M.load_history()
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local buftype = vim.bo[bufnr].buftype
  if buftype ~= "" then
    M.clear()
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]
  local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
  local prefix = line:sub(1, col)

  -- インデントを除いた prefix
  local trimmed_prefix = prefix:match("^%s*(.-)$") or ""
  -- 2バイト（日本語1文字、または英字2文字）以上で検索開始
  if #trimmed_prefix < 2 then
    M.clear()
    return
  end

  -- 前方一致で最も最新のマッチを検索
  local match_suffix = nil
  for _, item in ipairs(history_lines) do
    if vim.startswith(item, trimmed_prefix) and #item > #trimmed_prefix then
      match_suffix = item:sub(#trimmed_prefix + 1)
      break
    end
  end

  if not match_suffix then
    M.clear()
    return
  end

  -- 既存の extmark をクリアして新しく描画
  M.clear()
  current_suggestion = { text = match_suffix, row = row, col = col }
  pcall(vim.api.nvim_buf_set_extmark, bufnr, ns_id, row, col, {
    virt_text = { { match_suffix, "Comment" } },
    virt_text_pos = "inline",
    hl_mode = "combine",
  })
end

-- 初期化とイベント登録
function M.setup()
  -- 初回挿入モード突入時に非同期ロード
  local group = vim.api.nvim_create_augroup("ClaudeHistoryAutosuggest", { clear = true })

  vim.api.nvim_create_autocmd("InsertEnter", {
    group = group,
    once = true,
    callback = function()
      M.load_history()
    end,
  })

  vim.api.nvim_create_autocmd("TextChangedI", {
    group = group,
    callback = M.update,
  })

  vim.api.nvim_create_autocmd({ "InsertLeave", "BufLeave" }, {
    group = group,
    callback = M.clear,
  })

  vim.api.nvim_create_autocmd("CursorMovedI", {
    group = group,
    callback = function()
      if current_suggestion then
        local cursor = vim.api.nvim_win_get_cursor(0)
        if cursor[1] - 1 ~= current_suggestion.row or cursor[2] ~= current_suggestion.col then
          M.clear()
        end
      end
    end,
  })

  -- Tab キー: サジェストがあれば確定、無ければ通常の Tab
  vim.keymap.set("i", "<Tab>", function()
    local accepted = M.accept()
    if accepted then
      return accepted
    end
    return "<Tab>"
  end, { expr = true, remap = false, desc = "Accept history suggestion or insert Tab" })

  -- Ctrl + F: サジェスト確定 (Zsh と同じ操作感)
  vim.keymap.set("i", "<C-f>", function()
    local accepted = M.accept()
    if accepted then
      return accepted
    end
    return "<C-f>"
  end, { expr = true, remap = false, desc = "Accept history suggestion or Ctrl-F" })

  -- Ctrl + E: サジェストをキャンセル (文字はそのまま)
  vim.keymap.set("i", "<C-e>", function()
    if current_suggestion then
      M.clear()
      return ""
    end
    return "<C-e>"
  end, { expr = true, remap = false, desc = "Cancel suggestion or Ctrl-E" })
end

return M
