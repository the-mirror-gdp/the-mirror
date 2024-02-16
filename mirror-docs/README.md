This repo uses Docusaurus and autodeploys on Vercel.

# THIS WILL HELP! USE THE PASTE IMAGE VSCODE EXTENSION TO EASILY PASTE SCREENSHOTS AS YOU WRITE DOCS: https://marketplace.visualstudio.com/items?itemName=mushan.vscode-paste-image

---

# Docusaurus Boilerplate

# Website

This website is built using [Docusaurus 2](https://docusaurus.io/), a modern static website generator.

### Installation

```
$ yarn
```

### Local Development

```
$ yarn dev
```

This command starts a local development server and opens up a browser window. Most changes are reflected live without having to restart the server.

### Build

```
$ yarn build
```

This command generates static content into the `build` directory and can be served using any static contents hosting service.

### Deployment

Using SSH:

```
$ USE_SSH=true yarn deploy
```

Not using SSH:

```
$ GIT_USER=<Your GitHub username> yarn deploy
```

If you are using GitHub pages for hosting, this command is a convenient way to build the website and push to the `gh-pages` branch.
