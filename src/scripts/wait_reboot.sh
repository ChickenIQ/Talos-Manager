#!/bin/sh
set -e

get_stage() { 
  talosctl get machinestatus $ARGS -o yaml | yq .spec.stage | sed 's/"//g'
}

while [ "$(get_stage)" != "running" ]; do
  sleep 5
done