local M = {}
local state = {autocmd = {}}

local augroup = vim.api.nvim_create_augroup('client_cmds', {clear = true})
local autocmd = vim.api.nvim_create_autocmd
local fmt = string.format

M.start = function(userConfig, rootDir)
  local config = M.config(userConfig, rootDir)
  local id = vim.lsp.start_client(config.params)
  if not id then return end

  if vim.v.vim_did_enter == 1 then
    M.buf_attach(config, id)
  end

  state.autocmd[id] = autocmd('BufEnter', {
    pattern = '*',
    group = augroup,
    desc = fmt('Attach LSP: %s', "CircleCI Language Server"),
    callback = function()
      M.buf_attach(config, id)
    end
  })
end

M.config = function(userConfig, rootDir)
  local lspCmd = userConfig.cmd or (vim.fn.stdpath('data') .. '/mason/packages/circleci-yaml-language-server/darwin-arm64-lsp')
  local server_opts = {
    params = {
      name = 'CircleCI config helper',
      cmd = { lspCmd, '-schema='..rootDir..'/.circleci/config.yml', '--stdio'
      },
      capabilities = vim.lsp.protocol.make_client_capabilities(),
      on_attach = function(client, bufnr)
        vim.bo.omnifunc = 'v:lua.vim.lsp.omnifunc'
        local user_on_attach = userConfig.on_attach
        if user_on_attach then
          user_on_attach(client, bufnr)
        end
      end,
      on_init = function(client, results)
        if results.offsetEncoding then
          client.offset_encoding = results.offsetEncoding
        end

        if client.config.settings then
          client.notify('workspace/didChangeConfiguration', {
            settings = client.config.settings
          })
        end
      end,
      on_error = function(code)
        print("circleci lsp error " .. code)
      end,
      root_dir = rootDir,
    }
  }
  server_opts.params.on_exit = M.on_exit

  return server_opts
end

M.buf_attach = function(config, id)
  local supported = {
    ["yaml"] = true,
    ["yml"] = true
  }
  if not supported then return end

  local bufnr = vim.api.nvim_get_current_buf()
  vim.lsp.buf_attach_client(bufnr, id)
end

M.on_exit = function(code, signal, client_id)
  vim.schedule(function()
    vim.api.nvim_del_autocmd(state.autocmd[client_id])
  end)
end

return M
