#!/bin/sh
set -e

export ARGS=$@

get_stage() { 
  talosctl get machinestatus $ARGS -o yaml | yq .spec.stage | sed 's/"//g'
}

get_status() { 
  talosctl get staticpodstatus $ARGS | grep kube-apiserver | awk '{print $6}'
}

# Wait for the node to be ready
export retries=0 
while [ "$(get_stage)" != "running" ] && [ $retries -lt 120 ]; do
  retries=$((retries+1))
  sleep 5
done

if [ $retries -ge 120 ]; then
  echo "Error: Node not ready after 10 minutes!"
  exit 1
fi

# Wait for k8s if the node is a controlplane
if [ $NODE_TYPE != "controlplane" ]; then exit 0; fi

export retries=0
while [ "$(get_status)" != "True" ] && [ $retries -lt 120 ]; do
  retries=$((retries+1))
  sleep 5
done

if [ $retries -ge 120 ]; then
  echo "Error: Kubernetes ApiServer not ready after 10 minutes!"
  exit 1
fi