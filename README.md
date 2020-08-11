# Getting-started

#### New Porjects
* To get your new project CI/CD ready run the below script in your preject root. 

```shell
bash <(curl -s https://eks-dtap-shared.s3.us-east-2.amazonaws.com/cicdscripts/cicd-bootstrap.sh)
```

#### Existing Projects:
* For existing projects use the below migration script in your project root.

```shell
bash <(curl -s https://eks-dtap-shared.s3.us-east-2.amazonaws.com/cicdscripts/cicd-migration.sh)
```

# How the Pipeline works
### Deploying to Kubernetes with Helm

[Helm](https://helm.sh/) is a popular Kubernetes package manager. To deploy to Kubernetes with Helm, you'll first need to [initialize it in your cluster](https://docs.helm.sh/using_helm#install-helm).

## Initial Project Structure

All CI/CD-scripts configuration lives in a `deploy` directory at the root of your project by default.

```plaintext
app-dir/
├── deploy/
│   ├── production.config                        // production build configs
│   ├── approval.config                         // approval build configs
│   ├── testing.config                         // testing build configs
│   ├── development.config                    // development build configs
│   ├── charts/                              // All HELM chart configuration for the app
│   │   └── app/
│   │       ├── Chart.yaml
│   │       └── templates/
│   │           ├── app.deployment.yaml
│   │           ├── app-env.configmap.yaml
│   │           ├── app.ingress.yaml
│   │           └── app.service.yaml
│   ├── production/                           // Contains files to deploy to dev environment
│   │   ├── prod-env.secret.sops.yml          // Secrets in SOPS: <secret-name>.secret.sops.yml
│   │   └── prod.values.yml                   // Helm values: <app>.values.yml
│   ├── approval/                             // Contains files to deploy to dev environment
│   │   ├── approval-env.secret.sops.yml      // Secrets in SOPS: <secret-name>.secret.sops.yml
│   │   └── approval.values.yml               // Helm values: <app>.values.yml
│   ├── testing/                              // Contains files to deploy to dev environment
│   │   ├── test-env.secret.sops.yml          // Secrets in SOPS: <secret-name>.secret.sops.yml
│   │   └── test.values.yml                   // Helm values: <app>.values.yml
│   ├── development/                          // Contains files to deploy to dev environment
│   │   ├── dev-env.secret.sops.yml           // Secrets in SOPS: <secret-name>.secret.sops.yml
│   │   └── dev.values.yml                    // Helm values: <app>.values.yml
├── app.files
├── Dockerfile                                // If project USES dockerfiles.
└── README.md
```

In the above structure we've added a Helm chart, which we won't be outlining here. The other additional files and folder we'll outline below.

## Configuration
The `deploy/development.config` file here is a CI/CD config file for the development environment.

```bash
NAMESPACE='development'
SOPS_SECRETS=('development/app-env')
HELM_CHARTS=('charts/app')
HELM_RELEASE_NAMES=('app-dev')
HELM_VALUES=('development/dev')
```

You'll see that some of these configurations reference _similar_, but not exact, matches to the files above. Note `deploy/development/dev.values.yml` translates to `HELM_VALUES=('development/dev')`. The `deploy/development/app-env.secret.sops.yml` file translates to `SOPS_SECRETS=('development/app-env')`. **Note that if the files are not named with the expected extensions then CI/CD will not work**.

## Helm Values Files
Helm uses values files to fill in chart templates. In this example, our values file is reference in CI/CD config as `HELM_VALUES=('development/dev')`, which maps to reading the `deploy/development/dev.values.yml` file. A simple values file might look something like this:

```yaml
---
image: 012345678911.dkr.ecr.us-east-1.amazonaws.com/app
somevalue: anothervalue
```

## Secret Management
Helm stores release information in Config Maps. If we deployed Kubernetes Secrets with Helm, they'd also be visible in that Helm release Config Map. To avoid that, we manage secrets separately. Please see [Managing Kubernetes Secrets Securely](https://git.prod.cellulant.com/ops-templates/ci-cd-workflows/rok8s-scripts/getting-started/blob/master/docs/secrets.md) for further information.

## Deploying it All
This step assumes that you've already configured access to your cluster in your pipeline.

With cluster auth in place, chart values configured, and Docker images build, you're ready to deploy this with Helm:

follow the git workflow document below:
* [ CI/CD Wokflow ](https://git.prod.cellulant.com/ops-templates/ci-cd-workflows/rok8s-scripts/getting-started/-/wikis/home) 

This script reads the CI/CD config file (`deploy/development.config`) and runs a Helm upgrade or install with the given values files.

## Advanced Configuration

### Multiple Charts
The Helm environment variables here all support multiple values. Each value in each array should line up with the value of the other arrays at that position.

```bash
NAMESPACE='development'
HELM_CHARTS=('charts/app' 'charts/app2')
HELM_RELEASE_NAMES=('app-dev' 'app-2-dev')
HELM_VALUES=('development/app' 'development/app2')
```

### Multiple Releases
Similar to above, we can reuse the same chart but have multiple releases of it with slightly different configuration:

```bash
NAMESPACE='development'
HELM_CHARTS=('charts/app' 'charts/app')
HELM_RELEASE_NAMES=('app-dev' 'app-variant')
HELM_VALUES=('development/app' 'development/app-variant')
```

### Multiple Values Files
In some cases, the values files between environments will be quite similar. A helpful pattern involves using a base values file along with environment specific values files.

```bash
# development.config
NAMESPACE='development'
HELM_CHARTS=('charts/app')
HELM_RELEASE_NAMES=('app-dev')
HELM_VALUES=('shared/app,development/app')

# staging.config
NAMESPACE='staging'
HELM_CHARTS=('charts/app')
HELM_RELEASE_NAMES=('app-dev')
HELM_VALUES=('shared/app,staging/app')
```

### Remote Charts
In some cases, it may make more sense to use a remote chart from a Helm repository. This can be accomplished with a couple extra parameters.

```bash
HELM_REPO_NAMES=('bitnami')
HELM_REPO_URLS=('https://charts.bitnami.com')

HELM_CHARTS=('bitnami/redis')
HELM_RELEASE_NAMES=('redis-dev')
HELM_VALUES=('development/redis')
```