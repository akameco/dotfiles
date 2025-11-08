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
map("n", "<leader>.", function()
  vim.cmd.edit(vim.fn.stdpath("config") .. "/init.lua")
end, { desc = "init.lua を開く" })
map("n", "<leader>,", function()
  vim.cmd.source(vim.fn.stdpath("config") .. "/init.lua")
  vim.notify("Neovim 設定を再読み込みしました", vim.log.levels.INFO)
end, { desc = "init.lua を再読み込み" })
map("n", ",d", function()
  local dir = vim.fn.expand("%:p:h")
  if dir ~= "" then
    vim.cmd.lcd(vim.fn.fnameescape(dir))
    vim.notify("lcd " .. dir)
  end
end, { desc = "バッファのディレクトリへ移動" })
map("n", ",fc", "<cmd>%foldclose<CR>", { desc = "すべて折りたたむ" })
map("n", ",fo", "<cmd>%foldopen<CR>", { desc = "すべて展開" })
map("n", "<leader>i", format_buffer, { desc = "全体を整形" })

map("n", "j", "gj", { silent = true })
map("n", "k", "gk", { silent = true })
map("x", "j", "gj", { silent = true })
map("x", "k", "gk", { silent = true })
map("x", "v", "$h", { silent = true })
map("i", "'", "''<Left>")
map("i", '"', '""<Left>')
map("n", "<ESC><ESC>", "<cmd>nohlsearch<CR><Esc>", { silent = true })
map("n", "<leader>w", "<C-w>", { remap = true, desc = "ウィンドウ操作" })
map("n", "G", "Gzz")
map("n", "<C-o>", "<C-o>zz")

map("n", "gc", "<cmd>tablast | tabnew<CR>", { silent = true, desc = "新規タブ" })
map("n", "gl", "<cmd>tabnext<CR>", { silent = true, desc = "次のタブ" })
map("n", "gh", "<cmd>tabprevious<CR>", { silent = true, desc = "前のタブ" })
map("n", "gs", "<cmd>tab split<CR>", { silent = true, desc = "カレントを新規タブ" })

map("n", ",.", function()
  vim.cmd([[%s/\./。/g]])
end, { desc = "句点を全角に" })
map("n", ",,", function()
  vim.cmd([[%s/,/、/g]])
end, { desc = "読点を全角に" })
map("n", ",bl", "<cmd>set background=light<CR>", { desc = "背景: light" })
map("n", ",bd", "<cmd>set background=dark<CR>", { desc = "背景: dark" })

map("n", "<leader>mm", "<cmd>edit ~/Dropbox/Memo/memo.md<CR>", { desc = "メモ" })
map("n", "<leader>md", "<cmd>edit ~/Dropbox/Memo/todo.md<CR>", { desc = "TODO" })
map("n", "<leader>mn", "<cmd>edit ~/Dropbox/Memo/now.md<CR>", { desc = "NOW" })

map("n", ",vf", oil_float(function()
  return vim.fn.expand("%:p:h")
end), { desc = "バッファのディレクトリを Oil で開く" })
map("n", "<leader>e", function()
  vim.cmd.Oil({ args = { "--split", "left" } })
end, { desc = "左ペインに Oil" })

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
