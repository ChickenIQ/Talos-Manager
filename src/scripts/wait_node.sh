#!/bin/sh
set -e

ARGS=$@
CLUSTER_BOOTSRAPPED=false

get_stage() { 
  talosctl get machinestatus $ARGS -o yaml | yq .spec.stage | sed 's/"//g'
}

get_status() { 
  talosctl get staticpodstatus $ARGS | grep kube-apiserver | awk '{print $6}'
}

if [ "$(talosctl service etcd status $ARGS | grep STATE | awk '{print $2}')" == "Running" ]; then CLUSTER_BOOTSRAPPED=true; fi 

# Wait for the node to be ready
retries=0 
while [ $retries -lt 120 ]; do
  stage=$(get_stage)
  if [ $CLUSTER_BOOTSRAPPED == false ] && [ $stage == "booting" ]; then break; fi
  if [ $stage == "running" ]; then break ; fi
  retries=$((retries+1))
  sleep 5
done

if [ $retries -ge 120 ]; then
  echo "Error: Node not ready after 10 minutes!"
  exit 1
fi

# Wait for k8s if the node is a controlplane
if [ $NODE_TYPE != "controlplane" ] || [ $CLUSTER_BOOTSRAPPED == false ]; then exit 0; fi

retries=0
while [ "$(get_status)" != "True" ] && [ $retries -lt 120 ]; do
  retries=$((retries+1))
  sleep 5
done

if [ $retries -ge 120 ]; then
  echo "Error: Kubernetes ApiServer not ready after 10 minutes!"
  exit 1
fi