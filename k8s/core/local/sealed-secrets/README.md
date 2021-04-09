Store the key as backup in secrets manager

```sh
kubectl get secret -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml >master.key
```


Export the following env vars:
```bash
export SEALED_SECRETS_CONTROLLER_NAMESPACE=sealed-secrets
export SEALED_SECRETS_CONTROLLER_NAME=sealed-secrets
```
