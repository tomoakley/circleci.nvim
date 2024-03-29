# CircleCI.nvim

A _very_ early stage plugin, and Telescope extension, for visualising CircleCI pipelines, jobs and workflows in neovim. Not really ready to be used yet. This was started during a hack day at TotallyMoney; I have no previous experience writing Lua or neovim plugins, but I use neovim daily. Contributors welcome, lots to be done! Loosely based on/inspired by the CircleCI vscode plugin. Code quality is awful, mostly due to: being written in ~18 hours during a hack day while not knowing Lua or the Neovim API. Please don't judge me!

## Install
Use the standard installer for your neovim package manager.

## Setup
Ensure you have a CircleCI user token in your macOS keychain (sorry, does not support Linux yet as it uses the macOS `security` CLI):
1. Go to https://app.circleci.com/settings/user/tokens
2. Run this command `security add-generic-password -a $USER -s "circleci" -D "environment variable"  -w <your token>` to add the token to your keychain

Currently this plugin only officially supports Github as the source control provider for the project on CircleCI. Gitlab and Bitbucket are in the `providerMap` in [`lua/nvim-circleci.lua`](https://github.com/tomoakley/circleci.nvim/blob/main/lua/nvim-circleci.lua), but I am unable to test them. If they don't work, please open an issue, or even better make a pull request with a fix!

## Telescope
To activate the Telescope extension add this to your vimrc:
```
require("telescope").load_extension("circleci")
```

### View your pipelines
To show your pipelines in a telescope window and preview their status, run this command:
```
lua require('telescope').extensions.circleci.get_my_pipelines()
```
To show all the projects pipelines from every user, run this command:
```
lua require('telescope').extensions.circleci.get_all_pipelines()
```


