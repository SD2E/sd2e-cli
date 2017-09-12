
# Overview

Command line interface for the SD2E platform. This repository is mostly intended for developers of the CLI. It's installable via a curl-based installer or available as a Docker container image. Full documentation is available in the [docs/](docs/) folder. 

## Installation

You can use our handy web installer:

```shell
# Run the installer
% curl -L https://raw.githubusercontent.com/sd2e/sd2e-cli/master/install/install.sh | sh
```
# Source your .bashrc
% source ~/.bashrc

# Verify the CLI is installed
% sd2e info

DARPA SD2E version 1.0.1
TACC Cloud API tenant: sd2e
TACC Cloud API versions:
        Science APIs: 2.2.5
        Reactors API: dev
        TACC Accounting API: v1
```

You can also download and install the CLI yourself:


```shell
# Download and unpack into your home directory
% curl -L https://raw.githubusercontent.com/sd2e/sd2e-cli/master/sd2e-cloud-cli.tgz
% tar -xvf sd2e-cloud-cli.tgz -C $HOME

# Add $HOME/sd2e-cloud-cli/bin to your $PATH
% echo "PATH=\$PATH:$HOME/sd2e-cloud-cli/bin" >> ./.bashrc

# Source your .bashrc and verify that the "sd2e" command is available

```

## Using Docker

We maintain the CLI as nicely functional Docker image. 


```shell
# Pull the latest image
% docker pull sd2e/cloud-cli:latest
% docker run -it -v $HOME/.agave:/root/.agave sd2e/cloud-cli bash
```

Some people find it handy to define this as an alias

`alias sd2e-cli='docker run -it -v $HOME/.agave:/root/.agave sd2e/cloud-cli bash'`

```
