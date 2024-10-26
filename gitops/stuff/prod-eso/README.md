Fetch necessary data from cluster

```shell
kubectl -n default get configmap kube-root-ca.crt -o "jsonpath={.data['ca\.crt']}" | base64 -w 0

```

