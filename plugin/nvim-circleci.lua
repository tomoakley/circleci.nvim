vim.api.nvim_create_user_command("CCMyPipelines", require("nvim-circleci").getMyPipelines, {})
