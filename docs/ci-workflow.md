# Developing an application under CI

This documetation for developing an agave application under CI is in the alpha stage.

## Install latest cli

Backup your current `~/.agave` directory because the next steps may corrupt it.

```
tar -czf $HOME/agave_bak.tar.gz ~/.agave
```

Install the latest CLI from the `CI` branch.

```
curl -L https://github.com/SD2E/sd2e-cli/raw/ci/sd2e-cloud-cli.tgz | tar -xzf -
```

Add `$HOME/sd2e-cloud-cli/bin` to your `$PATH`

```
export PATH=$HOME/sd2e-cloud-cli/bin:${PATH}
```

## Initialize the environment

Initialize the sdk
```
tenants-init
```
Initialize gitlab with TACC credentials
```
tacclab login
```
Initialize docker registry with dockerhub credentials
```
taccreg login
```

These commands save config files to your `~/.agave` directory.

## Initialize an application

```
apps-init
```

## Deploy the application

```
apps-deploy
```
