docker run -it --rm --network host \
    -v ~/.talos:/host/.talos \
    -v ~/.kube:/host/.kube \
    -v ./config.yaml:/host/config.yaml \
    ghcr.io/chickeniq/talos-manager:latest