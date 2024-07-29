docker run -it --rm \
    -v ~/.talos:/host/.talos \
    -v ~/.kube:/host/.kube \
    -v ./config.yaml:/host/config.yaml \
    ghcr.io/chickeniq/talos-manager:latest