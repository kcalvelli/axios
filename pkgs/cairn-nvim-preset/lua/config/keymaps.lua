-- Core keymaps (plugin-specific keymaps are in their respective plugin files)

local map = vim.keymap.set

-- Better window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- Resize windows with arrows
map("n", "<C-Up>", ":resize -2<CR>", { desc = "Decrease window height", silent = true })
map("n", "<C-Down>", ":resize +2<CR>", { desc = "Increase window height", silent = true })
map("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Decrease window width", silent = true })
map("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Increase window width", silent = true })

-- Buffer navigation
map("n", "<S-h>", ":bprevious<CR>", { desc = "Previous buffer", silent = true })
map("n", "<S-l>", ":bnext<CR>", { desc = "Next buffer", silent = true })
map("n", "<leader>bd", ":bdelete<CR>", { desc = "Delete buffer", silent = true })
map("n", "<leader>bD", ":bdelete!<CR>", { desc = "Force delete buffer", silent = true })

-- Clear search highlight
map("n", "<Esc>", ":nohlsearch<CR>", { desc = "Clear search highlight", silent = true })

-- Better indenting (stay in visual mode)
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })

-- Move lines
map("n", "<A-j>", ":m .+1<CR>==", { desc = "Move line down", silent = true })
map("n", "<A-k>", ":m .-2<CR>==", { desc = "Move line up", silent = true })
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down", silent = true })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up", silent = true })

-- Better paste (don't yank replaced text)
map("v", "p", '"_dP', { desc = "Paste without yanking" })

-- Save file
map("n", "<C-s>", ":w<CR>", { desc = "Save file", silent = true })
map("i", "<C-s>", "<Esc>:w<CR>", { desc = "Save file", silent = true })

-- Quit
map("n", "<leader>qq", ":qa<CR>", { desc = "Quit all", silent = true })

-- New file
map("n", "<leader>fn", ":enew<CR>", { desc = "New file", silent = true })

-- Split windows
map("n", "<leader>ws", ":split<CR>", { desc = "Horizontal split", silent = true })
map("n", "<leader>wv", ":vsplit<CR>", { desc = "Vertical split", silent = true })
map("n", "<leader>wd", ":close<CR>", { desc = "Close window", silent = true })

-- Diagnostic navigation (without LSP plugin loaded)
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line diagnostics" })
