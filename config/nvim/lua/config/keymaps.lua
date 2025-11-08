local map = vim.keymap.set

local function telescope(builtin, opts)
  return function()
    local ok, tb = pcall(require, "telescope.builtin")
    if not ok then
      vim.notify("Telescope が読み込まれていません", vim.log.levels.WARN)
      return
    end
    tb[builtin](opts or {})
  end
end

local function oil_float(dir_fn)
  return function()
    local ok, oil = pcall(require, "oil")
    if not ok then
      vim.notify("oil.nvim が読み込まれていません", vim.log.levels.WARN)
      return
    end
    local dir = type(dir_fn) == "function" and dir_fn() or dir_fn
    oil.open_float(dir)
  end
end

local function format_buffer()
  if vim.lsp and next(vim.lsp.get_active_clients({ bufnr = 0 }) or {}) then
    vim.lsp.buf.format({ async = false })
    return
  end
  vim.cmd([[normal! gg=G]])
end

local function git_root()
  local root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
  if vim.v.shell_error == 0 and root and root ~= "" then
    return root
  end
  return nil
end

map({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

map("n", "j", "gj", { silent = true })
map("n", "k", "gk", { silent = true })
map("x", "j", "gj", { silent = true })
map("x", "k", "gk", { silent = true })
map("x", "v", "$h", { silent = true })
map("n", "<ESC><ESC>", "<cmd>nohlsearch<CR><Esc>", { silent = true })
map("n", "<leader>w", "<C-w>", { remap = true, desc = "ウィンドウ操作" })
map("n", "G", "Gzz")
map("n", "<C-o>", "<C-o>zz")

map("n", "<leader>mm", "<cmd>edit ~/Memo/memo.md<CR>", { desc = "メモ" })

map("n", ",vf", oil_float(function()
  return vim.fn.expand("%:p:h")
end), { desc = "バッファのディレクトリを Oil で開く" })

map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

map("n", "<leader>f", "<Nop>")
map("n", "<leader>fm", telescope("oldfiles", { cwd_only = true }), { desc = "最近使ったファイル" })
map("n", "<leader>fa", telescope("find_files", { follow = true }), { desc = "ファイル検索 (全体)" })
map("n", "<leader>fl", telescope("current_buffer_fuzzy_find"), { desc = "バッファ内検索" })
map("n", "<leader>ff", function()
  local dir = vim.fn.expand("%:p:h")
  if dir == "" then
    telescope("find_files")()
  else
    telescope("find_files", { cwd = dir })()
  end
end, { desc = "バッファと同じディレクトリで検索" })
map("n", "<leader>fp", function()
  local root = git_root()
  if root then
    telescope("find_files", { cwd = root })()
  else
    telescope("find_files")()
  end
end, { desc = "Git ルートで検索" })
map("n", "<leader>fs", telescope("grep_string"), { desc = "単語を grep" })
map("n", "<leader>fg", telescope("live_grep"), { desc = "全文 grep" })
