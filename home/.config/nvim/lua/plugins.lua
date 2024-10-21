-- Neovim-specific Lua configurations

-- Set up which-key plugin
if pcall(require, "which-key") then
  require("which-key").setup {
    -- Your which-key configuration here
  }
end

-- Add more Neovim-specific plugin configurations here
-- For example:
-- if pcall(require, "nvim-treesitter") then
--   require("nvim-treesitter.configs").setup {
--     -- Your treesitter configuration here
--   }
-- end

-- You can add more Lua-based configurations for other Neovim-specific plugins here

-- Setup lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Commented out to disable lazy.nvim
--require("lazy").setup({}, opts)

-- Only required if you have packer configured as `opt`
--vim.cmd [[packadd packer.nvim]]

--return require('packer').startup(function(use)
--  -- Packer can manage itself
--  use 'wbthomason/packer.nvim'

--  use({
--    "jackMort/ChatGPT.nvim",
--      config = function()
--        require("chatgpt").setup()
--      end,
--      requires = {
--        "MunifTanjim/nui.nvim",
--        "nvim-lua/plenary.nvim",
--        "nvim-telescope/telescope.nvim"
--      }
--  })
--end)
