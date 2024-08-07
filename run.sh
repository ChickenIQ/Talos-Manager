#!/bin/sh

docker run -it --rm \
    -v ~/.kube:/.kube \
    -v ~/.talos:/.talos \
    -v ./config.yaml:/config.yaml \
    ghcr.io/chickeniq/talos-manager:latest $1