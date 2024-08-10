<h1 align="center">Talos Manager (Work In Progress)</h1>

A simple, yet powerful tool to create and manage your Kubernetes clusters using [Talos Linux](https://talos.dev/).

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

- Cilium integration

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

3. Replace the example values with your own.

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

## Encrypting your config file

Talos-Manager supports encryption and decryption of the config file using ansible-vault.

It is highly recommended to encrypt your config file as it contains credentials that can be used to gain full access to your cluster.

### Encryption:

```bash
docker run --rm -v ./example.yaml:/config.yaml -e VAULT_KEY="vault key" ghcr.io/chickeniq/talos-manager encrypt
```

### Decryption:

```bash
docker run --rm -v ./example.yaml:/config.yaml -e VAULT_KEY="vault key" ghcr.io/chickeniq/talos-manager decrypt
```

### Automatic decryption

To use automatic decryption, you have to provide the vault key as an environment variable in your apply command:

```bash
-e VAULT_KEY="vault key"
```

# Configuration options

Talos-Manager allows you to configure your cluster using a single YAML file, through a couple Talos-Manager specific variables, patches and addons.

The config file is nothing but an Ansible inventory file and can be configured like one. The only difference is that the group names `cluster`, `controlplane` and `worker` cannot be changed.

| Name             | Description               | Required | Default value                |
| ---------------- | ------------------------- | -------- | ---------------------------- |
| cluster_name     | The name of the cluster   | Yes      | -                            |
| cluster_endpoint | Kubernetes endpoint       | Yes      | -                            |
| tls_sans         | Additional TLS SANs       | No       | The IPs of all controlplanes |
| talos_image      | Talos image to use        | No       | ghcr.io/siderolabs/installer |
| talos_version    | Talos version to use      | No       | Latest tested version        |
| k8s_version      | Kubernetes version to use | No       | Latest tested version        |
| secrets          | Cluster secrets           | Yes      | -                            |
| patches          | Patches to apply          | No       | -                            |
| addons           | Addons to install         | No       | -                            |

**Note:**

If a talos/k8s version isn't set. Talos-Manager will automatically upgrade your cluster to the latest tested version.
It is highly recommened that you define the versions you want to use to prevent unexpected upgrades.

If the tls_sans are modified, the IPs of all controlplanes will be prepended to the list.
This is necessary to prevent errors when bootstrapping the cluster when a public IP is used.

## Patches

Most of the configuration is done using patches, similar to the way you would configure a cluster using talosctl.

Patches are optional and can be applied on a per node or per group basis including a global patch that applies to all nodes.

You can use the **_[official docs](https://www.talos.dev/latest/reference/configuration/v1alpha1/config/)_** to write your patches.

`Global`, `controlplane` and `worker` patches are baked into the generated config, with the most specific patch type taking precedence, while machinepatches (per node) are applied on top of the generated config and override any other patches.

**Per node patches:**

```yaml
controlplane:
  hosts:
    192.168.1.100:
      machinepatches:
        # Change hostname to a
        machine:
          network:
            hostname: a

worker:
  hosts:
    192.168.1.200:
      machinepatches:
        # Change hostname to b
        machine:
          network:
            hostname: b

    # Use nodes IPs from 192.168.1.10 to 192.168.1.20
    # 192.168.1.[10:20]:
```

**Per group patches:**

```yaml
cluster:
  vars:
    patches:
      global:
        # Enable kubespan for all nodes
        machine:
          network:
            kubespan:
              enabled: true

      controlplane:
        # Allow scheduling on controlplanes
        cluster:
          allowSchedulingOnControlPlanes: true

      worker:
        # Change install disk for all workers
        machine:
          install:
            disk: /dev/nvme0n1
```

## Addons

Talos-Manager allows you to extend the functionality of your cluster by installing certain helm charts, which we will call addons.

The following addons are currently supported:

- Cilium
- FluxCD

Create an issue if you would like to see more addons added to the project.

### [Cilium](https://cilium.io/)

Cilium replaces flannel as the CNI provider and provides a lot of additional features.

This addon is deployed using the helm values provided in the official Talos docs, also replacing kube-proxy.

### Cilium configuration

| Name                  | Description                                     | Required | Default value         |
| --------------------- | ----------------------------------------------- | -------- | --------------------- |
| enabled               | Enable the cilium addon                         | No       | false                 |
| version               | Cilium version to use                           | No       | Latest tested version |
| namespace             | Namespace to install cilium                     | No       | kube-system           |
| enable_default_policy | Use the networkpolicy provided by Talos-Manager | No       | false                 |
| helm_values           | Additional helm values                          | No       | -                     |

**Information about the networkpolicy provided by Talos-Manager (Disabled by default)**

**Note:** When this is enabled for the first time or updates, an automatic reboot will be triggered. All controlplanes will be rebooted one at a time.

This policy is split into multiple files and is not visible via the crds. It is loaded from the filesystem under `/var/lib/Talos-Manager/cilium/`.

You can check if the policy was applied correctly by running `cilium policy get` inside a cilium pod.

The default networkpolicy is a set of policies that allows every pod to access the kube-dns and deny all traffic to the pods inside the cluster, but allow traffic to the outside world.

The kube-system and the specified cilium namespace are considered privileged namespaces and have unrestricted access to the cluster.

Pods running in the host network are also considered privileged. They also have unrestricted access to the cluster.

<details>
  <summary>Rendered policy preview</summary>

#### Allow every pod to access the kube-dns

**Path:** /var/lib/Talos-Manager/cilium/kube-dns.yaml

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: kube-dns
  namespace: kube-system
spec:
  endpointSelector:
    matchLabels:
      k8s-app: kube-dns
  ingress:
    - fromEntities:
        - cluster
        - remote-node
      toPorts:
        - ports:
            - port: "53"
              protocol: UDP
```

### Allow all traffic inside the kube-system namespace, deny ingress from every other pod

**Path:** /var/lib/Talos-Manager/cilium/kube-system.yaml

```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: kube-system
  namespace: kube-system
spec:
  endpointSelector: {}
  ingress:
    - fromEndpoints:
        - {}
    - fromEntities:
        - remote-node
  egress:
    - toEntities:
        - all
```

### Allow all traffic inside the specified cilium namespace, deny ingress from every other pod

**Path:** /var/lib/Talos-Manager/cilium/cilium-namespace.yaml

```yaml
# This file is only created if a namespace besides kube-system is used
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: cilium
  namespace: cilium_namespace
spec:
  endpointSelector: {}
  ingress:
    - fromEndpoints:
        - {}
    - fromEntities:
        - remote-node
  egress:
    - toEntities:
        - all
```

### Allow ingress from outside the cluster and pods running in the host network

### Allow egress to outside the cluster and kube-dns

**Path:** /var/lib/Talos-Manager/cilium/global.yaml

```yaml
apiVersion: cilium.io/v2
kind: CiliumClusterwideNetworkPolicy
metadata:
  name: global
spec:
  endpointSelector:
    matchExpressions:
      - key: io.kubernetes.pod.namespace
        operator: NotIn
        values:
          - kube-system
          - cilium_namespace # Only present if specified
  ingress:
    - fromEntities:
        - world
        - remote-node
  egress:
    - toEntities:
        - world
    - toEndpoints:
        - matchLabels:
            io.kubernetes.pod.namespace: kube-system
            k8s-app: kube-dns
      toPorts:
        - ports:
            - port: "53"
              protocol: UDP
          rules:
            dns:
              - matchPattern: "*"
```

</details>

### [FluxCD](https://fluxcd.io/)

FluxCD is a tool that allows you to automatically deploy your workloads using gitops.

This addon is deployed using the flux cli and currently only supports GitHub repositories.

**FluxCD configuration**

| Name       | Description                              | Required | Default value  |
| ---------- | ---------------------------------------- | -------- | -------------- |
| enabled    | Enable the fluxcd addon                  | No       | false          |
| update     | Update the configuration on apply        | No       | false          |
| branch     | Branch to use                            | No       | main           |
| username   | GitHub username                          | Yes      | -              |
| repository | GitHub repository                        | Yes      | -              |
| path       | Path for the FluxCD configuration        | No       | /clusters/main |
| token      | GitHub token                             | Yes      | -              |
| sops       | Gzipped, Base64 encoded SOPS private key | No       | -              |

## Upgrades

Upgrades are automatic and work similar to how you would upgrade your cluster using talosctl.

As soon as a version/image change is detected, Talos-Manager will automatically upgrade k8s then talos, one node at a time, making sure the upgrade was succesful before moving to the next node.

### Differences from talosctl

- Talos upgrades can use different images

  - This allows you declare the images for every node, improving hardware compatibility.
  - talosctl is also able to provide this functionality, but it is necessary to run the upgrade command with the specific image flag for each node.

- All kubernetes components are upgraded at once

  - The workloads running on the node and etcd are left intact.
  - This results in quite a noticeable speed increase, but at the cost of the node becoming unschedulable for a short period of time.
