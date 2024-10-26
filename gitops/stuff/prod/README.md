Fetch necessary data from cluster

* Run the below command on evergreen
* Copy the result in `secrets/eso-k8s-token.yaml`

```shell
CA_CRT=$(kubectl -n prod get secret prod-eso-auth-token -o "jsonpath={.data['ca\.crt']}")
NS=$(kubectl -n prod get secret prod-eso-auth-token -o "jsonpath={.data.namespace}")
TOKEN=$(kubectl -n prod get secret prod-eso-auth-token -o "jsonpath={.data.token}")

envsubst <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: external-secrets
---
apiVersion: v1
kind: Secret
metadata:
  name: evergreen-token
  namespace: external-secrets
data:
  token: $TOKEN
  ns: $NS
  ca.crt: $CA_CRT
EOF

```

---

Human Readable:

```shell
echo "API Server CA Cert:"
kubectl -n prod get secret prod-eso-auth-token -o "jsonpath={.data['ca\.crt']}" | base64 -d
echo -e "\nNamespace:"
kubectl -n prod get secret prod-eso-auth-token -o "jsonpath={.data.namespace}"  | base64 -d
echo -e "\n\nJWT Token:"
kubectl -n prod get secret prod-eso-auth-token -o "jsonpath={.data.token}"      | base64 -d
echo -e "\n"
```

