local M = {}
local state = {autocmd = {}}

local augroup = vim.api.nvim_create_augroup('client_cmds', {clear = true})
local autocmd = vim.api.nvim_create_autocmd
local fmt = string.format


local function getCircleCILanguageServerConfig(userConfig)
  local packagePath = userConfig.exec_path or (vim.fn.stdpath('data') .. '/mason/packages/circleci-yaml-language-server')
  local defaultCmd = {packagePath .. '/darwin-arm64-lsp', '-schema='..packagePath..'/schema.json', '--stdio'}
  return {
    cmd = { unpack(userConfig.cmd or defaultCmd) },
    on_attach = function(client, bufnr)
      vim.bo.omnifunc = 'v:lua.vim.lsp.omnifunc'
      local user_on_attach = userConfig.on_attach
      if user_on_attach then
        user_on_attach(client, bufnr)
      end
    end,
  }
end

local function getYamlLanguageServerConfig(userConfig)
  return {
    cmd = {"yaml-language-server", "--stdio"},
    on_attach = function(client, bufnr)
      local user_on_attach = userConfig.on_attach
      if user_on_attach then
        user_on_attach(client, bufnr)
      end
    end,
    settings = {
      yaml = {
        schemas = {
          ["https://json.schemastore.org/circleciconfig.json"] = {"/.circleci/config.yml", "/.circleci/config.yaml"}
        },
      }
    },
    filetypes = {'yaml', 'yml'}
  }
end


local getConfigMethodForLS = {
  ["CircleCI Language Server"] = getCircleCILanguageServerConfig,
  ["Yaml Language Server"] = getYamlLanguageServerConfig
}

M.start = function(lsName, userConfig, rootDir)
  local config = M.config(lsName, userConfig, rootDir)
  local id = vim.lsp.start_client(config)
  if not id then return end

  if vim.v.vim_did_enter == 1 then
    M.buf_attach(config, id)
  end

  state.autocmd[id] = autocmd('BufEnter', {
    pattern = {'*.yaml', '*.yml'},
    group = augroup,
    desc = fmt('Attach LSP: %s', lsName),
    callback = function()
      M.buf_attach(config, id)
    end
  })
end

M.config = function(lsName, userConfig, rootDir)
  local server_opts = getConfigMethodForLS[lsName](userConfig)
  server_opts.name = lsName
  server_opts.root_dir = rootDir
  server_opts.on_exit = M.on_exit
  server_opts.on_init = M.on_init
  server_opts.capabilities = vim.lsp.protocol.make_client_capabilities()

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

M.on_init = function(client, results)
  if results.offsetEncoding then
    client.offset_encoding = results.offsetEncoding
  end

  if client.config.settings then
    client.notify('workspace/didChangeConfiguration', {
      settings = client.config.settings
    })
  end
end

M.on_exit = function(code, signal, client_id)
  vim.schedule(function()
    vim.api.nvim_del_autocmd(state.autocmd[client_id])
  end)
end

return M
