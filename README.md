<p align="center"><img src="https://user-images.githubusercontent.com/39482679/201857002-00673709-053f-428d-b7ea-8bbbe010bc42.gif" alt="transfer-org-repos"></p>

# Transfer organization repositories

An interactive tool that you can use directly from your browser to transfer or move Github organization repositories in bulk.

# Quickstart

- Open this on Gitpod 👇

[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#github.com/Gitpod-Samples/tool-transfer-org-repos)
  - Login with GitHub if needed.

## Prerequisites

- Make sure you have Admin permissions on source organization, otherwise it may fail for repositories that you didn't create. On the target organization you will need only repository creation permission.

- Make sure you have granted **Organization access** to Gitpod for your source and target organization. You can check that from here:
  - https://github.com/settings/connections/applications/484069277e293e6d2a2a (scroll to the bottom)

- Make sure _all_ permissions are granted in:
  - https://gitpod.io/integrations > **GitHub** > **Edit Permissions**

- Finally, proceed with the instructions in the terminal prompt on Gitpod.

# How does it work

It uses GitHub API to transfer the repositories. Different API calls are made in 6 places [[1](./src/main#L36), [2](./src/main#L36), [3](./src/main.sh#L48), [4](./src/main.sh#L63), [5](./src/main.sh#L78), [6](./src/main.sh#L131)] for things like:

- Logging into GitHub if needed.

- Checking whether you have needed permissions on source and target organization.

- Retrieving the full list of repositories on your source organization.

- Issuing repository transfer.

# Built with

It is built with the following tools:

- [bashbox](https://github.com/bashbox/bashbox)
- [fzf](https://github.com/junegunn/fzf)
- [gh](https://github.com/cli/cli)
- [gum](https://github.com/charmbracelet/gum)

