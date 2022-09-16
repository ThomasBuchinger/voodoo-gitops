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

---

Setup Secrets Automatically
https://www.reddit.com/r/kubernetes/comments/xao5pe/automatically_import_secrets_into_vault/

## Solution 1: Template Secrets in StartupSecrets

Patch Vault custom resource as follows

``yaml
apiVersion: "vault.banzaicloud.com/v1alpha1"
kind: Vault
metadata:
  name: vault
spec:
  # ... vault custom resource ...
  externalConfig:
    startupSecrets:
      - type: kv
        path: secret/data/path-to-secret
        data:
          data:
            foo: "${env `MY_SECRET_ENV_VARIABLE`}"
  envsConfig:
    - name: MY_SECRET_ENV_VARIABLE
      valueFrom:
        secretKeyRef:
          name: name-of-the-secret
          key: name-of-the-key-inside-the-secret
          optional: true
```

## Solution 2: Mutating Webhook


The vault-secrets-webhook can also be used to write to vault. This feature is [documented here](https://banzaicloud.com/docs/bank-vaults/mutating-webhook/configuration/#write-a-value-into-vault) and nowhere else. The feature is originally designed to support a few vault-secret-engines, that require to send a HTTP PUT request, but can be used to send arbitrary requests to Vault

* You need to make sure that any secrets that use this feature are deployed AFTER Vault and the Vault webhook are ready
* The Webhook differentiates between create and update. This is based on the k8s-secret, so you need to recreate the k8s-secret, if the secret does not exist in vault
* I like that the vault-path is part of the secret, not the vault custom-resource

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: test-secret
  annotations:
    vault.security.banzaicloud.io/vault-addr: "http://vault:8200"
    vault.security.banzaicloud.io/vault-role: "writer-role-name"
    vault.security.banzaicloud.io/vault-skip-verify: "true"
    vault.security.banzaicloud.io/vault-agent: "false"

stringData:
  # ">>vault:"  Sets the HTTP-Method to PU
  # "secret/data/test"  Combined with vault-addr to form the URL
  # "#hello" Name of the key
  # "#{\"data\":{\"hello\":\"my_secret_value\"}}"  HTTP Body sent to Vault
  #
  # This translates to: curl -X PUT http://vault:8200/v1/secret/data/test --data "{\"data\":{\"hello\":\"my_secret_value\"}}"
  myworld: ">>vault:secret/data/test#hello#{\"data\":{\"hello\":\"my_secret_value\"}}"
```
