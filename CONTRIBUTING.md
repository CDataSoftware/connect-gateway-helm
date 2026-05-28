# Contributing

This repository is the **single source of truth** for the CData Connect Gateway Helm chart. The chart is no longer maintained in CData's internal repositories — all changes happen here.

## Repository layout

```
.
├── charts/
│   └── connect-gateway/      # The chart itself (Chart.yaml, values.yaml, templates/)
├── .github/workflows/
│   ├── lint.yml              # Runs `ct lint` on every PR
│   └── release.yml           # Runs chart-releaser-action on every push to main
└── LICENSE                   # MIT
```

## Local development

Lint and template-render the chart locally before pushing:

```bash
helm lint charts/connect-gateway
helm template test charts/connect-gateway \
  --set gateway.locationId=test \
  --set gateway.accountId=test \
  --set gateway.apiKey=test
```

To test an end-to-end install against a real cluster:

```bash
helm install test charts/connect-gateway \
  --set gateway.locationId=<your-location-id> \
  --set gateway.accountId=<your-account-id> \
  --set gateway.apiKey=<your-api-key> \
  -n connect-gateway --create-namespace --dry-run
```

## Pull requests

1. Branch from `main`.
2. Make changes under `charts/connect-gateway/`.
3. **Bump `version` in `Chart.yaml`** following [SemVer](https://semver.org/):
   - Patch (`1.0.0` → `1.0.1`): bug fixes, doc-only changes that affect the rendered chart.
   - Minor (`1.0.0` → `1.1.0`): new optional values, additive template changes.
   - Major (`1.0.0` → `2.0.0`): breaking changes — removed values, renamed resources, required-value changes.
4. Update `appVersion` if the chart now targets a new Connect Gateway image release.
5. Open a PR against `main`. The `lint` workflow runs `helm lint` + `ct lint` on the changed chart.
6. Once merged, the `release` workflow automatically publishes the new version (see below).

## Release process

Releases are fully automated by [`helm/chart-releaser-action`](https://github.com/helm/chart-releaser-action) on every push to `main`:

1. The action inspects each chart under `charts/`.
2. For any chart whose `version` in `Chart.yaml` is **not yet released**, it:
   - Packages the chart as a `.tgz` artifact.
   - Creates a GitHub Release tagged `v<version>` (per `cr.yaml`).
   - Updates `index.yaml` on the `gh-pages` branch (the Helm repository index served at <https://cdatasoftware.github.io/connect-gateway-helm>).
3. No manual tagging or `helm package`/`helm push` is required — bump the version in `Chart.yaml`, merge, done.

If you need to re-publish or roll back, delete the corresponding GitHub Release and `gh-pages` entry, then re-trigger the workflow.

## Reporting issues

File issues at <https://github.com/CDataSoftware/connect-gateway-helm/issues>. For product-level questions about the Connect Gateway itself (not chart-specific), use [CData Support](https://www.cdata.com/support/).
