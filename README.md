# connect-gateway-helm

Helm charts for the [CData Connect Gateway](https://docs.cloud.cdata.com/en/Connect-Gateway) — a secure outbound agent that lets [CData Connect AI](https://www.cdata.com/ai/) query private data sources without opening inbound firewall rules.

## Charts

| Chart | Version | Description |
|---|---|---|
| [connect-gateway](charts/connect-gateway) | [![Release](https://img.shields.io/github/v/release/CDataSoftware/connect-gateway-helm)](https://github.com/CDataSoftware/connect-gateway-helm/releases) | Deploys the Connect Gateway agent on Kubernetes. |

## Usage

```bash
helm repo add cdata https://cdatasoftware.github.io/connect-gateway-helm
helm repo update

helm install connect-gateway cdata/connect-gateway \
  --set gateway.locationId=<location-id> \
  --set gateway.accountId=<account-id> \
  --set gateway.apiKey=<api-key> \
  -n connect-gateway --create-namespace
```

For configuration options, secret-management patterns, and cloud workload identity setup, see the [chart README](charts/connect-gateway/README.md).

## Links

- [Connect Gateway documentation](https://docs.cloud.cdata.com/en/Connect-Gateway)
- [CData Connect AI](https://www.cdata.com/ai/)
- [Container image (public)](https://connectaipublic.azurecr.io/connectgateway) — `connectaipublic.azurecr.io/connectgateway`

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the release process and contribution guidelines.

## License

[MIT](LICENSE)
