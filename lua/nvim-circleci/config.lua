local M = {}

M.config = {
  project_slug = '',
  mappings = {
    open_in_browser = '<C-o>'
  },
  lsp = {
    enable = false,
    config = {
      exec_path = nil,
      on_attach = nil,
      cmd = nil,
    }
  }
}

M.mergeConfig = function(defaultConfig, userConfig)
  for k, v in pairs(userConfig) do
      if type(v) == "table" then
          if type(defaultConfig[k] or false) == "table" then
              M.mergeConfig(defaultConfig[k], v)
          else
              defaultConfig[k] = v
          end
      else
          defaultConfig[k] = v
      end
  end
  return defaultConfig
end

return M
