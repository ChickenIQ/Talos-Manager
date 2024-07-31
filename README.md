# Talos Manager (Work In Progress)

A simple, yet powerful, tool to create and manage your Kubernetes clusters using [Talos Linux](https://talos.dev/).

Please note that this project is still in development and is not yet ready for production use. There **WILL** be breaking changes.

## Requirements

- [Docker](https://www.docker.com/) or [Podman](https://podman.io/)

- Somewhere to deploy [Talos](https://www.talos.dev/latest/talos-guides/install/)

## Features

- Automatic deployment and bootstrap

- On demand rolling upgrades with support for different talos images

- Full cluster reset and re-deployment

- Per node configuration

- Highly customizable

- Cilium CNI integration

- FluxCD integration

- Support for jinja2 templating in config

- One config file to rule them all

- Config file encryption and automatic decryption

## Quick Start

1. Download the **_[example config file](https://github.com/ChickenIQ/Talos-Manager/blob/main/example.yaml)_** from this repository.

2. Generate your `secrets` string using the following command:

```bash
docker run ghcr.io/chickeniq/talos-manager gen-secrets
```

3. Copy the output of the previous command and paste it in the `secrets` field of the config file.

4. Replace the example values with your own and remove what you don't need.

5. Apply your config file:

### Linux

```bash
mkdir ~/.talos ~/.kube
```

```bash
docker run -it --rm \
    -v ~/.talos:/host/.talos \
    -v ~/.kube:/host/.kube \
    -v ./config.yaml:/host/config.yaml \
    ghcr.io/chickeniq/talos-manager apply
```

### Windows (Powershell)

```powershell
mkdir ~\.talos,~\.kube
```

```powershell
docker run -it --rm `
    -v $env:USERPROFILE\.talos:/host/.talos `
    -v $env:USERPROFILE\.kube:/host/.kube `
    -v $PWD\config.yaml:/host/config.yaml `
    ghcr.io/chickeniq/talos-manager apply
```

## Encryption

Talos-Manager supports encryption and decryption of the config file using ansible-vault. It is highly recommended to encrypt your config file as it will contain important secrets and information about your cluster.

You will have to mount the key file to the container for this to work. You can do this by adding the following line to your apply command

```bash
-v PATH_TO_KEY_FILE:/host/.vault_key
```

Make sure to use a strong and complicated key and keep it safe.

#### Encryption:

```bash
docker run -it --rm -v PATH_TO_KEY_FILE:/host/.vault_key ghcr.io/chickeniq/talos-manager encrypt
```

#### Decryption:

**Note:** You don't have to decrypt the config file to apply it, it will be done automatically as long as it is mounted.

```bash
docker run -it --rm -v PATH_TO_KEY_FILE:/host/.vault_key ghcr.io/chickeniq/talos-manager decrypt
```
