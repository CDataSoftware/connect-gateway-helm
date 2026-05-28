# connect-gateway

Helm chart for deploying the [CData Connect Gateway](https://docs.cloud.cdata.com/en/Connect-Gateway) on Kubernetes.

The Connect Gateway runs as an agent inside your infrastructure and establishes a secure outbound connection to CData Connect AI, enabling cloud-based tools to query on-premises or private data sources without opening inbound firewall rules.

## Requirements

- Kubernetes 1.25+
- Helm 3.10+
- A CData Connect AI account with a Gateway location ID, account ID, and API key

> **One release per namespace.** The chart creates resources with fixed names (`connect-gateway` Deployment, Service, HPA, etc.) so two releases in the same namespace will collide. Install each Gateway location in its own namespace.

## Installation

You can install the chart two ways. Pick whichever fits your workflow.

### Option A: Add the Helm repository (recommended)

```bash
helm repo add cdata https://cdatasoftware.github.io/connect-gateway-helm
helm repo update

helm install connect-gateway cdata/connect-gateway \
  --set gateway.locationId=<location-id> \
  --set gateway.accountId=<account-id> \
  --set gateway.apiKey=<api-key> \
  -n connect-gateway --create-namespace
```

### Option B: Install directly from the GitHub release

Useful for air-gapped environments, pinning to an exact version, or when you don't want to add a Helm repo.

```bash
helm install connect-gateway \
  https://github.com/CDataSoftware/connect-gateway-helm/releases/download/v1.0.0/connect-gateway-1.0.0.tgz \
  --set gateway.locationId=<location-id> \
  --set gateway.accountId=<account-id> \
  --set gateway.apiKey=<api-key> \
  -n connect-gateway --create-namespace
```

> Replace `v1.0.0` / `1.0.0` with the version you want from the [releases page](https://github.com/CDataSoftware/connect-gateway-helm/releases). To upgrade later, point at the newer release URL.

> **Note:** Passing `gateway.apiKey` via `--set` stores it in Helm release history.
> See [Secret Management](#secret-management) for production-safe alternatives.

### Using a pre-existing secret (recommended)

Create the secret out-of-band, then reference it:

```bash
kubectl create secret generic connect-gateway-secret \
  --from-literal=gateway-api-key=<api-key> \
  -n connect-gateway

helm install connect-gateway cdata/connect-gateway \
  --set gateway.locationId=<location-id> \
  --set gateway.accountId=<account-id> \
  --set existingSecret=connect-gateway-secret \
  -n connect-gateway --create-namespace
```

## Configuration

| Parameter | Description | Default |
|---|---|---|
| `image.repository` | Container image repository | `connectaipublic.azurecr.io/connectgateway` |
| `image.tag` | Image tag — when empty, defaults to `Chart.appVersion` | `""` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `replicaCount` | Number of replicas (used when HPA is disabled) | `2` |
| `gateway.locationId` | Gateway location ID (**required**) | `""` |
| `gateway.accountId` | CData account ID (**required**) | `""` |
| `gateway.apiKey` | API key — chart creates a Secret when set | `""` |
| `gateway.registrationUrl` | Registration URL for the Connect AI Agent API | `https://cloud.cdata.com` |
| `existingSecret` | Name of a pre-existing Secret containing `gateway-api-key` | `""` |
| `service.type` | Kubernetes Service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `service.containerPort` | Main HTTP container port | `8490` |
| `service.managementPort` | Spring Boot management/actuator port | `8491` |
| `relay.connectionTimeoutSeconds` | Relay connection timeout | `30` |
| `relay.autoReconnect` | Automatically reconnect on relay disconnect | `true` |
| `relay.reconnectDelaySeconds` | Delay between reconnect attempts | `5` |
| `relay.maxReconnectAttempts` | Max reconnect attempts (`0` = unlimited) | `0` |
| `logging.profile` | Spring profile (set to `prod` for JSON/Logstash structured logging) | `""` |
| `logging.agentLevel` | Log level for agent classes | `INFO` |
| `resources.requests.cpu` | CPU request | `100m` |
| `resources.requests.memory` | Memory request | `512Mi` |
| `resources.limits.cpu` | CPU limit | `500m` |
| `resources.limits.memory` | Memory limit | `2Gi` |
| `hpa.enabled` | Enable Horizontal Pod Autoscaler | `true` |
| `hpa.minReplicas` | Minimum replicas | `2` |
| `hpa.maxReplicas` | Maximum replicas | `5` |
| `hpa.targetMemoryUtilizationPercentage` | Target memory utilisation for scaling | `80` |
| `pdb.enabled` | Enable PodDisruptionBudget | `true` |
| `pdb.minAvailable` | Minimum pods available during disruption | `1` |
| `topologySpread.enabled` | Spread pods across availability zones | `true` |
| `topologySpread.topologyKey` | Topology key for zone spreading | `topology.kubernetes.io/zone` |
| `serviceAccount.create` | Create a ServiceAccount | `true` |
| `serviceAccount.name` | ServiceAccount name | `connect-gateway` |
| `serviceAccount.annotations` | Annotations for cloud workload identity binding | `{}` |
| `probes.readiness` | Readiness probe configuration | HTTP GET `/actuator/health/readiness:8491` |
| `probes.liveness` | Liveness probe configuration | HTTP GET `/actuator/health/liveness:8491` |
| `probes.startup` | Startup probe configuration | HTTP GET `/actuator/health:8491` |

## Secret Management

The `GATEWAY_API_KEY` is sensitive and must be supplied via a Kubernetes Secret.
The chart supports the following patterns:

### 1. `--set-file` (simple, keeps key off shell history)

```bash
echo -n "<api-key>" > /tmp/gw-key.txt
helm install connect-gateway cdata/connect-gateway \
  --set-file gateway.apiKey=/tmp/gw-key.txt \
  --set gateway.locationId=<location-id> \
  --set gateway.accountId=<account-id> \
  -n connect-gateway --create-namespace
rm /tmp/gw-key.txt
```

### 2. Pre-existing Secret (recommended for CI/CD and GitOps)

```bash
kubectl create secret generic connect-gateway-secret \
  --from-literal=gateway-api-key=<api-key> \
  -n connect-gateway

helm install connect-gateway cdata/connect-gateway \
  --set existingSecret=connect-gateway-secret \
  --set gateway.locationId=<location-id> \
  --set gateway.accountId=<account-id> \
  -n connect-gateway --create-namespace
```

### 3. External Secrets Operator (AWS / Azure Key Vault / GCP Secret Manager)

Sync secrets from your cloud vault automatically:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: connect-gateway-secret
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: <your-secret-store>
    kind: ClusterSecretStore
  target:
    name: connect-gateway-secret
  data:
    - secretKey: gateway-api-key
      remoteRef:
        key: <path/to/secret>
```

Then set `--set existingSecret=connect-gateway-secret`.

### 4. Sealed Secrets (encrypted secrets safe to commit to git)

```bash
kubectl create secret generic connect-gateway-secret \
  --from-literal=gateway-api-key=<api-key> \
  --dry-run=client -o yaml \
| kubeseal --format yaml > sealed-secret.yaml
```

Commit `sealed-secret.yaml` to your repository, then set `--set existingSecret=connect-gateway-secret`.

### 5. HashiCorp Vault Agent Injector

Inject secrets directly into the pod via annotations. See the
[Vault Agent Injector documentation](https://developer.hashicorp.com/vault/docs/platform/k8s/injector).

## Cloud Workload Identity

If the gateway needs to authenticate to cloud services, bind a cloud identity via `serviceAccount.annotations`:

```yaml
# Azure Workload Identity
serviceAccount:
  annotations:
    azure.workload.identity/client-id: "<client-id>"

# AWS IRSA
serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::<account-id>:role/<role-name>"

# GCP Workload Identity
serviceAccount:
  annotations:
    iam.gke.io/gcp-service-account: "<sa-name>@<project-id>.iam.gserviceaccount.com"
```

## Upgrading

If installed via the Helm repository:

```bash
helm repo update
helm upgrade connect-gateway cdata/connect-gateway \
  --set gateway.locationId=<location-id> \
  --set gateway.accountId=<account-id> \
  --set existingSecret=connect-gateway-secret \
  -n connect-gateway
```

If installed from a release tarball, point at the newer release URL:

```bash
helm upgrade connect-gateway \
  https://github.com/CDataSoftware/connect-gateway-helm/releases/download/v<new-version>/connect-gateway-<new-version>.tgz \
  --set gateway.locationId=<location-id> \
  --set gateway.accountId=<account-id> \
  --set existingSecret=connect-gateway-secret \
  -n connect-gateway
```

## Uninstalling

```bash
helm uninstall connect-gateway -n connect-gateway
```

> **Note:** If the secret was created by the chart (via `gateway.apiKey`), it will be deleted along with the release. If you used `existingSecret`, the secret is not managed by the chart and will not be deleted.

## Support

- Product documentation: <https://docs.cloud.cdata.com/en/Connect-Gateway>
- Issues with this chart: <https://github.com/CDataSoftware/connect-gateway-helm/issues>
- CData Support: <https://www.cdata.com/support/>
