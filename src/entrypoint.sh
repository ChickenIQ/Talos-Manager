#!/bin/sh

export ANSIBLE_ARGS="/src/playbooks/main.yaml --connection local -i /host/config.yaml"
export VAULT_FILE="/host/.vault_key"

if [ -f /host/.vault_key ]; then
  export ANSIBLE_ARGS="$ANSIBLE_ARGS --vault-password-file $VAULT_FILE"
  export KEY_EXISTS=true
fi

start () {
  ansible-playbook $ANSIBLE_ARGS $1
}

vault_action() {
  if [ $KEY_EXISTS ]; then
    # Avoid ansible bug when encrypting/decrypting a file in place
    CONTENT=$(ansible-vault $1 /host/config.yaml --vault-password-file $VAULT_FILE --output -) && 
    echo "$CONTENT" > /host/config.yaml
  else
    echo "Vault key not found."
  fi
}

case "$1" in
  "")
    start
  ;;
  "sh")
    sh
  ;;
  "start")
    start
  ;;
  "debug")
    start -vv
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
  *)
    echo "Unknown command!"
    echo ""
    echo "Available commands:"
    echo "sh:           Start a shell"
    echo "start:        Execute normally"
    echo "debug:        Execute in debug mode"
    echo "encrypt:      Encrypt the config file"
    echo "decrypt:      Decrypt the config file"
    echo "gen-secrets:  Generate secrets for the config file"
    ;;
esac