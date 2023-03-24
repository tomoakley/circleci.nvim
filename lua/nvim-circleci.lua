-- main module file
local module = require("nvim-circleci.module")
local config = require("nvim-circleci.config")

local M = {}

-- setup is the public method to setup your plugin
M.setup = function(args)
  -- you can define your setup function here. Usually configurations can be merged, accepting outside params and
  -- you can also put some validation here for those.
  config.config = args
end

M.getMyPipelines = function()
  module.my_first_function()
end

return M
