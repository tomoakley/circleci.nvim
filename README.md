# CircleCI.nvim

A _very_ early stage plugin and Telescope extension, for visualising CircleCI pipelines, jobs and workflows in neovim. Not really ready to be used yet - but it does work. The code is likely to change a lot with breaking changes common.

This was started during a hack day at TotallyMoney in 2023; I have no previous experience writing Lua or neovim plugins, but I use neovim daily. Contributors welcome, lots to be done! Loosely based on/inspired by the CircleCI vscode plugin. Code quality is awful, mostly due to: being written in ~18 hours during a hack day while not knowing Lua or the Neovim API. Please don't judge me! I have since continued working on it.

## Install
Use the standard installer for your neovim package manager.

## Setup
Ensure you have a CircleCI user token in your macOS keychain (sorry, does not support Linux yet as it uses the macOS `security` CLI):
1. Go to https://app.circleci.com/settings/user/tokens
2. Run this command `security add-generic-password -a $USER -s "circleci" -D "environment variable"  -w <your token>` to add the token to your keychain

In your neovim config file, add:
```
circleci.setup()
```

### LSP
To enable the [CircleCI YAML Language Server](https://github.com/CircleCI-Public/circleci-yaml-language-server), add some config to the setup call:
```
circleci.setup{
  lsp = {
    enable = true
  }
}

```
There are further config options available for the LSP:
```
  lsp = {
    enable = true,
    config = {
      exec_path = "",
      cmd = {}, -- the LSP executable command in list form
      on_attach = function(client, bufnr), -- function that gets called when the LSP client attaches
      enable_yaml = true
    }
  }
```
The recommended way to install the language server is using [Mason.nvim](https://github.com/williamboman/mason.nvim). Run `:Mason`, search for circleci-yaml-language-server and press I to install. The plugin will look in the mason packages directory for the LSP executable by default.
If you want to install it elsewhere (for example on your $PATH), there are two options: either provide the `cmd` option in the `config.lsp` object, in the form of a list of strings with the required flags. You can also provide the `exec_path` - provide the path to the directory where the executable lives and the plugin will add the required flags.

The CircleCI Language Server also supports contextual documentation for Circle concepts like executors, orbs, pipelines, workflows and more. This functionality requires the [Yaml Language Server](https://github.com/redhat-developer/yaml-language-server). This plugin supports this functionality but it's optional to enable - use the `lsp.config.enable_yaml = true` attribute to enable it. Then install the Yaml Language Server - `yarn global add yaml-language-server`. When in your circleci/config.yml file, you should be able to use `lua vim.lsp.buf.hover()` function to show the documentation.
Alternatively you can do this yourself in your own config using [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#yamlls). To add the CircleCI yaml schema, add this to the schemas object:
```
["https://json.schemastore.org/circleciconfig.json"] = "/.circleci/config.yml"
```

Currently this plugin only officially supports Github as the source control provider for the project on CircleCI. Gitlab and Bitbucket are in the `providerMap` in [`lua/nvim-circleci.lua`](https://github.com/tomoakley/circleci.nvim/blob/main/lua/nvim-circleci.lua), but I am unable to test them. If they don't work, please open an issue, or even better make a pull request with a fix!

If you self-host your own CircleCI infrastructure, you can pass the config variable `selfHostedUrl` to set that.

## Telescope
The Telescope extension is only activated by the plugin if the project root has a `.circleci` directory.

### View your pipelines
To show your pipelines in a telescope window and preview their status, run this command:
```
lua require('telescope').extensions.circleci.get_my_pipelines()
```
To show all the projects pipelines from every user, run this command:
```
lua require('telescope').extensions.circleci.get_all_pipelines()
```

To open a pipeline or workflow in a browser, use `<C-o>` while in the picker. To modify this mapping, pass in this config to the `circleci.setup()` method:
```
{
  "mappings" = {
    "open_in_browser" = "<C-a>" -- pass new mapping here
  }
}
```
