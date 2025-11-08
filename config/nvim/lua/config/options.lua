-- 基本設定 （日本語コメント）
local opt = vim.opt

opt.encoding = "utf-8"
opt.fileencodings = { "utf-8", "iso-2022-jp", "euc-jp", "sjis" }
opt.fileformats = { "unix", "dos" }
opt.termguicolors = true
opt.number = true
opt.relativenumber = false
opt.cursorline = true
opt.signcolumn = "yes"
opt.scrolloff = 5
opt.sidescrolloff = 5
opt.wrap = false
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true
opt.clipboard = "unnamedplus"
opt.splitbelow = true
opt.splitright = true
opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.laststatus = 3
opt.updatetime = 300

vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- 日本語入力状態でも ESC 二連打で戻れるよう短めの timeout
opt.timeoutlen = 400
