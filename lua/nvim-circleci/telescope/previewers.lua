local previewers = require("telescope.previewers")

local M = {}

M.workflow = function(opts)
  return previewers.new_buffer_previewer{
    title = 'workflow preview'
  }
end

return M
