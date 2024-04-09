local api = {}
local curl = require "plenary.curl"
local config = require"nvim-circleci.config"

function api.get_circle_token()
  if api.token then return api.token end
  local result = vim.fn.system('security find-generic-password -w -a ${USER} -D "environment variable" -s "circleci"')
  return string.gsub(result, '\n', '')
end

api.token = api.get_circle_token()

local function makeRequest(method, url)
  local headers = {
    ['content-type'] = "application/json",
    ['Circle-Token'] = api.token
  }
  local opts = {
    url = string.format('https://circleci.com/api/v2/%s', url),
    headers = headers
  }

  local res = curl.get(opts)
  return res.body
end

function api.getMyPipelineIds()
  local pipelineIds = {}
  local response = makeRequest("GET", string.format("project/%s/pipeline/mine", config.config['project_slug']))
  local data = vim.json.decode(response)
  for k,v in pairs(data) do
    if (k == "items") then
      for _, item in ipairs(v) do
        pipelineIds[#pipelineIds + 1] = {branch = item.vcs.branch, id = item.id, number = item.number, updated_at = item.updated_at, state = item.state}
      end
    end
  end
  return pipelineIds
end

function api.getAllPipelineIds()
  local pipelineIds = {}
  local response = makeRequest("GET", string.format("project/%s/pipeline", config.config['project_slug']))
  local data = vim.json.decode(response)
  for k,v in pairs(data) do
    if (k == "items") then
      for _, item in ipairs(v) do
        pipelineIds[#pipelineIds + 1] = {branch = item.vcs.branch, id = item.id, number = item.number, updated_at = item.updated_at, state = item.state, user = item.trigger.actor.login}
      end
    end
  end
  return pipelineIds
end

function api.getWorkflowById(id)
  local response = makeRequest("GET", string.format("pipeline/%s/workflow", id))
  local data = vim.json.decode(response)
  local workflowData = {}
  for k,v in pairs(data) do
    if (k == "items") then
      for _, item in ipairs(v) do
        workflowData[#workflowData+1] = {id = item.id, status = item.status, name = item.name, created_at = item.created_at, number = item.pipeline_number}
      end
    end
  end
  return workflowData
end

function api.getWorkflowJobs(id)
  local response = makeRequest("GET", string.format("workflow/%s/job", id))
  local data = vim.json.decode(response)
  local items = {}
  for k,v in pairs(data) do
    if (k == "items") then
      items = v
    end
  end
  return items
end

function api.getWorkflowForBranch(sender, branch)
  local pipelines = api.getAllPipelineIds()
  -- local branchWorkflows = {}
  for key,item in pairs(pipelines) do
    if (item.branch == branch) then
      local workflow = api.getWorkflowById(item.id)
      -- branchWorkflows[#branchWorkflows+1] = workflow
      sender(workflow)
    end
  end
end

function api.openJobUrl(number)
  local response = makeRequest("GET", string.format("project/%s/job/%s", config.config['project_slug'], number))
  local data = vim.json.decode(response)
  for k,v in pairs(data) do
    if (k == "web_url") then
      vim.cmd('silent exec "!open \'' .. v .. '\'"')
    end
  end
end

function api.run(request, params, cb)
  cb(request(params))
end


return api
