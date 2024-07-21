docker run -it --rm --network host \
    -v ~/.talos:/data/.talos \
    -v ~/.kube:/data/.kube \
    -v ./config.yaml:/data/config.yaml:ro \
    -v ~/.ansible/.vault_key:/data/.vault_key:ro \
    ghcr.io/chickeniq/talos-manager:latest 