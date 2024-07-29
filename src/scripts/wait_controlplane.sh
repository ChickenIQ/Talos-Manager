#!/bin/sh
set -e

get_status() { 
  talosctl get staticpodstatus $ARGS | grep kube-apiserver | awk '{print $6}'
}

while [ "$(get_status)" != "True" ]; do
  sleep 5
done