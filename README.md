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

1. Download the **_[example config file](https://github.com/ChickenIQ/Talos-Manager/blob/main/example.yaml)_** fron this repository.

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
    ghcr.io/chickeniq/talos-manager
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
    ghcr.io/chickeniq/talos-manager
```

## Encryption

Talos-Manager supports encryption and decryption of the config file using ansible-vault. It is highly recommended to encrypt your config file as it will contain important secrets and information about your cluster.

You will have to mount the key file to the container for this to work. Make sure to use a strong and complicated key and keep it safe.

#### Encryption:

```bash
docker run -it --rm -v PATH_TO_KEY_FILE:/host/.vault_key ghcr.io/chickeniq/talos-manager encrypt
```

#### Decryption:

**Note:** You don't have to decrypt the config file to apply it, it will be done automatically as long as it is mounted.

```bash
docker run -it --rm -v PATH_TO_KEY_FILE:/host/.vault_key ghcr.io/chickeniq/talos-manager decrypt
```

## How it works

All of the steps below are done automatically by Talos-Manager on every launch.

### Config Generation

Talos-Manager uses your config file to generate the necessary files to deploy and manage your Talos cluster using the secrets provided.
The required files are generated on every launch and depending on your configuration.

1. Creates the global, controlplane and worker patches

2. Creates the patches required for your CNI of choice

3. Decodes and decompresses the secrets string and stores it in the datastore as secrets.yaml

4. Adds all controlplane ips and additional FQDNs/IPs to the TLS SANs

5. Generates the config files using the provided patches and secrets

6. Adds all nodes and endpoints to the talosconfig

7. Backs up your previous host talosconfig

8. Deletes any context with the same name and then merges the generated talosconfig

### Deployment

After the config generation, Talos-Manager will deploy your cluster using the generated config files.

1. Checks if the node is in maintenance mode

2. If the node has already been initialized, it will take a snapshot of the current machineconfig

3. Generates patches for the node if specified

4. Applies the configs with the patches and waits for the node to reboot

5. Upgrades k8s if a new version is detected then waits for the controlplane to be ready

6. Get the new rendered machineconfig and compares it with the snapshot for changes to the image

7. If the image has changed, it will upgrade the machine with the new image/version

### Cluster Bootstrap

After the deployment, Talos-Manager will bootstrap your cluster using the 1st available controlplane node.

1. Waits for etcd to be ready

2. Bootstraps the cluster if necessary

3. Waits for the kubernetes api to be available

4. Backs up your previous host kubeconfig

5. Deletes any context with the same name and merges the new one optained from the cluster

### Post Deployment

After the bootstrap, Talos-Manager will add the specified components to the cluster

1. Sets up the specified CNI (currently only cilium is supported, flannel does not need to be set up)

- Creates the cilium namespace if necessary

- Installs/Upgrades cilium with the specified configuration

2. Sets up the specified GitOps Platform (currently only fluxcd is supported)

- Creates the fluxcd namespace and sops secrets if necessary

- Bootstraps the fluxcd components
