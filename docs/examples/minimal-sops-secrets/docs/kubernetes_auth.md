# Authenticating with Kubernetes

In order to connect to your Kubernetes cluster, you'll need to set the environment
variable `KUBECONFIG_DATA`. This variable should contain a valid base64 encoded
[kubeconfig](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/)

## Using an Existing Kubeconfig
> Note: Using your local kubeconfig is NOT recommended. It is much more secure
> to use cloud provider credentials or create a service account, as shown below

The easiest way to authenticate is to pass a valid kubeconfig to the `base64` command. (The `-w` flag is unnecessary on MacOS and should be left out.)

```
cat ~/.kube/config | base64 -w 0
```

The output of this command should be set as the environment variable `KUBECONFIG_DATA`
in the settings for your CI platform.

## Using Cloud Providers
If you're using EKS or GKE, the preferred method of authentication is to create a deployment
account on AWS or GCP. Using the credentials for that account, cell-ci-cd can use the
`aws-cli` and `gcloud` tools to authenticate with your cluster.

See the documentation for [AWS](aws.md) or [GCP](gcp.md) for more information.

## Using a Service Account
[Service accounts](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/)
are the best method for granting automated access to the Kubernetes API if you're not using
a managed Kubernetes service like EKS or GKE. You can use
these instructions to generate a kubeconfig for a service account.

### Creating a Service Account
> If you've already got a service account set up with the necessary permissions,
> you can skip this section

Use these commands to create a new namespace `cell-ci-cd`, along with a ServiceAccount.
```
kubectl create namespace cell-ci-cd
kubectl create serviceaccount cell-ci-cd -n cell-ci-cd
```

#### Super-user permissions
> It's recommended that you use a tighter ClusterRole than `cluster-admin` in order
> to follow the principle of least privilege. See "Safter permissions" for details
Depending on what features of cell-ci-cd you're using, you'll need different permissions.
This example simply grants `cluster-admin` access to the service account, which grants
super-user access to cell-ci-cd.
```
kubectl create clusterrolebinding cell-ci-cd \
  --clusterrole=cluster-admin \
  --serviceaccount=cell-ci-cd:cell-ci-cd
```

#### Safer permissions
> The examples below use [rbac-manager](https://github.com/FairwindsOps/rbac-manager)
> to simplify the permissions model

One common pattern is to only grant `cluster-admin` permissions on namespaces that
have been explicitly given the label `cell-ci-cd-admin`

*NOTE*: The `tiller` related permissions here are obsolete as of cell-ci-cd v11+ due to the
introduction of Helm3.

```yaml
apiVersion: rbacmanager.reactiveops.io/v1beta1
kind: RBACDefinition
metadata:
 name: cell-ci-cd
rbacBindings:
 - name: cell-ci-cd
   subjects:
     - kind: ServiceAccount
       name: cell-ci-cd
       namespace: cell-ci-cd
   roleBindings:
     - clusterRole: cluster-admin
       namespaceSelector:
         matchLabels:
           cell-ci-cd-admin: "true"
```

Or, if you'll be using Helm to push your deployments, and all those deployments will live
in the same namespace, you can simply grant access to Tiller:

```yaml
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: tiller-manager
  namespace: tiller-world
rules:
- apiGroups: ["", "batch", "extensions", "apps"]
  resources: ["*"]
  verbs: ["*"]
---
apiVersion: rbacmanager.reactiveops.io/v1beta1
kind: RBACDefinition
metadata:
 name: rbac-definition
rbacBindings:
 - name: circleci
   subjects:
     - kind: ServiceAccount
       name: cell-ci-cd
       namespace: cell-ci-cd
   roleBindings:
     - clusterRole: tiller-manager
       namespace: tiller-world
```

### Generating the kubeconfig
Assuming your service account is named `cell-ci-cd` and is in the `cell-ci-cd` namespace,
you can use the below to generate the necessary `KUBECONFIG_DATA` value.

```bash
namespace="cell-ci-cd"
serviceaccount="cell-ci-cd"

sa_secret_name=$(kubectl -n "${namespace}" get serviceaccount "${serviceaccount}" -o 'jsonpath={.secrets[0].name}')

context_name="$(kubectl config current-context)"
kubeconfig_old="${KUBECONFIG}"
cluster_name="$(kubectl config view -o "jsonpath={.contexts[?(@.name==\"${context_name}\")].context.cluster}")"
server_name="$(kubectl config view -o "jsonpath={.clusters[?(@.name==\"${cluster_name}\")].cluster.server}")"
cacert="$(kubectl -n "${namespace}" get secret "${sa_secret_name}" -o "jsonpath={.data.ca\.crt}" | base64 --decode)"
token="$(kubectl -n "${namespace}" get secret "${sa_secret_name}" -o "jsonpath={.data.token}" | base64 --decode)"

export KUBECONFIG="$(mktemp)"
kubectl config set-credentials "${serviceaccount}" --token="${token}" >/dev/null
ca_crt="$(mktemp)"; echo "${cacert}" > ${ca_crt}
kubectl config set-cluster "${cluster_name}" --server="${server_name}" --certificate-authority="$ca_crt" --embed-certs >/dev/null
kubectl config set-context "${cluster_name}" --cluster="${cluster_name}" --user="${serviceaccount}" >/dev/null
kubectl config use-context "${cluster_name}" >/dev/null

KUBECONFIG_DATA=$(cat "${KUBECONFIG}" | base64 -w 0)
rm ${KUBECONFIG}
export KUBECONFIG="${kubeconfig_old}"
echo "${KUBECONFIG_DATA}"
```
