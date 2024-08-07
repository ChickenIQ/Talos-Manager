#!/bin/sh
set -e

export ANSIBLE_ARGS="/src/main.yaml --connection local -i /src/group.yaml -i /config.yaml"

if [ -n "$VAULT_KEY" ]; then 
  echo "$VAULT_KEY" > /tmp/.vault_key
  export ANSIBLE_ARGS="$ANSIBLE_ARGS --vault-password-file /tmp/.vault_key"
fi

apply () {
  TASK="apply" ansible-playbook $ANSIBLE_ARGS $1
}

reset () {
  CONFIRM="y"
  if [ "$2" != "--no-confirm" ]; then
    echo "This command will reset the cluster to its initial state, then bootstrap it again."
    echo "Warning! Data loss will occur!"
    echo "Do you want to continue? [y/N]"
    read -r CONFIRM
  fi
  
  if [ "$CONFIRM" == "y" ]; then
    TASK="reset" ansible-playbook $ANSIBLE_ARGS $1
  fi
}

vault_action() {
  if [ -z "$VAULT_KEY" ]; then echo "Vault key not found."; exit 1; fi 
  # Avoid problems when encrypting/decrypting a file in place
  CONTENT=$(ansible-vault $1 /config.yaml --vault-password-file /tmp/.vault_key --output -) && 
  echo "$CONTENT" > /config.yaml && echo "File "$1"ed successfully."
}

gen_secrets() {
  SECRETS=$(talosctl gen secrets -o /tmp/secrets.yaml && gzip /tmp/secrets.yaml && base64 /tmp/secrets.yaml.gz -w0)

  if [ ! -f /config.yaml ]; then echo $SECRETS; exit 0; fi

  if head -n 1 /config.yaml | grep -q "\$ANSIBLE_VAULT"; then
    echo "The config file is encrypted, please decrypt it before continuing!"
    exit 1
  fi

  CONFIG_SECRETS=$(yq ".cluster.vars.secrets" /config.yaml)

  if [ "$CONFIG_SECRETS" == "" ] ||  [ "$CONFIG_SECRETS" == "null" ]; then
    # Avoid losing whitespace
    NEW_CONFIG=$(sed '/^$/s//#NEWLINE/' /config.yaml | yq ".cluster.vars.secrets = \"$SECRETS\"" | sed 's/#NEWLINE//') &&
    echo "$NEW_CONFIG" > /config.yaml && 
    echo "Secrets generated successfully."
  else
    echo "Secrets not empty, refusing to continue"
    exit 1
  fi
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
    gen_secrets
    ;;
  "--")
    shift
    exec "$@"
  ;;
  *)
    show_commands
    ;;
esac