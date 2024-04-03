-- main module file
local module = require("nvim-circleci.module")
local config = require("nvim-circleci.config")

local M = {}

local providerMap = {
    ["git@github.com"] = "gh",
    -- Untested
    ["git@gitlab.com"] = "gl",
    ["git@bitbucket.org"] = "bb",
}

local function getTopLevelOfRepo()
  local handle = io.popen("git rev-parse --show-toplevel")
  local repoRoot = handle:read("*a")
  handle:close()
  repoRoot = string.gsub(repoRoot, "\n", "")
  return repoRoot
end

local function checkForCircleCIConfig(root)
  local circleDirectory = ".circleci"
  local file = io.open(circleDirectory, "r")
  return file ~= nil and io.close(file)
end

local function getRemoteOriginUrl(repoRoot)
  local configFilePath = repoRoot .. "/.git/config"
  local file = io.open(configFilePath, "r")
  if not file then
    local parentPath = string.match(repoRoot, "(.*/)")
    local parentConfigPath = parentPath .. "config"
    file = io.open(parentConfigPath) -- git worktrees setup
    if not file then
      return nil
    end
  end

  local url = nil
  for line in file:lines() do
    if string.match(line, "^%s*url%s*=") then
        url = string.match(line, "= (.*)")
        break
    end
  end

  file:close()
  return url
end

local function formatRemoteOriginToProjectSlug(remoteOrigin)
  local firstPart = string.match(remoteOrigin, "^[^:]*")

  local providerPrefix = providerMap[firstPart]
  if providerPrefix then
    local formatted = string.gsub(remoteOrigin, firstPart, providerPrefix)
    formatted = string.gsub(formatted, "%.git$", "")
    formatted = string.gsub(formatted, ":", "/")
    return formatted
  else
    return remoteOrigin
  end
end

-- setup is the public method to setup your plugin
M.setup = function(args)
  -- you can define your setup function here. Usually configurations can be merged, accepting outside params and
  -- you can also put some validation here for those.

  config.config = args
  -- Usage
  local repoRoot = getTopLevelOfRepo()
  if checkForCircleCIConfig(repoRoot) then
    local remoteOriginUrl = getRemoteOriginUrl(repoRoot)
    if remoteOriginUrl then
      local projectSlug = formatRemoteOriginToProjectSlug(remoteOriginUrl)
      if projectSlug then
        require("telescope").load_extension("circleci")
        config.config.project_slug = projectSlug
      end
    else
      print("Error opening git config file")
    end

    local lspConfig = args.lsp or { enable = false }
    if lspConfig.enable then
      require("nvim-circleci.lsp").start(lspConfig.config, repoRoot)
    end
  end
end

--[[ M.getMyPipelines = function()
  module.my_first_function()
end ]]

return M
