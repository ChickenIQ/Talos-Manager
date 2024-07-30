FROM alpine:latest

RUN apk add --no-cache ansible curl py3-kubernetes helm yq

RUN ansible-galaxy collection install kubernetes.core

RUN curl -L https://github.com/siderolabs/talos/releases/latest/download/talosctl-linux-amd64 -o /usr/bin/talosctl && \
    chmod +x /usr/bin/talosctl

# Why did they have to add the version to the package name? :(
RUN curl -L https://api.github.com/repos/fluxcd/flux2/releases/latest -o /tmp/metadata.json && \
    VERSION=$(grep '"tag_name":' "/tmp/metadata.json" | sed -E 's/.*"([^"]+)".*/\1/' | cut -c 2-) && \
    curl -L https://github.com/fluxcd/flux2/releases/download/v${VERSION}/flux_${VERSION}_linux_amd64.tar.gz -o /tmp/flux.tar.gz && \
    tar -xzvf /tmp/flux.tar.gz -C /usr/bin && rm /tmp/metadata.json /tmp/flux.tar.gz && \
    chmod +x /usr/bin/flux
    
RUN adduser -D alpine && mkdir -p /data/patches /data/configs /host && chown -R alpine:alpine /data /host
    
COPY ./src /src

WORKDIR /src

RUN chmod +x /src/scripts/*

USER alpine

ENTRYPOINT [ "/src/scripts/entrypoint.sh" ]
