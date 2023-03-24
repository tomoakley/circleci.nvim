# CircleCI.nvim

A _very_ early stage plugin for visualising CircleCI pipelines, jobs and workflows in neovim. Not really ready to be used yet. This was started during a hack day at TotallyMoney; I have no previous experience writing Lua or neovim plugins, but I use neovim daily. Contributors welcome, lots to be done! Loosely based on/inspired by the CircleCI vscode plugin. Code quality is awful, mostly due to: being written in ~18 hours during a hack day while not knowing Lua or the Neovim API. Please don't judge me!

## Install
Use the standard installer for your neovim package manager.

## Setup
Ensure you have a CircleCI user token in your macOS keychain (sorry, does not support Linux yet as it uses the macOS `security` CLI):
1. Go to https://app.circleci.com/settings/user/tokens
2. Run this command `security add-generic-password -a $USER -s "circleci" -D "environment variable"  -w <your token>` to add the token to your keychain

In vimrc/init.lua add:
```
require('nvim-circleci').setup{
  project_slug = '<your project slug>'
}
```

where `project_slug` comes from Circle in the format `vcs-slug/org-name/repo-name`. For example, `gh/facebook/react'.

## Commands
`:CCMyPipelines` - show your pipelines in a popup buffer. Press Enter on a pipeline to show the workflow and jobs. Press `O` to open the workflow in the browser (currently opens the wrong job - but in the correct workflow)

