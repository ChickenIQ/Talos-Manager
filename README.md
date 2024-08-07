# Talos Manager (Work In Progress)

A simple, yet powerful, tool to create and manage your Kubernetes clusters using [Talos Linux](https://talos.dev/).

Please note that this project is still in development and is not yet ready for production use. There **WILL** be breaking changes.

This project is designed to be used with bare metal clusters, but it can be used anywhere, as long as you can get the node in maintenace mode and connect to it.

## Requirements

- [Docker](https://www.docker.com/) or [Podman](https://podman.io/)

- Somewhere to deploy Talos

## Features

- Automatic deployment and bootstrap

- On demand rolling upgrades with support for different talos images

- Full cluster reset and re-deployment

- Per node configuration

- Highly customizable

- Cilium CNI integration

- FluxCD integration

- One config file to rule them all

- Config file encryption and automatic decryption

- Support for jinja2 templating in the config file

## Quick Start

1. Download the **_[example config file](https://github.com/ChickenIQ/Talos-Manager/blob/main/example.yaml)_** from this repository.

2. Generate and set the `secrets` variable using the following command:

```bash
docker run --rm -v ./example.yaml:/config.yaml ghcr.io/chickeniq/talos-manager gen-secrets
```

3. Replace the example values with your own and remove what you don't need.

4. Apply your config file:

### Linux

```bash
mkdir ~/.talos ~/.kube
```

```bash
docker run -it --rm \
    -v ~/.kube:/.kube \
    -v ~/.talos:/.talos \
    -v ./example.yaml:/config.yaml \
    ghcr.io/chickeniq/talos-manager apply
```

### Windows (Powershell)

```powershell
mkdir ~\.talos,~\.kube
```

```powershell
docker run -it --rm `
    -v $env:USERPROFILE\.kube:/.kube `
    -v $env:USERPROFILE\.talos:/.talos `
    -v $PWD\example.yaml:/config.yaml `
    ghcr.io/chickeniq/talos-manager apply
```

## Encryption

Talos-Manager supports encryption and decryption of the config file using ansible-vault.

It is highly recommended to encrypt your config file as it contains credentials that can be used to gain full access to your cluster.

#### Encryption:

```bash
docker run --rm -v ./example.yaml:/config.yaml -e VAULT_KEY="vault key" ghcr.io/chickeniq/talos-manager encrypt
```

#### Decryption:

```bash
docker run --rm -v ./example.yaml:/config.yaml -e VAULT_KEY="vault key" ghcr.io/chickeniq/talos-manager decrypt
```

#### Automatic decryption

To use automatic decryption, you have to provide the vault key as an environment variable in your apply command:

```bash
-e VAULT_KEY="vault key"
```
