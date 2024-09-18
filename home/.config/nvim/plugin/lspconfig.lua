-- Setup language servers.
local lspconfig = require('lspconfig')
lspconfig.pyright.setup {}
lspconfig.ts_ls.setup {}
lspconfig.rust_analyzer.setup {
  -- Server-specific settings. See `:help lspconfig-setup`
  settings = {
    ['rust-analyzer'] = {},
  },
}


-- Global mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)


-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    -- Enable completion triggered by <c-x><c-o>
    vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

    -- Buffer local mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local opts =
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { buffer = ev.buf, desc = 'Go to declaration' })
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = ev.buf, desc = 'Go to definition' })
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = ev.buf, desc = 'Show hover' })
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, { buffer = ev.buf, desc = 'Go to implementation' })
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, { buffer = ev.buf, desc = 'Show signature help' })
    --vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
    --vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
    --vim.keymap.set('n', '<space>wl', function()
    --  print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    --end, opts)
    vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, { buffer = ev.buf, desc = 'Go to type definition' })
    vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, { buffer = ev.buf, desc = 'Rename' })
    vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, { buffer = ev.buf, desc = 'Code action' })
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, { buffer = ev.buf, desc = 'Go to references' })
    vim.keymap.set('n', '<space>f', function()
      vim.lsp.buf.format { async = true }
    end, { buffer = ev.buf, desc = 'Format' })
  end,
})
