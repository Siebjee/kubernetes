Welcome to my public repository for my "kubernetes blueprint".

- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
	- [Installation](#installation)
	- [Configuration of harbor](#configuration-of-harbor)
- [Internal Components](#internal-components)
- [Available URLS:](#available-urls)
- [Using harbor in k8s](#using-harbor-in-k8s)
- [Repository layout](#repository-layout)
	- [Cluster definitions](#cluster-definitions)
	- [Creating new resources](#creating-new-resources)
- [External references](#external-references)
- [Troubleshooting](#troubleshooting)
	- [Flux-system can't check image tags due to x509 error](#flux-system-cant-check-image-tags-due-to-x509-error)
	- [Slackhook not working](#slackhook-not-working)

# Prerequisites
* For deploying `local-minimal` or `local`(default) cluster you require atleast 16GB of mamory.
* Read up on Flux V2, and their [multi-cluster setup](https://github.com/fluxcd/flux2-kustomize-helm-example)
* Add `127.0.0.0/8` and `harbor.k8s-local.io` to the list of insecure registries and restart docker

# Getting Started
## Installation
Instal through `brew`, or your favorite package manager `fluxctl` and `argo`.

```
brew install helm fluxcd/tap/flux argoproj/tap/argo
```

And after, run `bin/setup`
```
bin/setup.sh
```

### Retrieving secrets
in case of needing to know the secrets:
```
bin/secrets.sh
```

## Configuration of harbor
To setup harbor for the demo project:

```
bin/setup_harbor.sh
```
* Demo user: `demo` with password `Demodemo0`
* Project: `demo`
* Administrator account is printed by: `bin/secrets.sh`

## Configuration of MinIO
To setup MinIO for the demo project:

```
bin/setup_minio.sh
```

This will create the required MinIO operator tenant.

# Internal Components
* Prometheus     **(Metrics)**
* Grafana        **(Dashboards)**
* Argo-workflows **(Workflows)**
* Argo Events    **(Events controller)**
* ArgoCD         **(Continuous Delivery)**
* MinIO          **(S3 like object store)**
* Harbor         **(Helm & Docker registry)**
* Sealed-secrets **Secure secrets**
* Demo app       **(Static HTML on nginx alpine container)**
* GitOps Toolkit
* Kubernetes Dashboard
* Nginx Ingress

# Available URLS:

* [Kubernetes dashboard](https://dashboard.k8s-local.io)
* [Grafana](https://monitoring.k8s-local.io)
* [Argo workflows](https://argo.k8s-local.io)
* [ArgoCD](https://argocd.k8s-local.io)
* [Harbor](https://harbor.k8s-local.io)
* [Demo - stable](https://demo.k8s-local.io)
* [Demo - pre release](https://demo.k8s-local.io/banana)

# Using harbor in k8s
Add the following to the docker config (docker for mac e.g.)
```json
{
  "insecure-registries": [
    "harbor.k8s-local.io"
  ]
}
```

# Repository layout
```
├── argo                   # Pipelines / argo workflows / argo-events that create workflows
├── bin                    # Helper scripts
├── flux                   # Flux installation directory
├── k8                     # primary kubernetes manifests directory
│   ├── apps               # primary manifests directory
│   │   ├── base           # the base directory for all "apps" in kubernetes. Cluster kustomizations refer to this
│   │   ├── demo           #      for demo cluster deployment
│   │   ├── local          #      for local cluster deployment
│   ├── clusters           # primary cluster manifests directory
│   │   ├── demo           #      for demo cluster deployment
│   │   ├── local          #      for local cluster deployment
│   ├── core               # core k8s infrastructure manifests directory
│   │   ├── base           # the base directory for all "core" components in kubernetes. Cluster kustomizations refer to this
│   │   ├── demo           #      for demo cluster deployment
│   │   ├── local          #      for local cluster deployment
│   └── infrastructure     # Kubernetes infrastructure that will be deployed as is in every cluster.
└── templates              # Azure DevOps Pipelines templates
```

## Cluster definitions


| Cluster | argo | argo-events | argocd | demo | harbor | ingress-nginx | kubernetes-dashboard | Grafana LGTMP | metrics-server | minio | minio-tenant-1 | cert-manager |
| :-----: | :--: | :---------: | :----: | :--: | :----: | :-----------: | :------------------: | :-----------: | :------------: | :---: | :------------: | :----------: |
|  demo   |  X   |      X      |    -   |  X   |    X   |       X       |          -           |     -         |       -        |   X   |       X        |      x       |
|  local  |  X   |      X      |    -   |  -   |    -   |       X       |          -           |     -         |       -        |   -   |       -        |      x       |

## Creating new resources
### Applications
1. Create the appropriate manifests in `k8s/apps/base` like you would normally.
2. Add a `kustomization.yaml` to this directory. See example below.
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: your-namespace
resources:
  - namespace.yaml
  - secret.yaml
  - deployment.yaml
  - service.yaml
  - ingress.yaml
```
Note: the order of `resources` does matter, as this will be the deployment order..

3. For the cluster add in `k8s/<cluster>/apps/your-app` the following files: `kustomization.yaml` and if cluster customisations are required a `<app-patch>.yaml`.

  `kustomization.yaml`
  ```yaml
  apiVersion: kustomize.config.k8s.io/v1beta1
  kind: Kustomization
  namespace: your-namespace
  resources:
    - ../../base/your-app
  patchesStrategicMerge:
    - app-patch.yaml
  ```
  `app-patch.yaml`
  ```yaml
  apiVersion: helm.toolkit.fluxcd.io/v2beta1
  kind: Deployment
  metadata:
    name: your-app
    namespace: your-namespace
  spec:
    resources:
      requests:
        memory: 64Mi
        cpu: 500m
      limits:
        memory: 128Mi
        cpu: 1000m
  ```

Note: you can kustomize any kubernetes resource (including CRDS)

4. In `k8s/clusters/<cluster>/apps/your-app.yaml` add the below example to actually activate your app in the cluster
```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1beta1
kind: Kustomization
metadata:
  name: app-your-app
  namespace: flux-system
spec:
  interval: 5m
  dependsOn:
    - name: infrastructure
  sourceRef:
    kind: GitRepository
    name: playground
  path: ./k8s/apps/<cluster>/apps/your-app
  prune: true
```

### Pipelines / Workflows
TBD

### Infrastructure components
TBD

### Clusters
TBD

# External references
* [fluxcd kustomize helm examples](https://github.com/fluxcd/flux2-kustomize-helm-example)
* [sealed-secrets](https://github.com/bitnami-labs/sealed-secrets)

# Troubleshooting
## Flux-system can't check image tags due to x509 error
This is due to having self-signed certificates.
The fix is also in `bin/setup.sh` function `setup_harbor`
```bash
HARBOR_CERTS=$(kubectl --namespace harbor get secret harbor-harbor-ingress -o jsonpath="{.data}" | jq -r)
cat <<YAML | kubectl --namespace flux-system apply -f -
apiVersion: v1
kind: Secret
metadata:
name: harbor-tls-certs
namespace: flux-system
type: Opaque
data:
caFile: $(echo ${HARBOR_CERTS} | jq -r ".\"ca.crt\"")
certFile: $(echo ${HARBOR_CERTS} | jq -r ".\"tls.crt\"")
keyFile: $(echo ${HARBOR_CERTS} | jq -r ".\"tls.key\"")
YAML
```

## Slackhook not working
Well.. I removed a file. I don't like to share my slack tokens with ya'll.
```bash
cat <<YAML | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: slack-secret
  namespace: argo-events
data:
  token: <base64 slack app token. xobx-.....>
YAML
```
