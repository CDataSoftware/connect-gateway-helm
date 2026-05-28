{{/*
Common labels applied to all resources.
*/}}
{{- define "connect-gateway.labels" -}}
app: connect-gateway
app.component: {{ .component }}
app.kubernetes.io/name: connect-gateway
app.kubernetes.io/instance: {{ .context.Release.Name }}
app.kubernetes.io/version: {{ .context.Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .context.Release.Service }}
{{- end }}

{{/*
Selector labels — used in Deployment.spec.selector and Service.spec.selector.
*/}}
{{- define "connect-gateway.selectorLabels" -}}
app: connect-gateway
app.component: connect-gateway
{{- end }}

{{/*
Resolve the Secret name to use for gateway credentials.
If gateway.apiKey is set the chart creates and owns the secret.
Otherwise fall back to existingSecret.
*/}}
{{- define "connect-gateway.secretName" -}}
{{- if .Values.gateway.apiKey -}}
{{ .Release.Name }}-credentials
{{- else -}}
{{ required "Either gateway.apiKey or existingSecret must be set" .Values.existingSecret }}
{{- end }}
{{- end }}

{{/*
Standard security context — runs as non-root, drops all capabilities.
*/}}
{{- define "connect-gateway.securityContext" -}}
securityContext:
  allowPrivilegeEscalation: false
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 3000
  capabilities:
    drop:
      - ALL
{{- end }}

{{/*
Pre-stop sleep for graceful connection draining before pod termination.
*/}}
{{- define "connect-gateway.preStopSleep" -}}
lifecycle:
  preStop:
    exec:
      command: ["sh", "-c", "sleep 5"]
{{- end }}

{{/*
Topology spread constraints — distributes pods evenly across zones or nodes.
Controlled by topologySpread.enabled and topologySpread.topologyKey in values.
*/}}
{{- define "connect-gateway.topologySpread" -}}
{{- if .Values.topologySpread.enabled }}
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: {{ .Values.topologySpread.topologyKey }}
    whenUnsatisfiable: ScheduleAnyway
    labelSelector:
      matchLabels:
        {{- include "connect-gateway.selectorLabels" . | nindent 8 }}
{{- end }}
{{- end }}
