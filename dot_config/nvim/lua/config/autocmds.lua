local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- 保存時に末尾の空白を削除
local trim = augroup("TrimWhitespace", { clear = true })
autocmd("BufWritePre", {
  group = trim,
  pattern = "*",
  callback = function()
    local save = vim.fn.winsaveview()
    vim.cmd([[silent! %s/\s\+$//e]])
    vim.fn.winrestview(save)
  end,
})

-- コピー直後にハイライト
local yank = augroup("HighlightYank", { clear = true })
autocmd("TextYankPost", {
  group = yank,
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})
