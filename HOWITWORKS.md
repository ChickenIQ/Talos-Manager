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
