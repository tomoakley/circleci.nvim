local M = {}

M.config = {
  project_slug = '',
  lsp = {
    enable = false,
    config = {
      exec_path = nil,
      on_attach = nil,
      cmd = nil,
    }
  }
}

return M
