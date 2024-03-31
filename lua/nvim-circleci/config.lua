local M = {}

M.config = {
  project_slug = '',
  lsp = {
    enable = false,
    config = {
      on_attach = nil,
      cmd = nil
    }
  }
}

return M
