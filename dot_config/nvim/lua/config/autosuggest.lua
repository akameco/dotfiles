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

-- Markdown 記号 (- , * , # , 1. , > 等) や先頭空白を除去
local function clean_prefix(line_prefix)
  local cleaned = line_prefix:gsub("^%s*[%-%*#>]%s*", "")
  cleaned = cleaned:gsub("^%s*%d+%.%s*", "")
  return vim.trim(cleaned)
end

-- 入力行からマッチ判定に使うフレーズ候補を抽出 (文単位、読点単位、単語単位)
local function get_clauses(text)
  local clauses = {}
  if #text >= 2 then
    table.insert(clauses, text)
  end

  -- 日本語の句点「。」で分割した最後の文
  local dot_parts = vim.split(text, "。")
  local last_dot = dot_parts[#dot_parts]
  if last_dot and #last_dot >= 2 and last_dot ~= text then
    table.insert(clauses, vim.trim(last_dot))
  end

  -- 日本語の読点「、」で分割した最後の節
  local comma_parts = vim.split(text, "、")
  local last_comma = comma_parts[#comma_parts]
  if last_comma and #last_comma >= 2 and last_comma ~= text and last_comma ~= last_dot then
    table.insert(clauses, vim.trim(last_comma))
  end

  -- 全角スペース「　」で分割した最後の節
  local zen_parts = vim.split(text, "　")
  local last_zen = zen_parts[#zen_parts]
  if last_zen and #last_zen >= 2 and last_zen ~= text and last_zen ~= last_dot and last_zen ~= last_comma then
    table.insert(clauses, vim.trim(last_zen))
  end

  -- 半角スペース、コロン等 (ASCII) で区切った最後の単語
  local last_word = text:match("[^%s:;]+$")
  if last_word and #last_word >= 2 and last_word ~= text and last_word ~= last_dot and last_word ~= last_comma and last_word ~= last_zen then
    table.insert(clauses, vim.trim(last_word))
  end

  return clauses
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

  local cleaned = clean_prefix(prefix)
  local clauses = get_clauses(cleaned)
  if #clauses == 0 then
    M.clear()
    return
  end

  -- 1. 前方一致（クエリで始まる履歴）を優先して検索
  local match_suffix = nil
  for _, query in ipairs(clauses) do
    if #query >= 2 then
      for _, item in ipairs(history_lines) do
        if vim.startswith(item, query) and #item > #query then
          match_suffix = item:sub(#query + 1)
          break
        end
      end
      if match_suffix then
        break
      end
    end
  end

  -- 2. 前方一致がない場合、ある程度の長さ（6バイト以上＝日本語2文字/英字6文字）があれば部分一致を検索
  if not match_suffix then
    for _, query in ipairs(clauses) do
      if #query >= 6 then
        for _, item in ipairs(history_lines) do
          local s, e = item:find(query, 1, true)
          if s and #item > e then
            match_suffix = item:sub(e + 1)
            break
          end
        end
        if match_suffix then
          break
        end
      end
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
