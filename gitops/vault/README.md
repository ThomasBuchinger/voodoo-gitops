The vault-unseal-keys secrets contains the unseal-keys and root-token for vault.
This secret was first generated randomly and then copied to match the initial config. if this secret is lost, vault is lost...

apiVersion: v1
kind: Secret
metadata:
  name: vault-unseal-keys
  namespace: default
  labels:
    app.kubernetes.io/name: vault
    vault_cr: vault
stringData:
  vault-root: 
  vault-test: 
  vault-unseal-0: # unseal keys are hexadecimal and 66 characters long
  vault-unseal-1: 111111111111111111111111111111111111111111111111111111111111111111
  vault-unseal-2: 
  vault-unseal-3: 
  vault-unseal-4: 
type: Opaque


