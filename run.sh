docker run -it --rm --network host \
    -v ~/.talos:/host/.talos \
    -v ~/.kube:/host/.kube \
    -v ./config.yaml:/host/config.yaml \
    -v ~/.ansible/.vault_key:/host/.vault_key:ro \
    ghcr.io/chickeniq/talos-manager:latest