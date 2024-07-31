#!/bin/sh
set -e

export ANSIBLE_ARGS="/src/main.yaml --connection local -i /host/config.yaml"
export VAULT_FILE="/host/.vault_key"

if [ -f $VAULT_FILE ]; then
  export ANSIBLE_ARGS="$ANSIBLE_ARGS --vault-password-file $VAULT_FILE"
  export KEY_EXISTS=true
fi

apply () {
  TASK="apply" ansible-playbook $ANSIBLE_ARGS $1
}

reset () {
  if [ "$2" != "--no-confirm" ]; then
    echo "This command will reset the cluster to its initial state, then bootstrap it again."
    echo "Warning! Data loss will occur!"
    echo "Do you want to continue? [y/N]"
    read -r CONFIRM
  else 
    export CONFIRM="y"
  fi
  
  if [ "$CONFIRM" == "y" ]; then
    TASK="reset" ansible-playbook $ANSIBLE_ARGS $1
  fi
}

vault_action() {
  if [ ! $KEY_EXISTS ]; then echo "Vault key not found."; exit 1; fi 
  # Avoid ansible bug when encrypting/decrypting a file in place
  CONTENT=$(ansible-vault $1 /host/config.yaml --vault-password-file $VAULT_FILE --output -) && 
  echo "$CONTENT" > /host/config.yaml
  echo "File $1ed successfully."
}

show_commands() {
  echo "Available commands:"
  echo "apply:          Apply the config file"
  echo "reset:          Reset the cluster"
  echo "apply-debug:    Apply the config file (verbose)"
  echo "reset-debug:    Reset the cluster (verbose)"
  echo "encrypt:        Encrypt the config file"
  echo "decrypt:        Decrypt the config file"
  echo "gen-secrets:    Generate secrets for the config file"
}

case "$1" in
  "apply")
    apply
  ;;
  "apply-debug")
    ANSIBLE_DISPLAY_SKIPPED_HOSTS=true apply -vv
  ;;
  "reset")
    reset "" $2
  ;;
  "reset-debug")
    ANSIBLE_DISPLAY_SKIPPED_HOSTS=true reset -vv $2
  ;;
  "encrypt")
    vault_action encrypt
    ;;
  "decrypt")
    vault_action decrypt
    ;;
  "gen-secrets")
    talosctl gen secrets -o /tmp/secrets.yaml && gzip /tmp/secrets.yaml && base64 /tmp/secrets.yaml.gz -w0
    ;;
  "--")
    shift
    exec "$@"
  ;;
  *)
    show_commands
    ;;
esac