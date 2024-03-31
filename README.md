# CircleCI.nvim

A _very_ early stage plugin, and Telescope extension, for visualising CircleCI pipelines, jobs and workflows in neovim. Not really ready to be used yet. This was started during a hack day at TotallyMoney; I have no previous experience writing Lua or neovim plugins, but I use neovim daily. Contributors welcome, lots to be done! Loosely based on/inspired by the CircleCI vscode plugin. Code quality is awful, mostly due to: being written in ~18 hours during a hack day while not knowing Lua or the Neovim API. Please don't judge me!

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
    cmd = "" -- the LSP executable command
    on_attach = function(client, bufnr)
      -- function that gets called when the LSP client attaches
    end
  }
```
The recommended way to install the language server is using [Mason.nvim](https://github.com/williamboman/mason.nvim). Run `:Mason`, search for circleci-yaml-language-server and press I to install. The plugin will look in the mason packages directory for the LSP executable by default. If you want to install it elsewhere (for example on your $PATH), provide the `cmd` option in the `config.lsp` object.

Currently this plugin only officially supports Github as the source control provider for the project on CircleCI. Gitlab and Bitbucket are in the `providerMap` in [`lua/nvim-circleci.lua`](https://github.com/tomoakley/circleci.nvim/blob/main/lua/nvim-circleci.lua), but I am unable to test them. If they don't work, please open an issue, or even better make a pull request with a fix!

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


