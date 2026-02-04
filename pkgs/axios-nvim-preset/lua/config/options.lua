-- Core vim options for IDE experience

local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Indentation
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- Display
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false

-- Splits
opt.splitbelow = true
opt.splitright = true

-- Clipboard (system clipboard integration)
opt.clipboard = "unnamedplus"

-- Undo persistence
opt.undofile = true
opt.undolevels = 10000

-- Completion
opt.completeopt = "menu,menuone,noselect"
opt.pumheight = 10

-- Performance
opt.updatetime = 250
opt.timeoutlen = 300

-- File handling
opt.backup = false
opt.swapfile = false
opt.writebackup = false

-- Whitespace characters
opt.list = true
opt.listchars = { tab = "  ", trail = "·", nbsp = "␣" }

-- Fill chars
opt.fillchars = { eob = " " }

-- Mouse
opt.mouse = "a"

-- Command line
opt.cmdheight = 1
opt.showmode = false -- Mode shown in statusline

-- Session
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
